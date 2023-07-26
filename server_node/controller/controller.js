"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Controller = void 0;
const maxSessions = 10000; // simple protection
class Controller {
    constructor() {
        this.sessions = new Map();
        /**
           CreateSession initie une nouvelle session de courses,
           avec la liste donnée.
           */
        this.CreateSession = (req, res) => {
            const list = req.body;
            const id = this.createSession(list);
            res.json({ sessionID: id });
        };
        this.GetSession = (req, res) => {
            const id = (req.query["sessionID"] || "");
            const session = this.sessions.get(id);
            if (session === undefined) {
                throw `La session <${id}> est invalide ou terminée.`;
            }
            res.json(session.list);
        };
        this.UpdateSession = (req, res) => {
            const args = req.body;
            const id = (req.query["sessionID"] || "");
            const l = this.updateSession(args, id);
            res.json(l.list);
        };
    }
    // renvoie l'id créé
    createSession(list) {
        if (this.sessions.size >= maxSessions) {
            throw "internal error: maximum number of session reached";
        }
        let id = randString();
        while (this.sessions.has(id)) {
            id = randString();
        }
        const s = { id: id, list: list };
        this.sessions.set(id, s);
        console.log(`Creating session ${id} with ${list.length} ingredients`);
        return id;
    }
    updateSession(args, sessionID) {
        const l = this.sessions.get(sessionID);
        if (l === undefined) {
            throw `La session <${sessionID}> est invalide ou terminée.`;
        }
        l.list.forEach((v, i) => {
            if (v.id == args.id) {
                l.list[i].checked = args.checked;
            }
        });
        return l;
    }
}
exports.Controller = Controller;
function randString() {
    const L = 16;
    let result = "";
    const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const charactersLength = characters.length;
    let counter = 0;
    while (counter < L) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
        counter += 1;
    }
    return result;
}
