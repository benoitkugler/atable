import 'package:atable/logic/models.dart';

const tomates = Ingredient(
    id: 1,
    nom: "Tomate",
    unite: Unite.kg,
    categorie: CategorieIngredient.legumes);
const pates = Ingredient(
    id: 2,
    nom: "Pâtes",
    unite: Unite.kg,
    categorie: CategorieIngredient.inconnue);
const lait = Ingredient(
    id: 3,
    nom: "Lait",
    unite: Unite.L,
    categorie: CategorieIngredient.laitages);
const sel = Ingredient(
    id: 4,
    nom: "Sel",
    unite: Unite.piece,
    categorie: CategorieIngredient.epicerie);

final sampleMenus = [
  MenuExt(Menu(id: 1, date: DateTime.now(), nbPersonnes: 10), const [
    MenuIngredientExt(tomates, 0.1, CategoriePlat.entree),
    MenuIngredientExt(tomates, 0.1, CategoriePlat.platPrincipal),
    MenuIngredientExt(pates, 0.1, CategoriePlat.platPrincipal),
    MenuIngredientExt(lait, 0.1, CategoriePlat.dessert),
  ]),
  MenuExt(Menu(id: 2, date: DateTime.now(), nbPersonnes: 20), const [
    MenuIngredientExt(tomates, 0.1, CategoriePlat.entree),
    MenuIngredientExt(tomates, 0.1, CategoriePlat.platPrincipal),
    MenuIngredientExt(pates, 0.1, CategoriePlat.platPrincipal),
    MenuIngredientExt(lait, 0.1, CategoriePlat.dessert),
    MenuIngredientExt(sel, 8, CategoriePlat.divers),
  ]),
];
