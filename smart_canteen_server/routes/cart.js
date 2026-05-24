// routes/cart.js
import express from "express";
import db from "../db.js";
import { requireAuth } from "./auth.js";

const router = express.Router();

/* =========================
   ADD / UPDATE CART ITEM
========================= */
router.post("/", requireAuth, (req, res) => {
  const { foodId, quantity = 1 } = req.body;

  if (!foodId || quantity < 1) {
    return res.status(400).json({
      success: false,
      message: "Invalid foodId or quantity",
    });
  }

  db.prepare(`
    INSERT INTO cart_items (user_id, food_id, quantity)
    VALUES (?, ?, ?)
    ON CONFLICT(user_id, food_id)
    DO UPDATE SET
      quantity = quantity + excluded.quantity
  `).run(req.user.id, foodId, quantity);

  res.json({ success: true });
});

/* =========================
   GET CART ITEMS
========================= */
router.get("/", requireAuth, (req, res) => {
  const items = db.prepare(`
    SELECT 
      c.food_id,
      c.quantity,
      f.name,
      f.price,
      f.image,
      f.available
    FROM cart_items c
    JOIN foods f ON f.id = c.food_id
    WHERE c.user_id = ?
    ORDER BY c.created_at DESC
  `).all(req.user.id);

  res.json({ success: true, items });
});

/* =========================
   CART COUNT (BADGE)
========================= */
router.get("/count", requireAuth, (req, res) => {
  const result = db.prepare(`
    SELECT COALESCE(SUM(quantity), 0) AS count
    FROM cart_items
    WHERE user_id = ?
  `).get(req.user.id);

  res.json({ success: true, count: result.count });
});

/* =========================
   UPDATE QUANTITY
========================= */
router.put("/", requireAuth, (req, res) => {
  const { foodId, quantity } = req.body;

  if (!foodId || quantity == null) {
    return res.status(400).json({
      success: false,
      message: "foodId and quantity required",
    });
  }

  if (quantity <= 0) {
    db.prepare(`
      DELETE FROM cart_items
      WHERE user_id = ? AND food_id = ?
    `).run(req.user.id, foodId);
  } else {
    db.prepare(`
      UPDATE cart_items
      SET quantity = ?
      WHERE user_id = ? AND food_id = ?
    `).run(quantity, req.user.id, foodId);
  }

  res.json({ success: true });
});

/* =========================
   DELETE SINGLE ITEM
========================= */
router.delete("/:foodId", requireAuth, (req, res) => {
  const { foodId } = req.params;

  const result = db.prepare(`
    DELETE FROM cart_items
    WHERE user_id = ? AND food_id = ?
  `).run(req.user.id, foodId);

  if (result.changes === 0) {
    return res.status(404).json({
      success: false,
      message: "Item not found",
    });
  }

  res.json({ success: true });
});

/* =========================
   CLEAR CART
========================= */
router.delete("/", requireAuth, (req, res) => {
  db.prepare(`
    DELETE FROM cart_items
    WHERE user_id = ?
  `).run(req.user.id);

  res.json({ success: true });
});

export default router;
