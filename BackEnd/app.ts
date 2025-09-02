import bodyParser from "body-parser";
import express from "express";
import { jwtAuthen } from "./controller/auth/jwt";
import { router as loginRouter } from "./controller/auth/login";

export const app = express();

app.use(bodyParser.json());
app.use(bodyParser.text());

app.use("/auth/login", loginRouter);
app.get("/health_check", (req, res) => {
  res.status(200).send("OK");
});


app.use(jwtAuthen, (err: any, req: any, res: any, next: any) => {
  if (err.name === "UnauthorizedError") {
    res.status(err.status).send({ message: err.message });
    return;
  }
  next();
});