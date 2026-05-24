// routes/food.js
import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import db from "../db.js";
import { fileURLToPath } from "url";

const router = express.Router();

/* =========================
   ESM __dirname FIX
========================= */
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/* =========================
   GET /food
========================= */
router.get("/", (req, res) => {
  try {
    const foods = db.prepare(`
      SELECT 
        id,
        name,
        price,
        image,
        category,
        is_veg,
        description
      FROM foods
      WHERE available = 1
      ORDER BY created_at DESC
    `).all();

    res.json({ success: true, foods });
  } catch (err) {
    console.error("Fetch food error:", err);
    res.status(500).json({ success: false, message: "Failed to fetch food" });
  }
});

// GET foods by category
router.get("/category/:category", (req, res) => {
  try {
    const category = req.params.category;

    const foods = db.prepare(`
      SELECT id, name, price, image, category, is_veg, description
      FROM foods
      WHERE available = 1 AND LOWER(category) = LOWER(?)
      ORDER BY created_at DESC
    `).all(category);

    res.json({
      success: true,
      foods,
    });
  } catch (err) {
    console.error("Category fetch error:", err);
    res.status(500).json({
      success: false,
      message: "Failed to fetch category foods",
    });
  }
});

/* =========================
   GET /food/vegetarian
========================= */
router.get("/vegetarian", (req, res) => {
  try {
    const foods = db.prepare(`
      SELECT id, name, price, image, category, is_veg, description
      FROM foods
      WHERE available = 1 AND is_veg = 1
      ORDER BY created_at DESC
    `).all();

    res.json({
      success: true,
      foods,
    });
  } catch (err) {
    console.error("Vegetarian fetch error:", err);
    res.status(500).json({
      success: false,
      message: "Failed to fetch vegetarian foods",
    });
  }
});

/* =========================
   MULTER CONFIG
========================= */
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, "../public/food_images");
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith("image/")) cb(null, true);
  else cb(new Error("Only image files allowed"));
};

export const uploadFoodImage = multer({ storage, fileFilter });

export default router;
