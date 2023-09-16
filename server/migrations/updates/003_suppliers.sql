BEGIN;
--
CREATE TABLE ingredient_suppliers (
    IdIngredient integer NOT NULL,
    IdSupplier integer NOT NULL,
    IdProfile integer NOT NULL
);
CREATE TABLE profiles (
    Id serial PRIMARY KEY,
    IdOwner integer NOT NULL,
    Name text NOT NULL
);
CREATE TABLE suppliers (
    Id serial PRIMARY KEY,
    IdProfile integer NOT NULL,
    Name text NOT NULL
);
-- constraints
ALTER TABLE suppliers
    ADD UNIQUE (Id, IdProfile);
ALTER TABLE suppliers
    ADD FOREIGN KEY (IdProfile) REFERENCES profiles ON DELETE CASCADE;
ALTER TABLE profiles
    ADD FOREIGN KEY (IdOwner) REFERENCES users ON DELETE CASCADE;
ALTER TABLE ingredient_suppliers
    ADD UNIQUE (IdProfile, IdIngredient);
ALTER TABLE ingredient_suppliers
    ADD FOREIGN KEY (IdSupplier, IdProfile) REFERENCES Suppliers (Id, IdProfile);
ALTER TABLE ingredient_suppliers
    ADD FOREIGN KEY (IdIngredient) REFERENCES ingredients ON DELETE CASCADE;
ALTER TABLE ingredient_suppliers
    ADD FOREIGN KEY (IdSupplier) REFERENCES suppliers ON DELETE CASCADE;
ALTER TABLE ingredient_suppliers
    ADD FOREIGN KEY (IdProfile) REFERENCES profiles ON DELETE CASCADE;
--
ALTER TABLE sejours
    ADD COLUMN IdProfile integer;
ALTER TABLE sejours
    ADD FOREIGN KEY (IdProfile) REFERENCES profiles ON DELETE SET NULL;
--
COMMIT;

