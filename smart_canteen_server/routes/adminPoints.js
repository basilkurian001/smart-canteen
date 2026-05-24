import express from "express";
import db from "../db.js";
import { requireAdminAuth } from "../middleware/requireAdmin.js";

const router = express.Router();

/* =========================
   GET POINT SETTINGS
========================= */
router.get("/", requireAdminAuth, (req, res) => {
  try {
    const row = db.prepare(`
      SELECT points_per_rupee, max_discount_percent
      FROM point_settings
      LIMIT 1
    `).get();

    res.json({
      success: true,
      settings: {
        pointsPerRupee: row?.points_per_rupee ?? 0.1,
        maxDiscountPercent: row?.max_discount_percent ?? 50
      }
    });
  } catch (err) {
    console.error("Fetch points settings error:", err);
    res.status(500).json({ success: false });
  }
});

/* =========================
   UPDATE POINT SETTINGS
========================= */
router.put("/", requireAdminAuth, (req, res) => {
  const { pointsPerRupee, maxDiscountPercent } = req.body;

  try {
    db.prepare(`
      UPDATE point_settings
      SET points_per_rupee = ?, max_discount_percent = ?
    `).run(pointsPerRupee, maxDiscountPercent);

    res.json({ success: true });
  } catch (err) {
    console.error("Update points settings error:", err);
    res.status(500).json({ success: false });
  }
});

export default router;
