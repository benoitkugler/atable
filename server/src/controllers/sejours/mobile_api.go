package sejours

import (
	"fmt"
	"sort"
	"strings"

	lib "github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/pass"
	sej "github.com/benoitkugler/atable/sql/sejours"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

// Mobile API
const (
	ClientEnpoint    = "/import-sejour"
	clientQueryParam = "id"
)

// SejoursExportToClient returns a list of the [Meal]s registred
// for the given sejour (as JSON payload).
// This endpoint should be used by a mobile app, in a setup step.
func (ct *Controller) SejoursExportToClient(c echo.Context) error {
	idCrypted := c.QueryParam(clientQueryParam)

	id_, err := ct.key.DecryptID(pass.EncryptedID(idCrypted))
	if err != nil {
		return err
	}

	out, err := ct.exportToClient(sej.IdSejour(id_))
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) exportToClient(idSejour sej.IdSejour) (out TablesM, _ error) {
	sejour, err := sej.SelectSejour(ct.db, idSejour)
	if err != nil {
		return out, utils.SQLError(err)
	}
	groups, err := sej.SelectGroupsBySejours(ct.db, sejour.Id)
	if err != nil {
		return out, utils.SQLError(err)
	}

	meals, err := sej.SelectMealsBySejours(ct.db, sejour.Id)
	if err != nil {
		return out, utils.SQLError(err)
	}

	links, err := sej.SelectMealGroupsByIdMeals(ct.db, meals.IDs()...)
	if err != nil {
		return out, utils.SQLError(err)
	}
	mealsToGroups := links.ByIdMeal()

	datas, err := lib.LoadMenus(ct.db, meals.Menus())
	if err != nil {
		return out, err
	}

	for _, ing := range datas.Ingredients {
		out.Ingredients = append(out.Ingredients, ing)
	}
	for _, rec := range datas.Receipes {
		out.Receipes = append(out.Receipes, rec)
	}
	out.ReceipeIngredients = datas.ReceipeIngredients
	for _, menu := range datas.Menus {
		out.Menus = append(out.Menus, menu)
	}
	out.MenuIngredients = datas.MenuIngredients
	out.MenuReceipes = datas.MenuReceipes

	// convert to the simplified mobile version
	out.Meals = make([]MealM, 0, len(meals))
	for _, meal := range meals {
		// compute the number of people from the groups and bonus
		forNb := ResolveSize(mealsToGroups[meal.Id], groups, meal.AdditionalPeople)

		// build the name from the sejour and groups
		var mealGroups []string
		for _, link := range mealsToGroups[meal.Id] {
			gr := groups[link.IdGroup]
			mealGroups = append(mealGroups, gr.Name)
		}
		sort.Strings(mealGroups)

		name := sejour.Name
		if len(mealGroups) == 0 {
			// do not include group names
		} else if len(mealGroups) == len(groups) && len(groups) > 1 {
			name += " (Tous)"
		} else {
			name += fmt.Sprintf(" (%s)", strings.Join(mealGroups, ", "))
		}

		// adjust the date, also encoding the horaire
		date := sejour.DayAt(meal.Jour)
		date = meal.Horaire.ApplyTo(date)

		out.Meals = append(out.Meals, MealM{
			Id:     meal.Id,
			IdMenu: meal.Menu,
			Name:   name,
			Date:   sej.Date(date),
			For:    forNb,
		})
	}

	return out, nil
}
