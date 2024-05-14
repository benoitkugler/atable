// This package models the data structure used for suppliers
// and profil of ingredient to product associations.
package orders

import (
	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/lib/pq"
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
	IdOwner users.IdUser `gomacro-sql-on-delete:"CASCADE"` // the owner (with modification permittion)

	Name string // for instance, the location this profile is relevant to
}

// IngredientkindSupplier is a link mapping all the ingredients
// with the given kind to a supplier
//
// gomacro:SQL ADD UNIQUE(IdProfile, Kind)
// gomacro:SQL ADD FOREIGN KEY(IdSupplier, IdProfile) REFERENCES Suppliers (Id, IdProfile) ON DELETE CASCADE
type IngredientkindSupplier struct {
	Kind       menus.IngredientKind
	IdSupplier IdSupplier `gomacro-sql-on-delete:"CASCADE"`
	IdProfile  IdProfile  `gomacro-sql-on-delete:"CASCADE"` // used for consistency
}

// ByKind assume only one profile is used and return the associated mapping
func (links IngredientkindSuppliers) ByKind() map[menus.IngredientKind]IdSupplier {
	out := make(map[menus.IngredientKind]IdSupplier)
	for _, link := range links {
		out[link.Kind] = link.IdSupplier
	}
	return out
}

// Kinds assumes only one supplier and returns its kinds
func (links IngredientkindSuppliers) Kinds() []menus.IngredientKind {
	out := make([]menus.IngredientKind, len(links))
	for i, l := range links {
		out[i] = l.Kind
	}
	return out
}

func RemoveSupplierForKinds(db DB, kinds []menus.IngredientKind, profile IdProfile) error {
	ints := make(pq.Int32Array, len(kinds))
	for i, k := range kinds {
		ints[i] = int32(k)
	}

	_, err := db.Exec("DELETE FROM ingredientkind_suppliers WHERE kind = ANY($1) AND idprofile = $2;", ints, profile)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

// IngredientSupplier is a link mapping one ingredient to a supplier.
//
// gomacro:SQL ADD UNIQUE(IdProfile, IdIngredient)
// gomacro:SQL ADD FOREIGN KEY(IdSupplier, IdProfile) REFERENCES Suppliers (Id, IdProfile) ON DELETE CASCADE
// gomacro:SQL _SELECT KEY(IdProfile, IdIngredient)
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
