import jwt from "jsonwebtoken";

const ADMIN_SECRET = process.env.ADMIN_JWT_SECRET || "admin_secret";

export function signAdmin(admin) {
  return jwt.sign(
    {
      adminId: admin.id,
      role: admin.role,
    },
    ADMIN_SECRET,
    { expiresIn: "1d" } // matches your shift logic
  );
}

export function verifyAdmin(token) {
  return jwt.verify(token, ADMIN_SECRET);
}
