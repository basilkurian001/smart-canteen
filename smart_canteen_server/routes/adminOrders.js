import express from "express";
import db from "../db.js";
import { requireAuth } from "./auth.js";
import { requireAdminAuth } from "../middleware/requireAdmin.js";

const router = express.Router();

/* =========================
   GET ALL ORDERS (ADMIN)
========================= */
router.get("/orders", requireAdminAuth, (req, res) => {
  // OPTIONAL: check admin flag

  const orders = db.prepare(`
    SELECT
      o.id,
      o.total_amount,
      o.status,
      o.created_at,
      u.name AS user_name
    FROM orders o
    JOIN users u ON u.id = o.user_id
    ORDER BY o.id DESC
  `).all();

  res.json({
    success: true,
    orders,
  });
});

/* =========================
   UPDATE ORDER STATUS
========================= */
router.put("/orders/:id/status", requireAdminAuth, (req, res) => {

  const { status } = req.body;

  db.prepare(`
    UPDATE orders
    SET status = ?
    WHERE id = ?
  `).run(status, req.params.id);

  res.json({ success: true });
});

/* =========================
   GET ORDER ITEMS
========================= */
router.get("/orders/:id/items", requireAdminAuth, (req, res) => {
  try {
    const items = db.prepare(`
      SELECT 
        oi.food_id,
        f.name,
        f.image,
        oi.quantity,
        oi.price
      FROM order_items oi
      JOIN foods f ON f.id = oi.food_id
      WHERE oi.order_id = ?
    `).all(req.params.id);
    res.json({ success: true, items });
  } catch (err) {
    console.error("Failed to fetch order items:", err);
    res.status(500).json({ success: false, message: "Failed to fetch items" });
  }
});

export default router;
