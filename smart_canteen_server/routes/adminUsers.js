import express from "express";
import db from "../db.js";
import { requireAdminAuth } from "../middleware/requireAdmin.js";

const router = express.Router();

/* =========================
   GET ALL USERS
========================= */
router.get("/", requireAdminAuth, (req, res) => {
  try {
    const users = db.prepare(`
      SELECT
        id,
        name,
        email,
        points,
        avatar
      FROM users
      ORDER BY created_at DESC
    `).all();

    res.json({ success: true, users });
  } catch (err) {
    console.error("Admin users error:", err);
    res.status(500).json({ success: false });
  }
});

export default router;
