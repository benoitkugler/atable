package sejours

import (
	"fmt"
	"sort"
	"strings"
	"time"

	lib "github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/pass"
	sej "github.com/benoitkugler/atable/sql/sejours"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

// Mobile API
const (
	ClientEnpoint    = "/api/client/import-sejour"
	clientQueryParam = "idSejour"
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

const day = 24 * time.Hour

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

	out.MenuTables, err = lib.LoadMenus(ct.db, meals.Menus())
	if err != nil {
		return out, err
	}

	// convert to the simplified mobile version
	out.Meals = make([]MealM, 0, len(meals))
	for _, meal := range meals {
		// build the name from the sejour and groups,
		// compute the number of people from the groups and bonus
		var (
			forNb      = meal.AdditionalPeople
			groupNames []string
		)
		for _, link := range mealsToGroups[meal.Id] {
			gr := groups[link.IdGroup]
			forNb += gr.Size
			groupNames = append(groupNames, gr.Name)
		}
		sort.Strings(groupNames)

		name := sejour.Name
		if len(groupNames) == 0 || len(groupNames) == len(groups) {
			// do not include group names
		} else {
			name += fmt.Sprintf(" (%s)", strings.Join(groupNames, ", "))
		}

		// adjust the date, also encoding the horaire
		date := sejour.Start.T().Add(time.Duration(meal.Jour) * day)
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
