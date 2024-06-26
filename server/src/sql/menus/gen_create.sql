-- Code genererated by gomacro/generator/sql. DO NOT EDIT.
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

-- constraints
ALTER TABLE ingredients
    ADD UNIQUE (Name);

ALTER TABLE ingredients
    ADD FOREIGN KEY (OWNER) REFERENCES users ON DELETE CASCADE;

ALTER TABLE receipes
    ADD UNIQUE (OWNER, Name);

ALTER TABLE receipes
    ADD FOREIGN KEY (OWNER) REFERENCES users ON DELETE CASCADE;

ALTER TABLE receipe_ingredients
    ADD UNIQUE (IdReceipe, IdIngredient);

ALTER TABLE receipe_ingredients
    ADD FOREIGN KEY (IdReceipe) REFERENCES receipes ON DELETE CASCADE;

ALTER TABLE receipe_ingredients
    ADD FOREIGN KEY (IdIngredient) REFERENCES ingredients;

ALTER TABLE menus
    ADD CHECK (IsPublished = FALSE
        OR IsFavorite = TRUE);

ALTER TABLE menus
    ADD FOREIGN KEY (OWNER) REFERENCES users ON DELETE CASCADE;

ALTER TABLE menu_ingredients
    ADD UNIQUE (IdMenu, IdIngredient);

ALTER TABLE menu_ingredients
    ADD FOREIGN KEY (IdMenu) REFERENCES menus ON DELETE CASCADE;

ALTER TABLE menu_ingredients
    ADD FOREIGN KEY (IdIngredient) REFERENCES ingredients;

ALTER TABLE menu_receipes
    ADD FOREIGN KEY (IdMenu) REFERENCES menus ON DELETE CASCADE;

ALTER TABLE menu_receipes
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
            bool_and(key IN ('Val', 'Unite', 'For_'))
        FROM
            jsonb_each(data))
        AND gomacro_validate_json_number (data -> 'Val')
        AND gomacro_validate_json_menu_Unite (data -> 'Unite')
        AND gomacro_validate_json_number (data -> 'For_');
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

ALTER TABLE receipe_ingredients
    ADD CONSTRAINT Quantity_gomacro CHECK (gomacro_validate_json_menu_QuantityR (Quantity));

