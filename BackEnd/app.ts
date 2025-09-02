import bodyParser from "body-parser";
import express from "express";
import { jwtAuthen } from "./controller/auth/jwt";
import { router as loginRouter } from "./controller/auth/login";
import { router as buyLotto } from "./controller/lotto/buy";
import { router as lotto } from "./controller/lotto/fetch";

export const app = express();

app.use(bodyParser.json());
app.use(bodyParser.text());

app.use("/auth/login", loginRouter);
app.get("/health_check", (req, res) => {
  res.status(200).send("OK");
});

app.use("/lotto/fetchlotto", jwtAuthen, lotto);
app.use("/lotto/buy", jwtAuthen, buyLotto);
app.use(jwtAuthen, (err: any, req: any, res: any, next: any) => {
  if (err.name === "UnauthorizedError") {
    res.status(err.status).send({ message: err.message });
    return;
  }
  next();
});