
-- sql/users/gen_create.sql
-- Code genererated by gomacro/generator/sql. DO NOT EDIT.
CREATE TABLE users (
    Id serial PRIMARY KEY,
    IsAdmin boolean NOT NULL,
    Mail text NOT NULL,
    Password text NOT NULL,
    Pseudo text NOT NULL
);

-- constraints
ALTER TABLE users
    ADD UNIQUE (Mail);

-- sql/menus/gen_create.sql
-- Code genererated by gomacro/generator/sql. DO NOT EDIT.
CREATE TABLE ingredients (
    Id serial PRIMARY KEY,
    Name text NOT NULL,
    Kind integer CHECK (Kind IN (0, 1, 2, 3, 4, 5, 6)) NOT NULL
);

CREATE TABLE menus (
    Id serial PRIMARY KEY,
    Owner integer NOT NULL
);

CREATE TABLE menu_ingredients (
    IdMenu integer NOT NULL,
    IdIngredient integer NOT NULL,
    Quantity jsonb NOT NULL,
    Plat integer CHECK (Plat IN (0, 1, 2, 3)) NOT NULL
);

CREATE TABLE menu_recettes (
    IdMenu integer NOT NULL,
    IdReceipe integer NOT NULL
);

CREATE TABLE receipes (
    Id serial PRIMARY KEY,
    Owner integer NOT NULL,
    Plat integer CHECK (Plat IN (0, 1, 2, 3)) NOT NULL,
    Name text NOT NULL,
    Description text NOT NULL
);

CREATE TABLE receipe_items (
    IdReceipe integer NOT NULL,
    IdIngredient integer NOT NULL,
    Quantity jsonb NOT NULL
);

-- constraints
ALTER TABLE ingredients
    ADD UNIQUE (Name);

ALTER TABLE receipes
    ADD UNIQUE (Name);

ALTER TABLE receipes
    ADD FOREIGN KEY (OWNER) REFERENCES users ON DELETE CASCADE;

ALTER TABLE receipe_items
    ADD UNIQUE (IdReceipe, IdIngredient);

ALTER TABLE receipe_items
    ADD FOREIGN KEY (IdReceipe) REFERENCES receipes ON DELETE CASCADE;

ALTER TABLE receipe_items
    ADD FOREIGN KEY (IdIngredient) REFERENCES ingredients;

ALTER TABLE menus
    ADD FOREIGN KEY (OWNER) REFERENCES users ON DELETE CASCADE;

ALTER TABLE menu_ingredients
    ADD FOREIGN KEY (IdMenu) REFERENCES menus ON DELETE CASCADE;

ALTER TABLE menu_ingredients
    ADD FOREIGN KEY (IdIngredient) REFERENCES ingredients;

ALTER TABLE menu_recettes
    ADD FOREIGN KEY (IdMenu) REFERENCES menus ON DELETE CASCADE;

ALTER TABLE menu_recettes
    ADD FOREIGN KEY (IdReceipe) REFERENCES receipes;

CREATE OR REPLACE FUNCTION gomacro_validate_json_menu_QuantityR (data jsonb)
    RETURNS boolean
    AS $$
DECLARE
    is_valid boolean;
BEGIN
    IF jsonb_typeof(data) != 'object' THEN
        RETURN FALSE;
    END IF;
    is_valid := (
        SELECT
            bool_and(key IN ('Val', 'Unite', 'For'))
        FROM
            jsonb_each(data))
        AND gomacro_validate_json_number (data -> 'Val')
        AND gomacro_validate_json_menu_Unite (data -> 'Unite')
        AND gomacro_validate_json_number (data -> 'For');
    RETURN is_valid;
END;
$$
LANGUAGE 'plpgsql'
IMMUTABLE;

CREATE OR REPLACE FUNCTION gomacro_validate_json_menu_Unite (data jsonb)
    RETURNS boolean
    AS $$
DECLARE
    is_valid boolean := jsonb_typeof(data) = 'number'
    AND data::int IN (0, 1, 2, 3, 4);
BEGIN
    IF NOT is_valid THEN
        RAISE WARNING '% is not a menu_Unite', data;
    END IF;
    RETURN is_valid;
END;
$$
LANGUAGE 'plpgsql'
IMMUTABLE;

CREATE OR REPLACE FUNCTION gomacro_validate_json_number (data jsonb)
    RETURNS boolean
    AS $$
DECLARE
    is_valid boolean := jsonb_typeof(data) = 'number';
BEGIN
    IF NOT is_valid THEN
        RAISE WARNING '% is not a number', data;
    END IF;
    RETURN is_valid;
END;
$$
LANGUAGE 'plpgsql'
IMMUTABLE;

ALTER TABLE menu_ingredients
    ADD CONSTRAINT Quantity_gomacro CHECK (gomacro_validate_json_menu_QuantityR (Quantity));

ALTER TABLE receipe_items
    ADD CONSTRAINT Quantity_gomacro CHECK (gomacro_validate_json_menu_QuantityR (Quantity));

-- sql/sejours/gen_create.sql
-- Code genererated by gomacro/generator/sql. DO NOT EDIT.
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
    Name text NOT NULL
);

-- constraints
ALTER TABLE sejours
    ADD UNIQUE (Id, OWNER);

ALTER TABLE sejours
    ADD FOREIGN KEY (OWNER) REFERENCES users ON DELETE CASCADE;

ALTER TABLE GROUPS
    ADD FOREIGN KEY (Sejour) REFERENCES sejours ON DELETE CASCADE;

ALTER TABLE meals
    ADD FOREIGN KEY (Sejour) REFERENCES sejours ON DELETE CASCADE;

ALTER TABLE meals
    ADD FOREIGN KEY (Menu) REFERENCES menus;

ALTER TABLE meal_groups
    ADD UNIQUE (IdMeal, IdGroup);

ALTER TABLE meal_groups
    ADD FOREIGN KEY (IdMeal) REFERENCES meals ON DELETE CASCADE;

ALTER TABLE meal_groups
    ADD FOREIGN KEY (IdGroup) REFERENCES GROUPS ON DELETE CASCADE;

