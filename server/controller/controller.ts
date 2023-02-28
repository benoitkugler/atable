import { Request, Response } from "express";
import { Session, ShopList } from "./models";

const maxSessions = 10_000; // simple protection

export class Controller {
  sessions: Map<string, Session> = new Map();

  /**
     CreateSession initie une nouvelle session de courses,
     avec la liste donnée.
     */
  CreateSession = (req: Request, res: Response) => {
    const list = req.body as ShopList;
    const id = this.createSession(list);
    res.json({ sessionID: id });
  };

  // renvoie l'id créé
  private createSession(list: ShopList): string {
    if (this.sessions.size >= maxSessions) {
      throw "internal error: maximum number of session reached";
    }
    let id = randString();
    while (this.sessions.has(id)) {
      id = randString();
    }
    const s: Session = { id: id, list: list };

    this.sessions.set(id, s);

    console.log(`Creating session ${id} with ${list.length} ingredients`);

    return id;
  }

  GetSession = (req: Request, res: Response) => {
    const id = (req.query["sessionID"] || "") as string;
    const session = this.sessions.get(id);
    if (session === undefined) {
      throw `La session <${id}> est invalide ou terminée.`;
    }
    res.json(session.list);
  };

  UpdateSession = (req: Request, res: Response) => {
    const args = req.body as update;

    const id = (req.query["sessionID"] || "") as string;
    const l = this.updateSession(args, id);

    res.json(l.list);
  };

  private updateSession(args: update, sessionID: string): Session {
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

type update = {
  checked: boolean;
  id: number;
};

function randString(): string {
  const L = 16;
  let result = "";
  const characters =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  const charactersLength = characters.length;
  let counter = 0;
  while (counter < L) {
    result += characters.charAt(Math.floor(Math.random() * charactersLength));
    counter += 1;
  }
  return result;
}
