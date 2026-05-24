const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const db = require("../db");
const { requireAuth } = require("./auth");
const bcrypt = require("bcryptjs");

// ensure upload dir exists
const AVATAR_DIR = path.join(__dirname, "..", "uploads", "avatars");
fs.mkdirSync(AVATAR_DIR, { recursive: true });

// storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, AVATAR_DIR);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `user_${req.user.id}${ext}`);
  },
});

// SAFE image validation
const fileFilter = (req, file, cb) => {
  const allowedExt = [".jpg", ".jpeg", ".png", ".webp", ".heic"];
  const ext = path.extname(file.originalname).toLowerCase();

  if (!allowedExt.includes(ext)) {
    return cb(new Error("Only image files allowed"));
  }

  // accept file
  cb(null, true);
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

// POST /profile/avatar
router.post(
  "/avatar",
  requireAuth,
  upload.single("avatar"),
  (req, res) => {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No file uploaded",
      });
    }

    // 🔒 BLOCK GOOGLE USERS
    const user = db
      .prepare("SELECT google_id FROM users WHERE id = ?")
      .get(req.user.id);

    if (user?.google_id) {
      return res.status(403).json({
        success: false,
        message: "Google users cannot change avatar",
      });
    }

    const avatarFile = req.file.filename;

    db.prepare("UPDATE users SET avatar = ? WHERE id = ?").run(
      avatarFile,
      req.user.id
    );

    res.json({
      success: true,
      avatar: avatarFile,
    });
  }
);

/**
 * CHANGE USERNAME
 * POST /profile/change-username
 * body: { name }
 */
router.post("/change-username", requireAuth, (req, res) => {
  const { name } = req.body;

  if (!name || name.trim().length < 3) {
    return res.status(400).json({
      success: false,
      message: "Username must be at least 3 characters",
    });
  }

  const user = db
    .prepare("SELECT id, google_id FROM users WHERE id = ?")
    .get(req.user.id);

  if (!user) {
    return res.status(404).json({ success: false, message: "User not found" });
  }

  // ❌ Block Google users
  if (user.google_id) {
    return res.status(403).json({
      success: false,
      message: "Google users cannot change username",
    });
  }

  db.prepare("UPDATE users SET name = ? WHERE id = ?").run(name.trim(), user.id);

  res.json({
    success: true,
    message: "Username updated successfully",
  });
});

/**
 * CHANGE PASSWORD
 * POST /profile/change-password
 * body: { oldPassword, newPassword }
 */
router.post("/change-password", requireAuth, (req, res) => {
  const { oldPassword, newPassword } = req.body;

  if (!oldPassword || !newPassword) {
    return res.status(400).json({
      success: false,
      message: "Old password and new password are required",
    });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({
      success: false,
      message: "New password must be at least 6 characters",
    });
  }

  const user = db
    .prepare("SELECT id, password, google_id FROM users WHERE id = ?")
    .get(req.user.id);

  if (!user) {
    return res.status(404).json({ success: false, message: "User not found" });
  }

  // ❌ Block Google users
  if (user.google_id) {
    return res.status(403).json({
      success: false,
      message: "Google users cannot change password",
    });
  }

  const isValid = bcrypt.compareSync(oldPassword, user.password);
  if (!isValid) {
    return res.status(401).json({
      success: false,
      message: "Old password is incorrect",
    });
  }

  const hashed = bcrypt.hashSync(newPassword, 10);
  db.prepare("UPDATE users SET password = ? WHERE id = ?").run(
    hashed,
    user.id
  );

  res.json({
    success: true,
    message: "Password updated successfully",
  });
});


module.exports = router;
