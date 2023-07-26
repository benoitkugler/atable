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

