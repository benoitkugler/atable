package menus

import "atable/sql/users"

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
// with (relative) quantities (see [ReceipeItem]).
//
// [Receipe]s are owned by users.
//
// gomacro:SQL ADD UNIQUE(Name)
type Receipe struct {
	Id          IdReceipe
	Owner       users.IdUser `gomacro-sql-on-delete:"CASCADE"`
	Plat        PlatKind
	Name        string
	Description string // notice, optional
}

// ReceipeItem is a link object.
//
// gomacro:SQL ADD UNIQUE(IdReceipe, IdIngredient)
type ReceipeItem struct {
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
type Menu struct {
	Id    IdMenu
	Owner users.IdUser `gomacro-sql-on-delete:"CASCADE"`
}

// MenuIngredient is a link item
type MenuIngredient struct {
	IdMenu       IdMenu `gomacro-sql-on-delete:"CASCADE"`
	IdIngredient IdIngredient
	Quantity     QuantityR
	Plat         PlatKind
}

// MenuRecette is a link item
type MenuRecette struct {
	IdMenu    IdMenu `gomacro-sql-on-delete:"CASCADE"`
	IdReceipe IdReceipe
}
