# À table !

### Une application pour faciler l'intendance en collectivité, de la composition des menus à la cuisine.

## Fonctionnalités

- Organiser ses recettes et menus
- Planifier les repas sur un agenda, pour un ou plusieurs séjours
- Calculer automatiquement les quantités en fonction du nombre de personnes
- Regrouper les ingrédients pour fournir une liste de courses
- Mettre à jour, de manière partageable, une liste à cocher pour les courses en magasin
- Afficher la recette d'un repas, à utiliser pendant leur confection

## Vue d'ensemble de l'implémentation

Le projet est découpé en deux interfaces. Une application web (supportée par une base SQL) permet de préparer en amont d'un séjour les menus. Ils sont ensuite exportable sur une application mobile, utilisable hors connection.
Le serveur contrôle aussi la fonction d'édition partagée d'une liste de courses.
