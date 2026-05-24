// server.js
import express from "express";
import cors from "cors";
import bodyParser from "body-parser";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";
dotenv.config();

import db from "./db.js";
import auth from "./routes/auth.js";
import profileRouter from "./routes/profile.js";
import foodRouter from "./routes/food.js";
import offerRouter from "./routes/offers.js";
import reviewRouter from "./routes/food_reviews.js";
import cartRoutes from "./routes/cart.js";
import favouritesRoutes from "./routes/favourites.js";
import ordersRoutes from "./routes/orders.js";
import adminAuthRoutes from "./routes/admin_auth.js";
import adminOrdersRoutes from "./routes/adminOrders.js";
import adminFoods from "./routes/adminFoods.js";
import adminUsers from "./routes/adminUsers.js";
import adminPoints from "./routes/adminPoints.js";

const app = express();

/* =========================
   ESM __dirname FIX
========================= */
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.use(cors());
app.use(bodyParser.json());

/* =========================
   ROUTES
========================= */
app.use("/auth", auth.router);
app.use("/profile", profileRouter);
app.use("/food", foodRouter);
app.use("/offers", offerRouter);
app.use("/reviews", reviewRouter);
app.use("/cart", cartRoutes);
app.use("/favourites", favouritesRoutes);
app.use("/orders", ordersRoutes);
app.use("/admin/auth", adminAuthRoutes);
app.use("/admin", adminOrdersRoutes);
app.use("/admin/foods", adminFoods);
app.use("/admin/users", adminUsers);
app.use("/admin/points", adminPoints);

/* =========================
   STATIC FILES
========================= */
app.use(express.static("public"));

app.use(
  "/food_images",
  express.static(path.join(__dirname, "public/food_images"))
);

app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.get("/health", (req, res) => {
  res.json({ status: "online" });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

/* =========================
   TOKEN CLEANUP
========================= */
setInterval(() => {
  const now = Math.floor(Date.now() / 1000);
  try {
    db.prepare("DELETE FROM tokens WHERE expires_at < ?").run(now);
    console.log("Expired tokens cleaned");
  } catch (e) {
    console.error("Cleanup error", e);
  }
}, 24 * 3600 * 1000);
