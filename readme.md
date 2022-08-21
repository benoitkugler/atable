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

L'objet fondamental est l'**ingredient**, caractérisé par un nom et une unité (Kg, L, Pièce). Ces ingrédients sont regroupés en **menu**s, un menu étant défini par une liste d'ingrédient et de quantités (relatives, le nombre de personnes n'étant pas défini dans un menu). Finalement un **repas** est un menu, défini pour un jour et un nombre de personnes.
