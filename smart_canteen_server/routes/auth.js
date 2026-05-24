// routes/auth.js
const express = require("express");
const router = express.Router();
const db = require("../db"); // better-sqlite3 instance
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { OAuth2Client } = require("google-auth-library");

// ================= CONFIG =================
const SECRET = process.env.JWT_SECRET || "change_this_secret_in_production";
const TOKEN_EXPIRY_SECONDS = 7 * 24 * 60 * 60; // 7 days
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

// ================= HELPERS =================
function makeJti() {
  return crypto.randomBytes(16).toString("hex");
}

function issueTokenForUser(user) {
  const jti = makeJti();
  const now = Math.floor(Date.now() / 1000);
  const expiresAt = now + TOKEN_EXPIRY_SECONDS;

  const payload = {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
  };

  const token = jwt.sign(payload, SECRET, {
    expiresIn: TOKEN_EXPIRY_SECONDS,
    jwtid: jti,
  });

  db.prepare(
    `INSERT INTO tokens (jti, user_id, issued_at, expires_at, active)
     VALUES (?, ?, ?, ?, 1)`
  ).run(jti, user.id, now, expiresAt);

  return token;
}

// ================= SIGNUP =================
router.post("/signup", async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!email || !password)
      return res.status(400).json({ success: false, message: "Email & password required" });

    const existing = db.prepare("SELECT * FROM users WHERE email = ?").get(email);
    if (existing)
      return res.status(409).json({ success: false, message: "Email already exists" });

    const hashed = bcrypt.hashSync(password, 10);
    const displayName = name || email.split("@")[0];

    const result = db.prepare(
      "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)"
    ).run(displayName, email, hashed, role || "student");

    const safeUser = {
      id: result.lastInsertRowid,
      name: displayName,
      email,
      role: role || "student",
    };

    const token = issueTokenForUser(safeUser);
    res.json({ success: true, user: safeUser, token });
  } catch (err) {
    console.error("Signup error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ================= LOGIN =================
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ success: false, message: "Email & password required" });

    const user = db.prepare("SELECT * FROM users WHERE email = ?").get(email);
    if (!user || !bcrypt.compareSync(password, user.password))
      return res.status(401).json({ success: false, message: "Invalid credentials" });

    const safeUser = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatar: user.avatar || null,
    };

    const token = issueTokenForUser(safeUser);
    res.json({ success: true, user: safeUser, token });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ================= GOOGLE LOGIN =================
router.post("/google", async (req, res) => {
  console.log("Google login body:", req.body);

  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: "Token required" });
    }

    // 1️⃣ Verify Google token
    const ticket = await googleClient.verifyIdToken({
      idToken: token,
      audience: GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    if (!payload || !payload.email_verified) {
      return res.status(401).json({ success: false, message: "Invalid Google token" });
    }

    // 2️⃣ Extract Google data
    const email = payload.email;
    const name = payload.name || email.split("@")[0];
    const avatar = payload.picture || null;
    const googleId = payload.sub;

    // 3️⃣ Find existing user
    let user = db
      .prepare("SELECT * FROM users WHERE email = ?")
      .get(email);

    if (!user) {
      // 4️⃣ Create new Google user
      const randomPassword = bcrypt.hashSync(Date.now().toString(), 10);

      const result = db.prepare(`
        INSERT INTO users (name, email, password, role, avatar, google_id)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run(name, email, randomPassword, "student", avatar, googleId);

      user = {
        id: result.lastInsertRowid,
        name,
        email,
        role: "student",
        avatar,
        google_id: googleId,
      };
    } else {
      // 5️⃣ Resync Google-controlled fields
      db.prepare(`
        UPDATE users
        SET name = ?, avatar = ?, google_id = ?
        WHERE id = ?
      `).run(name, avatar, googleId, user.id);

      user = {
        ...user,
        name,
        avatar,
        google_id: googleId,
      };
    }

    // 6️⃣ Issue app JWT
    const safeUser = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatar: user.avatar,
      google_id: user.google_id,
    };

    const appToken = issueTokenForUser(safeUser);

    res.json({
      success: true,
      user: safeUser,
      token: appToken,
    });
  } catch (err) {
    console.error("Google login error:", err);
    res.status(500).json({ success: false, message: "Google login failed" });
  }
});

// ================= AUTH MIDDLEWARE =================
function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ success: false, message: "No token" });

  const [type, token] = auth.split(" ");
  if (type !== "Bearer") return res.status(401).json({ success: false, message: "Bad auth format" });

  try {
    const payload = jwt.verify(token, SECRET);
    const decoded = jwt.decode(token);
    const jti = decoded?.jti;

    const row = db.prepare(
      "SELECT active, expires_at FROM tokens WHERE jti = ?"
    ).get(jti);

    const now = Math.floor(Date.now() / 1000);
    if (!row || row.active !== 1 || row.expires_at < now)
      return res.status(401).json({ success: false, message: "Token invalid" });

    req.user = payload;
    req.jti = jti;
    next();
  } catch {
    res.status(401).json({ success: false, message: "Invalid token" });
  }
}

// ================= ME =================
router.get("/me", requireAuth, (req, res) => {
  const user = db
    .prepare(
      "SELECT id, name, email, role, avatar, google_id FROM users WHERE id = ?"
    )
    .get(req.user.id);

  if (!user) {
    return res.status(404).json({ success: false, message: "User not found" });
  }

  const baseUrl = `${req.protocol}://${req.get("host")}`;

  res.json({
    success: true,
    user: {
      ...user,
      avatar: user.avatar
        ? user.avatar.startsWith("http")
          ? user.avatar
          : `${baseUrl}/uploads/avatars/${user.avatar}`
        : null,
    },
  });
});

// ================= LOGOUT =================
router.post("/logout", requireAuth, (req, res) => {
  db.prepare("UPDATE tokens SET active = 0 WHERE jti = ?").run(req.jti);
  res.json({ success: true, message: "Logged out" });
});

module.exports = {
  router,
  requireAuth,
};
