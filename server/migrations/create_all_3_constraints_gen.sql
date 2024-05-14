ALTER TABLE users
    ADD UNIQUE (Mail);

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

ALTER TABLE menu_ingredients
    ADD CONSTRAINT Quantity_gomacro CHECK (gomacro_validate_json_menu_QuantityR (Quantity));

ALTER TABLE receipe_ingredients
    ADD CONSTRAINT Quantity_gomacro CHECK (gomacro_validate_json_menu_QuantityR (Quantity));

ALTER TABLE sejours
    ADD UNIQUE (Id, OWNER);

ALTER TABLE sejours
    ADD FOREIGN KEY (OWNER) REFERENCES users ON DELETE CASCADE;

ALTER TABLE sejours
    ADD FOREIGN KEY (IdProfile) REFERENCES profiles ON DELETE SET NULL;

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

ALTER TABLE suppliers
    ADD UNIQUE (Id, IdProfile);

ALTER TABLE suppliers
    ADD FOREIGN KEY (IdProfile) REFERENCES profiles ON DELETE CASCADE;

ALTER TABLE profiles
    ADD FOREIGN KEY (IdOwner) REFERENCES users ON DELETE CASCADE;

ALTER TABLE ingredientkind_suppliers
    ADD UNIQUE (IdProfile, Kind);

ALTER TABLE ingredientkind_suppliers
    ADD FOREIGN KEY (IdSupplier, IdProfile) REFERENCES Suppliers (Id, IdProfile) ON DELETE CASCADE;

ALTER TABLE ingredientkind_suppliers
    ADD FOREIGN KEY (IdSupplier) REFERENCES suppliers ON DELETE CASCADE;

ALTER TABLE ingredientkind_suppliers
    ADD FOREIGN KEY (IdProfile) REFERENCES profiles ON DELETE CASCADE;

ALTER TABLE ingredient_suppliers
    ADD UNIQUE (IdProfile, IdIngredient);

ALTER TABLE ingredient_suppliers
    ADD FOREIGN KEY (IdSupplier, IdProfile) REFERENCES Suppliers (Id, IdProfile) ON DELETE CASCADE;

ALTER TABLE ingredient_suppliers
    ADD FOREIGN KEY (IdIngredient) REFERENCES ingredients ON DELETE CASCADE;

ALTER TABLE ingredient_suppliers
    ADD FOREIGN KEY (IdSupplier) REFERENCES suppliers ON DELETE CASCADE;

ALTER TABLE ingredient_suppliers
    ADD FOREIGN KEY (IdProfile) REFERENCES profiles ON DELETE CASCADE;

