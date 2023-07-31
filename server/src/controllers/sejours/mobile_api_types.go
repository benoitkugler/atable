package sejours

import (
	"github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
)

type MealM struct {
	Id     sej.IdMeal
	IdMenu menus.IdMenu
	Name   string
	Date   sej.Date
	For    int `json:"For_"`
}

type TablesM struct {
	library.MenuTables
	Meals []MealM
}
