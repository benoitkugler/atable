package shopsession

import (
	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/sejours"
)

//go:generate /home/benoit/go/src/github.com/benoitkugler/gomacro/cmd/gomacro types.go go/unions:types_gen.go

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

type Origin interface {
	isOrigin()
}

type OriginMeal struct {
	MealDate    sejours.Date
	MealHoraire sejours.Horaire
	Groupes     []string
	ReceipeName string // empty for free ingredients
}

type OriginStock struct{}

func (OriginMeal) isOrigin()  {}
func (OriginStock) isOrigin() {}
