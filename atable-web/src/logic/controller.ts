import { devLogMeta } from "@/env";
import { AbstractAPI, Horaire, HoraireLabels, SejourExt } from "./api_gen";
import { json } from "stream/consumers";

function arrayBufferToString(buffer: ArrayBuffer) {
  const uintArray = new Uint8Array(buffer);
  const encodedString = String.fromCharCode.apply(null, Array.from(uintArray));
  return decodeURIComponent(escape(encodedString));
}

class Controller extends AbstractAPI {
  public activeSejour: SejourExt | null = null;

  /** UI hook which should display an error */
  public onError?: (kind: string, htmlError: string) => void;

  /** UI hook which should display a snackbar */
  public showMessage?: (message: string, color?: string) => void;

  public isLoggedIn = false;

  logout() {
    this.isLoggedIn = false;
    this.authToken = "";
  }

  getToken() {
    return this.authToken;
  }

  getURL(endpoint: string) {
    return this.baseUrl + endpoint;
  }

  startRequest(): void {}

  handleError(error: any): void {
    let kind: string, messageHtml: string;
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      kind = `Erreur côté serveur`;
      messageHtml = error.response.data.message;
      if (messageHtml) {
        messageHtml = "<i>" + messageHtml + "</i>";
      } else {
        try {
          const json = arrayBufferToString(error.response.data);
          messageHtml = JSON.parse(json).message;
        } catch (error) {
          messageHtml = `Le format d'erreur du serveur n'a pu être décodé.<br/>
        Détails : <i>${error}</i>`;
        }
      }
    } else if (error.request) {
      // The request was made but no response was received
      // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
      // http.ClientRequest in node.js
      kind = "Aucune réponse du serveur";
      messageHtml =
        "La requête a bien été envoyée, mais le serveur n'a donné aucune réponse...";
    } else {
      // Something happened in setting up the request that triggered an Error
      kind = "Erreur du client";
      messageHtml = `La requête n'a pu être mise en place. <br/>
                  Détails :  ${error.message} `;
    }

    if (this.onError) {
      this.onError(kind, messageHtml);
    }
  }
}

/** Stores the success messages which should be displayed
 * on a snackbar
 */
export class Messages {
  private _messages: { text: string; id: number; time: Date }[] = [];
  private queueIndex = 0;
  private static timeout = 4000;

  get messages() {
    return this._messages.map((v) => ({ text: v.text, time: v.time }));
  }

  /** adds the given message to the list */
  addMessage(message: string) {
    const index = this.queueIndex;
    this.queueIndex++;
    this._messages.push({ text: message, id: index, time: new Date() });
    setTimeout(() => {
      this._messages = this._messages.filter((v) => v.id != index);
    }, Messages.timeout);
  }

  clearMessages() {
    this._messages = [];
  }
}

export interface Error {
  Kind: string;
  HTML: string;
}

const localhost = "http://localhost:1323";

/** `IsDev` is true when the client app is served in dev mode */
export const IsDev = import.meta.env.DEV;

export function isInscriptionValidated() {
  return window.location.search.includes("show-success-inscription");
}

export const controller = new Controller(
  IsDev ? localhost : window.location.origin,
  IsDev ? devLogMeta.Token : ""
);

export function copy<T>(v: T): T {
  return JSON.parse(JSON.stringify(v));
}

export function addDays(date: Date, days: number) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

export function formatDate(date: Date) {
  if (isNaN(date.valueOf())) return "";
  return date.toLocaleDateString("fr-FR", {
    weekday: "short",
    day: "numeric",
    month: "short",
  });
}

export function formatHoraire(horaire: Horaire) {
  return HoraireLabels[horaire];
}
