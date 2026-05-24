import express from "express";
import db from "../db.js";
import { requireAdminAuth } from "../middleware/requireAdmin.js";

const router = express.Router();

/* =========================
   GET /offers
   Fetch single announcement (id = 1)
========================= */
router.get("/", (req, res) => {
  try {
    const offer = db.prepare(`
      SELECT id, title, subtitle, active, expires_at
      FROM offers
      WHERE id = 1 AND active = 1
      LIMIT 1
    `).get();

    res.json({
      success: true,
      offer,
    });
  } catch (e) {
    console.error("Offer fetch error:", e);
    res.status(500).json({ success: false });
  }
});

/* =========================
   POST /offers
   Update single announcement (id = 1)
========================= */
router.post("/", requireAdminAuth, (req, res) => {
  try {
    const { title, subtitle, active, expires_at } = req.body;

    if (!title) {
      return res.status(400).json({
        success: false,
        message: "Title is required",
      });
    }

    const exists = db
      .prepare("SELECT id FROM offers WHERE id = 1")
      .get();

    if (exists) {
      // UPDATE existing row
      db.prepare(`
        UPDATE offers
        SET
          title = ?,
          subtitle = ?,
          active = ?,
          expires_at = ?
        WHERE id = 1
      `).run(
        title,
        subtitle || null,
        active ? 1 : 0,
        expires_at || null
      );
    } else {
      // INSERT once (failsafe)
      db.prepare(`
        INSERT INTO offers (id, title, subtitle, active, expires_at)
        VALUES (1, ?, ?, ?, ?)
      `).run(
        title,
        subtitle || null,
        active ? 1 : 0,
        expires_at || null
      );
    }

    res.json({ success: true });

  } catch (e) {
    console.error("Offer save error:", e);
    res.status(500).json({ success: false });
  }
});

export default router;
