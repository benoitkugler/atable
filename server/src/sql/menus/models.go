package menus

import "github.com/benoitkugler/atable/sql/users"

type (
	IdIngredient int64
	IdReceipe    int64
	IdMenu       int64
)

// Ingredient is the basic element
// used to build a receipe or a meal.
//
// [Ingredient]s are public, shared among users.
//
// gomacro:SQL ADD UNIQUE(Name)
type Ingredient struct {
	Id   IdIngredient
	Name string
	Kind IngredientKind
}

// Receipe is a list of ingredients
// with (relative) quantities (see [ReceipeIngredient]).
//
// [Receipe]s are owned by users.
//
// gomacro:SQL ADD UNIQUE(Owner, Name)
type Receipe struct {
	Id          IdReceipe
	Owner       users.IdUser `gomacro-sql-on-delete:"CASCADE"`
	Plat        PlatKind
	Name        string
	Description string // notice, optional
	IsPublished bool   // If true, other users may use it (as readonly)
}

// ReceipeIngredient is a link object.
//
// gomacro:SQL _SELECT KEY (IdReceipe, IdIngredient)
// gomacro:SQL ADD UNIQUE(IdReceipe, IdIngredient)
type ReceipeIngredient struct {
	IdReceipe    IdReceipe `gomacro-sql-on-delete:"CASCADE"`
	IdIngredient IdIngredient
	Quantity     QuantityR
}

// Menu describes one meal, as a list of
// [Receipe]s and additional [Ingredient]s.
//
// [Menu]s do not store contextual information (like time, number of people),
// and are typically accessed via a [sejours.Meal] entry.
//
// [Menu]s are owned by users, and might be shared accross several [sejours.Meal]s.
//
// gomacro:SQL ADD CHECK(IsPublished = false OR IsFavorite = true)
type Menu struct {
	Id    IdMenu
	Owner users.IdUser `gomacro-sql-on-delete:"CASCADE"`
	// If IsFavorite is true, the menu is not deleted
	// when no more [sejours.Meal]s are using it.
	IsFavorite bool

	// If true, other users may use it (as readonly)
	// It implies IsFavorite
	IsPublished bool
}

// MenuIngredient is a link item
//
// gomacro:SQL ADD UNIQUE(IdMenu, IdIngredient)
// gomacro:SQL _SELECT KEY (IdMenu, IdIngredient)
type MenuIngredient struct {
	IdMenu       IdMenu `gomacro-sql-on-delete:"CASCADE"`
	IdIngredient IdIngredient
	Quantity     QuantityR
	Plat         PlatKind
}

// MenuReceipe is a link item
//
// gomacro:SQL _SELECT KEY (IdMenu, IdReceipe)
type MenuReceipe struct {
	IdMenu    IdMenu `gomacro-sql-on-delete:"CASCADE"`
	IdReceipe IdReceipe
}
