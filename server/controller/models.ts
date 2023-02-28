export type Session = {
  id: string;
  list: ShopList;
};

export type ShopList = IngredientQuantite[];

type IngredientQuantite = {
  id: number;
  nom: string;
  categorie: CategorieIngredient;
  quantite: string;
  checked: boolean;
};

type CategorieIngredient = number; // uint8
