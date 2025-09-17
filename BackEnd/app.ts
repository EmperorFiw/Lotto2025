import bodyParser from "body-parser";
import express from "express";
import { jwtAuthen } from "./controller/auth/jwt";
import { router as login } from "./controller/auth/login";
import { router as register } from "./controller/auth/register";
import { router as buyLotto } from "./controller/lotto/buy";
import { router as checkPrize } from "./controller/lotto/check_prize";
import { router as claimLotto } from "./controller/lotto/claim";
import { router as lotto } from "./controller/lotto/fetch";
import { router as prizeDraw } from "./controller/lotto/prize_draw";
import { router as profile } from "./controller/user/profile";

export const app = express();

app.use(bodyParser.json());
app.use(bodyParser.text());

app.get("/health_check", (req, res) => {
  res.status(200).send("OK");
});

app.use("/auth/login", login);
app.use("/auth/register", register);

app.use("/lotto/fetchlotto", jwtAuthen, lotto);
app.use("/lotto/buy", jwtAuthen, buyLotto);
app.use("/lotto/claim", jwtAuthen, claimLotto);
app.use("/user/profile", jwtAuthen, profile);
app.use("/lotto/check_lotto", jwtAuthen, checkPrize);
app.use("/lotto/prize_draw", jwtAuthen, prizeDraw);

app.use(jwtAuthen, (err: any, req: any, res: any, next: any) => {
  if (err.name === "UnauthorizedError") {
    res.status(err.status).send({ message: err.message });
    return;
  }
  next();
});