import { devLogMeta } from "@/env";
import {
  AbstractAPI,
  Group,
  Horaire,
  HoraireLabels,
  IdGroup,
  IdUser,
  IngredientKind,
  Ingredients,
  MenuExt,
  PlatKind,
  QuantityMeal,
  Quantity,
  QuantityR,
  Receipes,
  ResourceHeader,
  SejourExt,
  Unite,
  UniteLabels,
} from "./api_gen";

function arrayBufferToString(buffer: ArrayBuffer) {
  const uintArray = new Uint8Array(buffer);
  const encodedString = String.fromCharCode.apply(null, Array.from(uintArray));
  return decodeURIComponent(escape(encodedString));
}

class Controller extends AbstractAPI {
  public idUser: IdUser | null = null;
  public pseudo: string = "";
  public activeSejour: SejourExt | null = null;

  /** UI hook which should display an error */
  public onError: (kind: string, htmlError: string) => void = () => {};

  /** UI hook which should display a snackbar */
  public showMessage: (message: string, color?: string) => void = () => {};

  constructor(isDev: boolean) {
    super(
      isDev ? localhost : window.location.origin,
      isDev ? devLogMeta.Token : ""
    );
    if (isDev) {
      this.idUser = devLogMeta.IdUser;
    }
  }

  setLog(idUser: IdUser, token: string, pseudo: string) {
    this.idUser = idUser;
    this.authToken = token;
    this.pseudo = pseudo;

    this.activeSejour = null;
  }

  getToken() {
    return this.authToken;
  }

  getURL(endpoint: string) {
    return this.baseUrl + endpoint;
  }

  receipesExportURL() {
    return (
      this.baseUrl + `/api/library/receipes/export?token=${this.authToken}`
    );
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

export const controller = new Controller(IsDev);

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
  [PlatKind.P_Empty]: "grey-darken-2",
  [PlatKind.P_Entree]: "green",
  [PlatKind.P_PlatPrincipal]: "orange-darken-3",
  [PlatKind.P_Dessert]: "pink-lighten-1",
};

export const horaireColors: { [key in Horaire]: string } = {
  [Horaire.PetitDejeuner]: "grey-lighten-3",
  [Horaire.Midi]: "teal-lighten-4",
  [Horaire.Gouter]: "pink-lighten-4",
  [Horaire.Diner]: "brown-lighten-3",
  [Horaire.Cinquieme]: "grey-lighten-1",
};

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

export function upperFirst(s: string) {
  if (!s.length) return s;
  return s.at(0)?.toUpperCase() + s.substring(1);
}

export interface MenuResource {
  Id: number;
  Title: string;
  Kind: "receipe" | "ingredient";
  IngredientKind?: IngredientKind;
}

export function resourcesToList(ingredients: Ingredients, receipes: Receipes) {
  const out: MenuResource[] = Object.values(ingredients || {}).map((ing) => ({
    Title: ing.Name,
    Id: ing.Id,
    IngredientKind: ing.Kind,
    Kind: "ingredient",
  }));

  out.push(
    ...Object.values(receipes || {}).map((rec) => ({
      Title: rec.Name,
      Id: rec.Id,
      Kind: "receipe" as const,
    }))
  );

  out.sort((a, b) => a.Title.localeCompare(b.Title));
  return out;
}

export function groupMap(groups: Group[] | null) {
  return new Map<IdGroup, Group>((groups || []).map((gr) => [gr.Id, gr]));
}

export function aggregateQuantities(quantities: QuantityMeal[]): string {
  const byUnit = new Map<Unite, number>();
  quantities.forEach((qu) => {
    const uniq = uniquifyQuantity(qu.Quantity);
    byUnit.set(uniq.Unite, (byUnit.get(uniq.Unite) || 0) + uniq.Val);
  });

  const items: Quantity[] = Array.from(byUnit.entries()).map((l) => ({
    Unite: l[0],
    Val: l[1],
  }));
  items.sort((a, b) => a.Unite - b.Unite);
  return items.map(formatQuantity).join(" et ");
}

function uniquifyQuantity(qu: Quantity): Quantity {
  if (qu.Unite == Unite.U_Kg) {
    return { Unite: Unite.U_G, Val: qu.Val * 1000 };
  } else if (qu.Unite == Unite.U_L) {
    return { Unite: Unite.U_CL, Val: qu.Val * 100 };
  }
  return qu;
}

export function formatQuantity(qu: Quantity): string {
  if (qu.Unite == Unite.U_Kg && qu.Val < 1) {
    qu = { Unite: Unite.U_G, Val: qu.Val * 1000 };
  } else if (qu.Unite == Unite.U_G && qu.Val > 1000) {
    qu = { Unite: Unite.U_Kg, Val: qu.Val / 1000 };
  } else if (qu.Unite == Unite.U_L && qu.Val < 1) {
    qu = { Unite: Unite.U_CL, Val: qu.Val * 100 };
  } else if (qu.Unite == Unite.U_CL && qu.Val > 100) {
    qu = { Unite: Unite.U_L, Val: qu.Val / 100 };
  }
  return `${qu.Val} ${UniteLabels[qu.Unite]}`;
}
