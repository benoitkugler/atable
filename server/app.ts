import bodyParser from "body-parser";
import express, { Request, Response } from "express";
import { Controller } from "./controller/controller";

const app = express();

const port = Number(process.env.PORT) || 1323;
const host = process.env.IP || "localhost";

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.get("/", (_: Request, res: Response) => {
  res.send("atable shop list endpoint");
});

const controller = new Controller();

app.put("/api/session", controller.CreateSession);
app.get("/api/session", controller.GetSession);
app.post("/api/session", controller.UpdateSession);

app.use(express.static("static"));
app.get("/shop", (_: Request, res: Response) => {
  res.sendFile("static/shop/index.html");
});

app.use((err: Error, _: Request, res: Response, __: any) => {
  res.status(500).json({ message: `${err}` });
});

app.listen(port, host, () => {
  console.log(`Server listening on ${host}:${port}`);
});
