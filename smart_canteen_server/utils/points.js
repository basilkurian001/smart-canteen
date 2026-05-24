import db from "../db.js";

export function getPointsConfig() {
  const row = db.prepare(`
    SELECT points_per_rupee, max_discount_percent
    FROM point_settings
    LIMIT 1
  `).get();

  return {
    pointsPerRupee: row?.points_per_rupee ?? 0.1,
    rupeePerPoint: 1, // 1 point = ₹1 (can be changed later)
    maxRedeemPercent: row?.max_discount_percent ?? 50,
  };
}
