// routes/reviews.js
import express from "express";
import db from "../db.js";
import { requireAuth } from "./auth.js";

const router = express.Router();

/* =========================
   GET REVIEWS + AVG RATING
========================= */
router.get("/:foodId", (req, res) => {
  const { foodId } = req.params;

  const reviews = db.prepare(`
    SELECT r.id, r.rating, r.comment, r.created_at, u.name
    FROM food_reviews r
    JOIN users u ON u.id = r.user_id
    WHERE r.food_id = ?
    ORDER BY r.created_at DESC
  `).all(foodId);

  const stats = db.prepare(`
    SELECT 
      AVG(rating) as avgRating,
      COUNT(*) as totalReviews
    FROM food_reviews
    WHERE food_id = ?
  `).get(foodId);

  res.json({
    success: true,
    reviews,
    averageRating: stats.avgRating ? Number(stats.avgRating).toFixed(1) : "0.0",
    totalReviews: stats.totalReviews
  });
});

/* =========================
   ADD / UPDATE REVIEW
========================= */
router.post("/:foodId", requireAuth, (req, res) => {
  const { foodId } = req.params;
  const { rating, comment } = req.body;

  if (!rating || rating < 1 || rating > 5) {
    return res.status(400).json({ success: false, message: "Invalid rating" });
  }

  const now = Math.floor(Date.now() / 1000);

  db.prepare(`
    INSERT INTO food_reviews (user_id, food_id, rating, comment, created_at)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(user_id, food_id)
    DO UPDATE SET
      rating = excluded.rating,
      comment = excluded.comment,
      created_at = excluded.created_at
  `).run(req.user.id, foodId, rating, comment, now);

  res.json({ success: true });
});

/* =========================
   DELETE REVIEW (OWNER ONLY)
========================= */
router.delete("/:foodId", requireAuth, (req, res) => {
  const { foodId } = req.params;

  const result = db.prepare(`
    DELETE FROM food_reviews
    WHERE food_id = ? AND user_id = ?
  `).run(foodId, req.user.id);

  if (result.changes === 0) {
    return res.status(403).json({ success: false, message: "No review to delete" });
  }

  res.json({ success: true });
});

export default router;
