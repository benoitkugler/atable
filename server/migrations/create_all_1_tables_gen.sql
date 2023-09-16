CREATE TABLE users (
    Id serial PRIMARY KEY,
    IsAdmin boolean NOT NULL,
    Mail text NOT NULL,
    Password text NOT NULL,
    Pseudo text NOT NULL
);

CREATE TABLE ingredients (
    Id serial PRIMARY KEY,
    Name text NOT NULL,
    Kind integer CHECK (Kind IN (0, 1, 2, 3, 4, 5, 6)) NOT NULL,
    Owner integer NOT NULL
);

CREATE TABLE menus (
    Id serial PRIMARY KEY,
    Owner integer NOT NULL,
    IsFavorite boolean NOT NULL,
    IsPublished boolean NOT NULL,
    Updated timestamp(0) with time zone NOT NULL
);

CREATE TABLE menu_ingredients (
    IdMenu integer NOT NULL,
    IdIngredient integer NOT NULL,
    Quantity jsonb NOT NULL,
    Plat integer CHECK (Plat IN (0, 1, 2, 3)) NOT NULL
);

CREATE TABLE menu_receipes (
    IdMenu integer NOT NULL,
    IdReceipe integer NOT NULL
);

CREATE TABLE receipes (
    Id serial PRIMARY KEY,
    Owner integer NOT NULL,
    Plat integer CHECK (Plat IN (0, 1, 2, 3)) NOT NULL,
    Name text NOT NULL,
    Description text NOT NULL,
    IsPublished boolean NOT NULL,
    Updated timestamp(0) with time zone NOT NULL
);

CREATE TABLE receipe_ingredients (
    IdReceipe integer NOT NULL,
    IdIngredient integer NOT NULL,
    Quantity jsonb NOT NULL
);

CREATE TABLE GROUPS (
    Id serial PRIMARY KEY,
    Sejour integer NOT NULL,
    Name text NOT NULL,
    Color text NOT NULL,
    Size integer NOT NULL
);

CREATE TABLE meals (
    Id serial PRIMARY KEY,
    Sejour integer NOT NULL,
    Menu integer NOT NULL,
    Jour integer NOT NULL,
    AdditionalPeople integer NOT NULL,
    Horaire integer CHECK (Horaire IN (0, 1, 2, 3, 4)) NOT NULL
);

CREATE TABLE meal_groups (
    IdMeal integer NOT NULL,
    IdGroup integer NOT NULL
);

CREATE TABLE sejours (
    Id serial PRIMARY KEY,
    Owner integer NOT NULL,
    Start date NOT NULL,
    Name text NOT NULL,
    IdProfile integer
);

