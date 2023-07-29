import { devLogMeta } from "@/env";
import {
  AbstractAPI,
  Horaire,
  HoraireLabels,
  IdUser,
  MenuExt,
  PlatKind,
  QuantityR,
  ResourceHeader,
  SejourExt,
} from "./api_gen";

function arrayBufferToString(buffer: ArrayBuffer) {
  const uintArray = new Uint8Array(buffer);
  const encodedString = String.fromCharCode.apply(null, Array.from(uintArray));
  return decodeURIComponent(escape(encodedString));
}

class Controller extends AbstractAPI {
  public idUser: IdUser = devLogMeta.IdUser;
  public activeSejour: SejourExt | null = null;

  /** UI hook which should display an error */
  public onError: (kind: string, htmlError: string) => void = () => {};

  /** UI hook which should display a snackbar */
  public showMessage: (message: string, color?: string) => void = () => {};

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

export const horairesItems = Object.entries(HoraireLabels).map((l) => ({
  value: Number(l[0]) as Horaire,
  title: l[1],
}));

export enum DragKind {
  ingredient,
  receipe,
  menu,
}

export interface ResourceDrag {
  item: ResourceHeader;
  kind: DragKind;
}

export const platColors: { [key in PlatKind]: string } = {
  [PlatKind.P_Empty]: "grey-darken-1",
  [PlatKind.P_Entree]: "green",
  [PlatKind.P_PlatPrincipal]: "orange-darken-3",
  [PlatKind.P_Dessert]: "pink-lighten-1",
};

export interface MenuResource {
  Id: number;
  Title: string;
  Kind: "receipe" | "ingredient";
}

export interface MenuItem {
  id: number;
  title: string;
  plat: PlatKind;
  isReceipe: boolean;
  quantity?: QuantityR; // null for receipe
}

export function sortMenuContent(menu: MenuExt): MenuItem[] {
  const out = (menu.Ingredients || [])
    .map(
      (ing): MenuItem => ({
        id: ing.IdIngredient,
        title: ing.Ingredient.Name,
        plat: ing.Plat,
        isReceipe: false,
        quantity: ing.Quantity,
      })
    )
    .concat(
      (menu.Receipes || []).map((rec) => ({
        id: rec.Id,
        title: rec.Name,
        plat: rec.Plat,
        isReceipe: true,
      }))
    );
  out.sort((a, b) =>
    a.plat == b.plat ? a.title.localeCompare(b.title) : -(a.plat - b.plat)
  );
  return out;
}

export class Debouncer {
  private timerId = 0;

  constructor(private action: (s: string) => void) {}

  /** onType will call `action` after a delay */
  onType = (pattern: string) => {
    const debounceDelay = 300;
    // cancel pending call
    clearTimeout(this.timerId);

    // delay new call for 'debounceDelay'
    this.timerId = window.setTimeout(() => this.action(pattern), debounceDelay);
  };
}
