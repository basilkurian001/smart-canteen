import express from "express";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import db from "../db.js";
import { requireAdminAuth } from "../middleware/requireAdmin.js";

const router = express.Router();

/* =========================
   ADMIN LOGIN
========================= */
router.post("/login", async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({
      success: false,
      message: "Username and password required",
    });
  }

  const admin = db.prepare(`
    SELECT * FROM admins WHERE username = ?
  `).get(username);

  if (!admin) {
    return res.status(401).json({
      success: false,
      message: "Invalid credentials",
    });
  }

  const match = await bcrypt.compare(password, admin.password);
  if (!match) {
    return res.status(401).json({
      success: false,
      message: "Invalid credentials",
    });
  }

  const token = jwt.sign(
    {
      id: admin.id,
      role: admin.role,
    },
    process.env.ADMIN_JWT_SECRET,
    { expiresIn: process.env.ADMIN_JWT_EXPIRES }
  );

  res.json({
    success: true,
    token,
    admin: {
      id: admin.id,
      username: admin.username,
      role: admin.role,
    },
  });
});

router.get("/me", requireAdminAuth, (req, res) => {
  res.json({ success: true });
});


export default router;
