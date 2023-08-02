package shopsession

import (
	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/sejours"
)

type Session struct {
	Id   string
	List ShopList
}

type CreateSessionOut struct {
	SessionID string
}

type UpdateSessionIn struct {
	Id      menus.IdIngredient
	Checked bool
}

type ShopList []IngredientUses

type IngredientUses struct {
	Ingredient menus.Ingredient
	Quantites  []Quantite
	Checked    bool
}

type Quantite struct {
	Quantite float64
	Unite    menus.Unite
	Origin   Origin
}

type Origin struct {
	MealDate    sejours.Date
	MealName    string
	ReceipeName string // empty for free ingredients
}
