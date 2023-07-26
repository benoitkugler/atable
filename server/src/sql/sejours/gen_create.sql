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

