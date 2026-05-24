// routes/favourites.js
import express from "express";
import db from "../db.js";
import { requireAuth } from "./auth.js";

const router = express.Router();

/* =========================
   CHECK IF FAVOURITE
========================= */
router.get("/check/:foodId", requireAuth, (req, res) => {
  const { foodId } = req.params;

  const fav = db.prepare(`
    SELECT 1 FROM favourites
    WHERE user_id = ? AND food_id = ?
  `).get(req.user.id, foodId);

  res.json({ success: true, isFavourite: !!fav });
});

/* =========================
   ADD TO FAVOURITES
========================= */
router.post("/:foodId", requireAuth, (req, res) => {
  const { foodId } = req.params;

  db.prepare(`
    INSERT OR IGNORE INTO favourites (user_id, food_id)
    VALUES (?, ?)
  `).run(req.user.id, foodId);

  res.json({ success: true });
});

/* =========================
   REMOVE FROM FAVOURITES
========================= */
router.delete("/:foodId", requireAuth, (req, res) => {
  const { foodId } = req.params;

  db.prepare(`
    DELETE FROM favourites
    WHERE user_id = ? AND food_id = ?
  `).run(req.user.id, foodId);

  res.json({ success: true });
});

/* =========================
   GET ALL FAVOURITES
========================= */
router.get("/", requireAuth, (req, res) => {
  const items = db.prepare(`
    SELECT 
        f.id as food_id,
        f.name,
        f.price,
        f.image,
        f.category,
        f.is_Veg,
        f.available
      FROM favourites fav
      LEFT JOIN foods f ON f.id = fav.food_id
      WHERE fav.user_id = ?
  `).all(req.user.id);

  res.json({ success: true, items });
});

export default router;
