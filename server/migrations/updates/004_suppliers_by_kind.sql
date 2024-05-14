CREATE TABLE ingredientkind_suppliers (
    Kind integer CHECK (Kind IN (0, 1, 2, 3, 4, 5, 6)) NOT NULL,
    IdSupplier integer NOT NULL,
    IdProfile integer NOT NULL
);

