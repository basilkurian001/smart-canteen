import express from "express";
import db from "../db.js";
import { requireAuth } from "./auth.js";
import { getPointsConfig } from "../utils/points.js";

const router = express.Router();

/* =========================
   PLACE ORDER (FROM CART)
========================= */
router.post("/", requireAuth, (req, res) => {
  const userId = req.user.id;
  const requestedPoints = Math.max(0, req.body.usePoints || 0);

  const cartItems = db.prepare(`
    SELECT c.food_id, c.quantity, f.price
    FROM cart_items c
    JOIN foods f ON f.id = c.food_id
    WHERE c.user_id = ?
  `).all(userId);

  if (!cartItems.length) {
    return res.status(400).json({
      success: false,
      message: "Cart is empty",
    });
  }

  const user = db.prepare(`
    SELECT points FROM users WHERE id = ?
  `).get(userId);

  const {
    maxRedeemPercent,
    rupeePerPoint,
    pointsPerRupee,
  } = getPointsConfig();

  /* ---------- SUBTOTAL ---------- */
  const subtotal = cartItems.reduce(
    (sum, i) => sum + i.price * i.quantity,
    0
  );

  /* ---------- MAX DISCOUNT (50%) ---------- */
  const maxRedeemValue =
    (maxRedeemPercent / 100) * subtotal;

  const maxRedeemPoints = Math.floor(
    maxRedeemValue / rupeePerPoint
  );

  const pointsUsed = Math.min(
    requestedPoints,
    user.points,
    maxRedeemPoints
  );

  const discount = pointsUsed * rupeePerPoint;

  /* ---------- HARD FLOOR ---------- */
  const minPayable = Math.ceil(
    subtotal * (1 - maxRedeemPercent / 100)
  );

  const finalTotal = Math.max(
    subtotal - discount,
    minPayable
  );

  if (finalTotal <= 0) {
    return res.status(400).json({
      success: false,
      message: "Invalid discount applied",
    });
  }

  /* ---------- POINTS EARNED ---------- */
  const pointsEarned =
  pointsUsed > 0
    ? 0
    : Math.floor(finalTotal * pointsPerRupee);

  /* ---------- CREATE ORDER ---------- */
  const order = db.prepare(`
    INSERT INTO orders (user_id, total_amount, points_used, points_earned)
    VALUES (?, ?, ?, ?)
  `).run(userId, finalTotal, pointsUsed, pointsEarned);

  const insertItem = db.prepare(`
    INSERT INTO order_items (order_id, food_id, quantity, price)
    VALUES (?, ?, ?, ?)
  `);

  for (const item of cartItems) {
    insertItem.run(
      order.lastInsertRowid,
      item.food_id,
      item.quantity,
      item.price
    );
  }

  /* ---------- UPDATE USER POINTS ---------- */
  db.prepare(`
    UPDATE users
    SET points = points - ? + ?
    WHERE id = ?
  `).run(pointsUsed, pointsEarned, userId);

  db.prepare(`
    DELETE FROM cart_items WHERE user_id = ?
  `).run(userId);

  res.json({
    success: true,
    orderId: order.lastInsertRowid,
    subtotal,
    discount,
    totalPaid: finalTotal,
    pointsUsed,
    pointsEarned,
    remainingPoints:
      user.points - pointsUsed + pointsEarned,
  });
});

/* =========================
   BUY NOW ORDER
========================= */
router.post("/buy-now", requireAuth, (req, res) => {
  const { foodId, quantity = 1, usePoints = 0 } = req.body;
  const userId = req.user.id;

  const food = db.prepare(`
    SELECT price, available
    FROM foods
    WHERE id = ?
  `).get(foodId);

  if (!food || food.available === 0) {
    return res.status(400).json({
      success: false,
      message: "Item unavailable",
    });
  }

  const user = db.prepare(`
    SELECT points FROM users WHERE id = ?
  `).get(userId);

  const {
    maxRedeemPercent,
    rupeePerPoint,
    pointsPerRupee,
  } = getPointsConfig();

  const subtotal = food.price * quantity;

  const maxRedeemValue =
    (maxRedeemPercent / 100) * subtotal;

  const maxRedeemPoints = Math.floor(
    maxRedeemValue / rupeePerPoint
  );

  const pointsUsed = Math.min(
    usePoints,
    user.points,
    maxRedeemPoints
  );

  const discount = pointsUsed * rupeePerPoint;

  const minPayable = Math.ceil(
    subtotal * (1 - maxRedeemPercent / 100)
  );

  const finalTotal = Math.max(
    subtotal - discount,
    minPayable
  );

  if (finalTotal <= 0) {
    return res.status(400).json({
      success: false,
      message: "Invalid discount applied",
    });
  }

  const pointsEarned =
  pointsUsed > 0
    ? 0
    : Math.floor(finalTotal * pointsPerRupee);

  const order = db.prepare(`
    INSERT INTO orders (user_id, total_amount, points_used, points_earned)
    VALUES (?, ?, ?, ?)
  `).run(userId, finalTotal, pointsUsed, pointsEarned);

  db.prepare(`
    INSERT INTO order_items (order_id, food_id, quantity, price)
    VALUES (?, ?, ?, ?)
  `).run(
    order.lastInsertRowid,
    foodId,
    quantity,
    food.price
  );

  db.prepare(`
    UPDATE users
    SET points = points - ? + ?
    WHERE id = ?
  `).run(pointsUsed, pointsEarned, userId);

  res.json({
    success: true,
    subtotal,
    discount,
    totalPaid: finalTotal,
    pointsUsed,
    pointsEarned,
  });
});

/* =========================
   GET USER ORDERS
========================= */
router.get("/", requireAuth, (req, res) => {
  const orders = db.prepare(`
    SELECT *
    FROM orders
    WHERE user_id = ?
    ORDER BY id DESC
  `).all(req.user.id);

  const getItems = db.prepare(`
    SELECT 
      oi.food_id,
      f.name,
      f.image,
      oi.quantity,
      oi.price
    FROM order_items oi
    JOIN foods f ON f.id = oi.food_id
    WHERE oi.order_id = ?
  `);

  res.json({
    success: true,
    orders: orders.map(order => ({
      ...order,
      items: getItems.all(order.id),
    })),
  });
});

/* =========================
   CHECKOUT PREVIEW
========================= */
router.get("/preview", requireAuth, (req, res) => {
  const user = db.prepare(`
    SELECT points FROM users WHERE id = ?
  `).get(req.user.id);

  const config = getPointsConfig();

  res.json({
    success: true,
    availablePoints: user.points,
    rupeePerPoint: config.rupeePerPoint,
    maxRedeemPercent: config.maxRedeemPercent,
  });
});

export default router;
