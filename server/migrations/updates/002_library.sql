-- v0.0.8
--

BEGIN;
-- add Owner to ingredients
ALTER TABLE ingredients
    ADD COLUMN OWNER integer;
UPDATE
    ingredients
SET
    OWNER = 1;
ALTER TABLE ingredients
    ALTER COLUMN OWNER SET NOT NULL;
ALTER TABLE ingredients
    ADD FOREIGN KEY (OWNER) REFERENCES users ON DELETE CASCADE;
-- add Updated to receipe and menu
ALTER TABLE receipes
    ADD COLUMN Updated timestamp(0) WITH time zone;
UPDATE
    receipes
SET
    Updated = Now();
ALTER TABLE receipes
    ALTER COLUMN Updated SET NOT NULL;
--
ALTER TABLE menus
    ADD COLUMN Updated timestamp(0) WITH time zone;
UPDATE
    menus
SET
    Updated = Now();
ALTER TABLE menus
    ALTER COLUMN Updated SET NOT NULL;
--
COMMIT;

