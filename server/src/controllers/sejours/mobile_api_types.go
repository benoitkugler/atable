package sejours

import (
	men "github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
)

type MealM struct {
	Id     sej.IdMeal
	IdMenu men.IdMenu
	Name   string
	Date   sej.Date
	For    int `json:"For_"`
}

// we avoid maps since json store keys as String,
// complicating the decoding on the client side
type TablesM struct {
	Ingredients        []men.Ingredient
	Receipes           []men.Receipe
	ReceipeIngredients men.ReceipeIngredients
	Menus              []men.Menu
	MenuReceipes       men.MenuReceipes
	MenuIngredients    men.MenuIngredients
	Meals              []MealM
}
