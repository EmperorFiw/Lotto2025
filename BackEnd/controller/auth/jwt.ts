import { expressjwt } from "express-jwt";
import jwt from "jsonwebtoken";

export const secret = process.env.JWT_SECRET || "Lotto2025Project";

if (!secret) {
  throw new Error("JWT_SECRET environment variable is required but not defined");
}
export const jwtAuthen = expressjwt({
  secret: secret,
  algorithms: ["HS256"],
}).unless({
  path: ["/", "auth/register", "auth/login"],
});

export function generateToken(payload: any): string {
  const token: string = jwt.sign(payload, secret, {
    expiresIn: "6h", // expires
    issuer: "0xFuse"
  });
  return token;
}

export function verifyToken(token: string,secretKey: string): { valid: boolean; decoded?: any; error?: string } {
  try {
    const decodedPayload: any = jwt.verify(token, secretKey);
    return { valid: true, decoded: decodedPayload };
  } catch (error) {
    return { valid: false, error: JSON.stringify(error) };
  }
}