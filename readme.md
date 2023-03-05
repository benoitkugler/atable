# A table !

### Une appli mobile pour faciler l'intendance en collectivité, de la composition de menus à la cuisine.

## Objectifs

- Planifier les repas sur un agenda (vue "Au bureau")
- Calculer automatiquement les quantités en fonction du nombre de personnes
- Regrouper les ingrédients pour fournir une liste de courses (vue "En magasin")
- Mettre à jour, de manière partageable, une liste à cocher pour les courses en magasin
- Afficher la recette d'un repas, à utiliser pendant leur confection (vue "En cuisine")
- (Bonus) Faciliter l'importation de menus existants depuis un format texte
- (Bonus) Classer les ingrédients par catégorie, pour les regrouper dans la liste de courses

## Vue d'ensemble de l'implémentation

Le projet est concentrée sur une application mobile, utilisable hors connection. La persistence des données est assurée par une base SQL stockée localement.
Un serveur contrôle la fonction d'édition partagée d'une liste de courses.

## Structure de la base de données

L'objet fondamental est l'**ingredient**, caractérisé par un nom et une catégorie.
Les ingrédients sont regroupés avec une quantité (relative) et une unité (Kg, L, Pièce) pour former une recette.
Un menu regroupe des recettes et des ingrédients additionnels.
Finalement, un repas est défini par un menu, un jour et un nombre de personnes.
