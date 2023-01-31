# Analyse un fichier CSV produit par https://cookteau.com/fr/home/#database

import sys
import csv
catMap = {
    'Champignons': 'legumes',
    'Boulangerie': 'boulangerie',
    'Plante': 'legumes',
    'Légumes': "legumes",
    'Boisson': "epicerie",
    'Plantes': "legumes",
    'Champignon': "legumes",
    'Fruits à coque et graines': "legumes",
    'Noix et graines': "epicerie",
    'Fruits': "legumes",
    'Additif': "inconnue",
    'Produits laitiers': "laitages",
    'Plats cuisinés': "inconnue",
    'Légumineuse': "legumes",
    'Épice': "epicerie",
    'Plat': "inconnue",
    'Boisson alcoolisée': "inconnue",
    'Dish': "inconnue",
    'Boissons': "inconnue",
    'Légumineuses': "legumes",
    'Laitière': "laitages", 'Usine': "inconnue",
    'Boissons alcoolisées': "inconnue",
    'Huile essentielle': "inconnue",
    'Vaisselle': "inconnue",
    'gingembre ail feuille de coriandre': "epicerie",
    'Herbe': "epicerie",
    'Légume': "legumes",
    'Assiette': "inconnue",
    'Herb': "epicerie",
    'Maïs': "legumes",
    'Végétal': "legumes",
    'Céréales': "legumes",
    'Fruit': "legumes",
    'Viande': "viandes",
    'Fleur': "inconnue",
    'Maize': "inconnue",
    'Plats': "inconnue",
    'Boisson Alcoolisée': "inconnue",
    'Poisson': "viandes",
    'Végétale': "legumes",
    'Céréale': "legumes", 'Épices': "epicerie", 'Fruits de mer': "viandes"
}


csvFileName = sys.argv[1]

lines = []

with open(csvFileName) as f:
    re = csv.reader(f, delimiter=';')
    next(re)  # saute la première ligne
    for line in re:
        name = line[2].replace("Œ", "Oe").replace("œ", "oe")
        categorie = line[6]
        categorie = catMap[categorie]
        code = f"""Ingredient(id: -1, nom: "{name}", unite: Unite.kg, categorie: CategorieIngredient.{categorie})"""
        lines.append(code)

code = ',\n'.join(lines)
print(f"""
import 'package:atable/logic/models.dart';

const ingredientsSuggestions = [{code}];
""")
