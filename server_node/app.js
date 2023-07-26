"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const body_parser_1 = __importDefault(require("body-parser"));
const express_1 = __importDefault(require("express"));
const controller_1 = require("./controller/controller");
const app = (0, express_1.default)();
const port = Number(process.env.PORT) || 1323;
const host = process.env.IP || "localhost";
app.use(body_parser_1.default.urlencoded({ extended: false }));
app.use(body_parser_1.default.json());
app.get("/", (_, res) => {
    res.send("atable shop list endpoint");
});
const controller = new controller_1.Controller();
app.put("/api/session", controller.CreateSession);
app.get("/api/session", controller.GetSession);
app.post("/api/session", controller.UpdateSession);
app.use(express_1.default.static("static"));
app.get("/shop", (_, res) => {
    res.sendFile("static/shop/index.html");
});
app.use((err, _, res, __) => {
    res.status(500).json({ message: `${err}` });
});
app.listen(port, host, () => {
    console.log(`Server listening on ${host}:${port}`);
});
