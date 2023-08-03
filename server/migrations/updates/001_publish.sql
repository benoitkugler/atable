BEGIN;
ALTER TABLE receipes
    ADD COLUMN IsPublished boolean;
ALTER TABLE menus
    ADD COLUMN IsPublished boolean;
UPDATE
    receipes
SET
    IsPublished = FALSE;
UPDATE
    menus
SET
    IsPublished = FALSE;
ALTER TABLE receipes
    ALTER COLUMN IsPublished SET NOT NULL;
ALTER TABLE menus
    ALTER COLUMN IsPublished SET NOT NULL;
ALTER TABLE menus
    ADD CHECK (IsPublished = FALSE
        OR IsFavorite = TRUE);
COMMIT;

