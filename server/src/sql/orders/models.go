// This package models the data structure used for suppliers
// and profil of ingredient to product associations.
package orders

import (
	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
)

type (
	IdSupplier int64
	IdProfile  int64
)

// gomacro:SQL ADD UNIQUE(Id, IdProfile)
type Supplier struct {
	Id        IdSupplier
	IdProfile IdProfile `gomacro-sql-on-delete:"CASCADE"` // the profile this supplier is part of

	Name string
}

// Profile defines a list of suppliers and map ingredients to
// suppliers.
//
// [Profile]s are public and may be shared among users.
type Profile struct {
	Id      IdProfile
	IdOwner users.IdUser `gomacro-sql-on-delete:"CASCADE"` // the owner (with modification permition)

	Name string // for instance, the location this profile is relevant to
}

// IngredientSupplier is a link mapping one ingredient to a supplier
//
// gomacro:SQL ADD UNIQUE(IdProfile, IdIngredient)
// gomacro:SQL ADD FOREIGN KEY(IdSupplier, IdProfile) REFERENCES Suppliers (Id, IdProfile) ON DELETE CASCADE
type IngredientSupplier struct {
	IdIngredient menus.IdIngredient `gomacro-sql-on-delete:"CASCADE"`
	IdSupplier   IdSupplier         `gomacro-sql-on-delete:"CASCADE"`
	IdProfile    IdProfile          `gomacro-sql-on-delete:"CASCADE"` // used for consistency
}

func RemoveSupplierFor(db DB, ingredients []menus.IdIngredient, profile IdProfile) error {
	_, err := db.Exec("DELETE FROM ingredient_suppliers WHERE idingredient = ANY($1) AND idprofile = $2;", menus.IdIngredientArrayToPQ(ingredients), profile)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}
