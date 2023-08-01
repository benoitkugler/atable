package sejours

import (
	men "github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
)

type MealM struct {
	Date   sej.Date
	Name   string
	Id     sej.IdMeal
	IdMenu men.IdMenu
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
