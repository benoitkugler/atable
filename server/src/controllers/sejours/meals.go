package sejours

import (
	"database/sql"
	"sort"

	"github.com/benoitkugler/atable/controllers/users"
	men "github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

// SejoursGetRepas loads the [Meals] setup on the given sejour,
// which should be diplayed in an agenda.
func (ct *Controller) MealsGet(c echo.Context) error {
	uID := users.JWTUser(c)

	id_, err := utils.QueryParamInt64(c, "id-sejour")
	if err != nil {
		return err
	}

	out, err := ct.getMeals(sej.IdSejour(id_), uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

// type MenuIngredientExt struct {
// 	Ingredient men.Ingredient
// 	Quantite   men.QuantityR
// }

// type MenuExt struct {
// 	Receipes    []men.Receipes
// 	Ingredients []men.MenuIngredient
// }

type MealHeader struct {
	Meal        sej.Meal
	Groups      []sej.Group // the groups affected (maybe empty)
	IsMenuEmpty bool
}

func (ct *Controller) getMeals(idSejour sej.IdSejour, uID us.IdUser) ([]MealHeader, error) {
	sejour, err := ct.checkSejourOwner(idSejour, uID)
	if err != nil {
		return nil, err
	}

	// load the meals
	meals, err := sej.SelectMealsBySejours(ct.db, sejour.Id)
	if err != nil {
		return nil, utils.SQLError(err)
	}

	// load the underlying [Menu]s and their content
	idMenus := meals.Menus()

	link1, err := men.SelectMenuReceipesByIdMenus(ct.db, idMenus...)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	link2, err := men.SelectMenuIngredientsByIdMenus(ct.db, idMenus...)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	receipes, ingredients := link1.ByIdMenu(), link2.ByIdMenu()

	// load the groups affected to the meals
	links, err := sej.SelectMealGroupsByIdMeals(ct.db, meals.IDs()...)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	groupsByMeal := links.ByIdMeal()

	groups, err := sej.SelectGroups(ct.db, links.IdGroups()...)
	if err != nil {
		return nil, utils.SQLError(err)
	}

	out := make([]MealHeader, 0, len(meals))
	for _, meal := range meals {
		// resolve groups
		var groupL []sej.Group
		for _, gr := range groupsByMeal[meal.Id] {
			groupL = append(groupL, groups[gr.IdGroup])
		}
		sort.Slice(groupL, func(i, j int) bool { return groupL[i].Id < groupL[j].Id })

		out = append(out, MealHeader{
			Meal:        meal,
			Groups:      groupL,
			IsMenuEmpty: len(receipes[meal.Menu])+len(ingredients[meal.Menu]) == 0,
		})
	}

	return out, nil
}

type AssistantMealsIn struct {
	IdSejour           sej.IdSejour
	DaysNumber         int
	Excursions         map[int][]sej.IdGroup // for each day, the groups in excursion
	WithGouter         bool
	GroupsForCinquieme []sej.IdGroup
	DeleteExisting     bool
}

// MealsWizzard is a shortcut to quickly create several [Meal]s for
// the given sejour.
// It returns the whole meals for the given sejour, not only the created ones.
func (ct *Controller) MealsWizzard(c echo.Context) error {
	uID := users.JWTUser(c)

	var args AssistantMealsIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.assistantMeals(args, uID)
	if err != nil {
		return err
	}

	out, err := ct.getMeals(args.IdSejour, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

// we special-case the Cinquieme (due to groups)
func (o AssistantMealsIn) resoudHoraires() []sej.Horaire {
	horaires := []sej.Horaire{sej.PetitDejeuner, sej.Midi, sej.Diner}
	if o.WithGouter {
		horaires = append(horaires, sej.Gouter)
	}
	return horaires
}

// crée un repas et y ajoute les groupes donnés
// DO NOT commit, DO NOT rollback
func createMeal(tx *sql.Tx, idSejour sej.IdSejour,
	horaire sej.Horaire, jourOffset int, idsGroupes sej.IdGroupSet, uID us.IdUser,
) error {
	// create a [Menu]...
	menu, err := men.Menu{Owner: uID}.Insert(tx)
	if err != nil {
		return utils.SQLError(err)
	}
	// and use it in a [Meal]
	meal, err := sej.Meal{
		Sejour:  idSejour,
		Menu:    menu.Id,
		Horaire: horaire,
		Jour:    jourOffset,
	}.Insert(tx)
	if err != nil {
		return utils.SQLError(err)
	}
	// associat the correct groups
	var rg []sej.MealGroup
	for idGroupe := range idsGroupes {
		rg = append(rg, sej.MealGroup{IdGroup: idGroupe, IdMeal: meal.Id})
	}
	if err = sej.InsertManyMealGroups(tx, rg...); err != nil {
		return utils.SQLError(err)
	}
	return nil
}

// delete the given [Meal]s, also removing the underlying [Menu]s
// when :
//   - not used anymore
//   - not in favorites
func deleteMeals(tx sej.DB, ids []sej.IdMeal) error {
	// store the linked [Menu]s
	meals, err := sej.SelectMeals(tx, ids...)
	if err != nil {
		return utils.SQLError(err)
	}

	// now remove the [Meal]s
	_, err = sej.DeleteMealsByIDs(tx, ids...)
	if err != nil {
		return utils.SQLError(err)
	}

	// cleanup the [Menu]s when possible
	menus := meals.Menus()

	consumers, err := sej.SelectMealsByMenus(tx, menus...)
	if err != nil {
		return utils.SQLError(err)
	}
	usedMenus := men.NewIdMenuSetFrom(consumers.Menus())

	allMenus, err := men.SelectMenus(tx, menus...)
	if err != nil {
		return utils.SQLError(err)
	}
	// filter
	var toDelete []men.IdMenu
	for _, menu := range allMenus {
		if !menu.IsFavorite && !usedMenus.Has(menu.Id) {
			toDelete = append(toDelete, menu.Id)
		}
	}
	_, err = men.DeleteMenusByIDs(tx, toDelete...)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
}

func (ct *Controller) assistantMeals(args AssistantMealsIn, uID us.IdUser) error {
	sejour, err := ct.checkSejourOwner(args.IdSejour, uID)
	if err != nil {
		return err
	}

	tx, err := ct.db.Begin()
	if err != nil {
		return utils.SQLError(err)
	}

	if args.DeleteExisting {
		meals, err := sej.SelectMealsBySejours(tx, sejour.Id)
		if err != nil {
			_ = tx.Rollback()
			return utils.SQLError(err)
		}

		// remove all existing [Meal]s
		err = deleteMeals(tx, meals.IDs())
		if err != nil {
			_ = tx.Rollback()
			return utils.SQLError(err)
		}
	}

	// fetch the groups
	groups, err := sej.SelectGroupsBySejours(tx, args.IdSejour)
	if err != nil {
		_ = tx.Rollback()
		return utils.SQLError(err)
	}

	// handle Gouter
	horaires := args.resoudHoraires()

	for jourOffset := 0; jourOffset < args.DaysNumber; jourOffset++ {
		// resolve the two lists : basic or with excursion
		sorties := sej.NewIdGroupSetFrom(args.Excursions[jourOffset])
		basique := make(sej.IdGroupSet)
		for idGroupe := range groups {
			if !sorties.Has(idGroupe) {
				basique.Add(idGroupe)
			}
		}

		for _, horaire := range horaires {
			if len(sorties) != 0 {
				// create the meal for the excursion
				err = createMeal(tx, sejour.Id, horaire, jourOffset, sorties, uID)
				if err != nil {
					_ = tx.Rollback()
					return utils.SQLError(err)
				}
			}

			if len(sorties) == 0 || len(basique) > 0 {
				// no excursion or basique not empty -> create a meal
				err = createMeal(tx, sejour.Id, horaire, jourOffset, basique, uID)
				if err != nil {
					_ = tx.Rollback()
					return utils.SQLError(err)
				}
			}
		}

		// cas du cinquième
		if groupes5 := args.GroupsForCinquieme; len(groupes5) > 0 {
			err = createMeal(tx, sejour.Id, sej.Cinquieme, jourOffset, sej.NewIdGroupSetFrom(groupes5), uID)
			if err != nil {
				_ = tx.Rollback()
				return utils.SQLError(err)
			}
		}
	}

	err = tx.Commit()
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
}
