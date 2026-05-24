import express from "express";
import db from "../db.js";
import { uploadFoodImage } from "./food.js";
import { requireAdminAuth } from "../middleware/requireAdmin.js";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const router = express.Router();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/* =========================
   GET ALL FOODS (ADMIN)
========================= */
router.get("/", requireAdminAuth, (req, res) => {
  try {
    const foods = db.prepare(`
      SELECT
        id,
        name,
        price,
        image,
        category,
        is_veg,
        description,
        available
      FROM foods
      ORDER BY created_at DESC
    `).all();

    res.json({ success: true, foods });
  } catch (err) {
    console.error("Admin fetch food error:", err);
    res.status(500).json({ success: false });
  }
});

/* =========================
   ADD FOOD
========================= */
router.post(
  "/",
  requireAdminAuth,
  uploadFoodImage.single("image"),
  (req, res) => {
    const { name, price, category, is_veg, description, available } = req.body;
    const image = req.file ? req.file.filename : null;

    db.prepare(`
      INSERT INTO foods (name, price, image, category, is_veg, description, available)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(
      name,
      price,
      image,
      category || null,
      String(is_veg) === "1" ? 1 : 0,
      description || null,
      String(available) === "1" ? 1 : 0
    );

    res.json({ success: true });
  }
);

/* =========================
   UPDATE FOOD
========================= */
router.put(
  "/:id",
  requireAdminAuth,
  uploadFoodImage.single("image"),
  (req, res) => {
    const { id } = req.params;
    const { name, price, category, is_veg, description, available } = req.body;

    let query = `
      UPDATE foods
      SET name = ?, price = ?, category = ?, is_veg = ?, description = ?, available = ?
    `;
    const params = [
      name,
      price,
      category || null,
      String(is_veg) === "1" ? 1 : 0,
      description || null,
      String(available) === "1" ? 1 : 0,
    ];

    if (req.file) {
      query += `, image = ?`;
      params.push(req.file.filename);
    }

    query += ` WHERE id = ?`;
    params.push(id);

    db.prepare(query).run(...params);

    res.json({ success: true });
  }
);

/* =========================
   DELETE FOOD
========================= */
router.delete("/:id", requireAdminAuth, (req, res) => {
  const { id } = req.params;

  try {
    // Get image name (optional cleanup)
    const food = db.prepare(
      "SELECT image FROM foods WHERE id = ?"
    ).get(id);

    // Delete DB record
    db.prepare("DELETE FROM foods WHERE id = ?").run(id);

    // OPTIONAL: delete image file
    if (food?.image) {
      const imgPath = path.join(
        __dirname,
        "../public/food_images",
        food.image
      );

      if (fs.existsSync(imgPath)) {
        fs.unlinkSync(imgPath);
      }
    }

    res.json({ success: true });
  } catch (err) {
    console.error("Delete food error:", err);
    res.status(500).json({ success: false });
  }
});

export default router;
