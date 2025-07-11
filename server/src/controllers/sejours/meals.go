package sejours

import (
	"database/sql"
	"fmt"
	"net/url"
	"sort"
	"strings"
	"time"

	lib "github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/controllers/users"
	men "github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

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

	out, err := ct.loadMeals(args.IdSejour, optionnalInt{}, uID)
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
	menu, err := men.Menu{Owner: uID, Updated: men.Time(time.Now())}.Insert(tx)
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

func garbageCollectMenus(tx men.DB, menus []men.IdMenu) error {
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
	err = garbageCollectMenus(tx, menus)
	return err
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

// MealsSearch searches the given string among
// [Ingredient]s, [Receipe]s and (favorite) [Menu]s
func (ct *Controller) MealsSearch(c echo.Context) error {
	uID := users.JWTUser(c)

	search := c.QueryParam("search")

	out, err := ct.searchResource(search, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

type platTitle struct {
	title string
	kind  men.PlatKind
}

func sortedTitle(chunks []platTitle) string {
	if len(chunks) == 0 {
		return ""
	}
	sort.Slice(chunks, func(i, j int) bool { return chunks[i].kind > chunks[j].kind })
	var s strings.Builder
	for _, c := range chunks {
		s.WriteString(", ")
		s.WriteString(c.title)
	}
	return s.String()[2:]
}

type ResourceSearchOut struct {
	Menus       []lib.ResourceHeader
	Receipes    []lib.ReceipeHeader
	Ingredients []lib.IngredientHeader
}

func (ct *Controller) searchResource(pattern string, uID us.IdUser) (out ResourceSearchOut, err error) {
	tx, err := ct.db.Begin()
	if err != nil {
		return out, utils.SQLError(err)
	}
	defer tx.Rollback() // this query is readonly, so we can simplify return clauses

	ingredients, err := men.SelectAllIngredients(tx)
	if err != nil {
		return out, utils.SQLError(err)
	}
	receipes, err := men.SelectAllReceipes(tx)
	if err != nil {
		return out, utils.SQLError(err)
	}
	menus, err := men.SelectAllMenus(tx)
	if err != nil {
		return out, utils.SQLError(err)
	}
	receipes.RestrictVisibleBy(uID)
	menus.RestrictVisibleBy(uID)

	// load the menu content so we can search in it
	links1, err := men.SelectMenuIngredientsByIdMenus(tx, menus.IDs()...)
	if err != nil {
		return out, utils.SQLError(err)
	}
	links2, err := men.SelectMenuReceipesByIdMenus(tx, menus.IDs()...)
	if err != nil {
		return out, utils.SQLError(err)
	}
	menuToIngredients, menuToReceipes := links1.ByIdMenu(), links2.ByIdMenu()
	// all the ingredients have been loaded, load the (potential) required receipes..
	otherReceipes, err := men.SelectReceipes(tx, links2.IdReceipes()...)
	if err != nil {
		return out, utils.SQLError(err)
	}
	// .. and merge
	for k, v := range otherReceipes {
		receipes[k] = v
	}

	// we are now ready to search
	switch pattern {
	case ":I", ":R", ":M":
	default:
		pattern = utils.Normalize(pattern)
	}
	for _, ing := range ingredients {
		if pattern == ":I" || strings.Contains(utils.Normalize(ing.Name), pattern) {
			out.Ingredients = append(out.Ingredients, lib.IngredientHeader{
				ResourceHeader: lib.ResourceHeader{
					Title:       ing.Name,
					ID:          int64(ing.Id),
					IsPersonnal: false,
				},
				Kind: ing.Kind,
			})
		}
	}

	menuAndReceipeOwners, err := us.SelectUsers(ct.db, append(receipes.Owners(), menus.Owners()...)...)
	if err != nil {
		return out, utils.SQLError(err)
	}
	for _, receipe := range receipes {
		if pattern == ":R" || strings.Contains(utils.Normalize(receipe.Name), pattern) {
			out.Receipes = append(out.Receipes, lib.ReceipeHeader{
				ResourceHeader: lib.ResourceHeader{
					Title:       receipe.Name,
					ID:          int64(receipe.Id),
					IsPersonnal: receipe.Owner == uID,
					Owner:       menuAndReceipeOwners[receipe.Owner].Pseudo,
				},
				Plat: receipe.Plat,
			})
		}
	}

	for _, menu := range menus {
		// only return favorite ones
		if !menu.IsFavorite {
			continue
		}

		// build the title from the contents (ingredient, receipes)
		ingredientsL, receipesL := menuToIngredients[menu.Id], menuToReceipes[menu.Id]
		var chunks []platTitle
		for _, link := range ingredientsL {
			ing := ingredients[link.IdIngredient]
			chunks = append(chunks, platTitle{title: ing.Name, kind: link.Plat})
		}
		for _, link := range receipesL {
			rec := receipes[link.IdReceipe]
			chunks = append(chunks, platTitle{title: rec.Name, kind: rec.Plat})
		}
		title := sortedTitle(chunks)
		if pattern == ":M" || strings.Contains(utils.Normalize(title), pattern) { // return the menu
			out.Menus = append(out.Menus, lib.ResourceHeader{
				Title:       title,
				ID:          int64(menu.Id),
				IsPersonnal: menu.Owner == uID,
				Owner:       menuAndReceipeOwners[menu.Owner].Pseudo,
			})
		}
	}

	sort.Slice(out.Menus, func(i, j int) bool { return out.Menus[i].Title < out.Menus[j].Title })

	sort.Slice(out.Receipes, func(i, j int) bool { return out.Receipes[i].Title < out.Receipes[j].Title })
	sort.SliceStable(out.Receipes, func(i, j int) bool { return out.Receipes[i].Plat > out.Receipes[j].Plat })

	sort.Slice(out.Ingredients, func(i, j int) bool { return out.Ingredients[i].Title < out.Ingredients[j].Title })
	sort.SliceStable(out.Ingredients, func(i, j int) bool { return out.Ingredients[i].Kind < out.Ingredients[j].Kind })

	return out, nil
}

type optionnalInt struct {
	v     int
	valid bool
}

// MealsLoadDay loads the complete content of the meals
// for the given sejour and day.
func (ct *Controller) MealsLoadDay(c echo.Context) error {
	uID := users.JWTUser(c)
	idSejour, err := utils.QueryParamInt[sej.IdSejour](c, "idSejour")
	if err != nil {
		return err
	}
	day, err := utils.QueryParamInt[int](c, "day")
	if err != nil {
		return err
	}
	out, err := ct.loadMeals(idSejour, optionnalInt{v: day, valid: true}, uID)
	if err != nil {
		return err
	}
	return c.JSON(200, out)
}

// MealsLoadAll loads the complete content of the meals
// for the given sejour, and all days
func (ct *Controller) MealsLoadAll(c echo.Context) error {
	uID := users.JWTUser(c)
	idSejour, err := utils.QueryParamInt[sej.IdSejour](c, "idSejour")
	if err != nil {
		return err
	}
	out, err := ct.loadMeals(idSejour, optionnalInt{}, uID)
	if err != nil {
		return err
	}
	return c.JSON(200, out)
}

type MealExt struct {
	Meal   sej.Meal
	Groups sej.MealGroups
}

type MealsLoadOut struct {
	Menus map[men.IdMenu]lib.MenuExt
	Meals []MealExt
}

// day restrict to one day
func (ct *Controller) loadMeals(idSejour sej.IdSejour, day optionnalInt, uID us.IdUser) (out MealsLoadOut, err error) {
	_, err = ct.checkSejourOwner(idSejour, uID)
	if err != nil {
		return out, err
	}

	allMeals, err := sej.SelectMealsBySejours(ct.db, idSejour)
	if err != nil {
		return out, utils.SQLError(err)
	}
	if day.valid {
		allMeals.RestrictByDay(day.v)
	}

	links, err := sej.SelectMealGroupsByIdMeals(ct.db, allMeals.IDs()...)
	if err != nil {
		return out, utils.SQLError(err)
	}
	mealToGroups := links.ByIdMeal()

	mt, err := lib.LoadMenus(ct.db, allMeals.Menus())
	if err != nil {
		return out, err
	}

	out.Menus, _ = mt.Compile()
	out.Meals = make([]MealExt, 0, len(allMeals))
	for _, meal := range allMeals {
		item := MealExt{
			Meal:   meal,
			Groups: mealToGroups[meal.Id],
		}
		out.Meals = append(out.Meals, item)
	}

	sort.Slice(out.Meals, func(i, j int) bool { return out.Meals[i].Meal.Jour < out.Meals[j].Meal.Jour })

	return out, nil
}

type MealCreateIn struct {
	IdSejour sej.IdSejour
	Day      int
	Horaire  sej.Horaire
}

// MealsCreate adds a [Meal] for the given sejour, day and horaire,
// adding all the groups not affected yet.
func (ct *Controller) MealsCreate(c echo.Context) error {
	uID := users.JWTUser(c)

	var args MealCreateIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.createMeal(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) createMeal(args MealCreateIn, uID us.IdUser) (MealExt, error) {
	_, err := ct.checkSejourOwner(args.IdSejour, uID)
	if err != nil {
		return MealExt{}, err
	}

	tx, err := ct.db.Begin()
	if err != nil {
		return MealExt{}, utils.SQLError(err)
	}
	// create the underlying menu
	menu, err := men.Menu{Owner: uID, Updated: men.Time(time.Now())}.Insert(tx)
	if err != nil {
		_ = tx.Rollback()
		return MealExt{}, utils.SQLError(err)
	}
	meal, err := sej.Meal{
		Sejour:  args.IdSejour,
		Menu:    menu.Id,
		Jour:    args.Day,
		Horaire: args.Horaire,
	}.Insert(tx)
	if err != nil {
		_ = tx.Rollback()
		return MealExt{}, utils.SQLError(err)
	}
	// attribute the groups still non affected for this day/horaire
	meals, err := sej.SelectMealsBySejours(tx, args.IdSejour)
	if err != nil {
		_ = tx.Rollback()
		return MealExt{}, utils.SQLError(err)
	}
	meals.RestrictByDay(args.Day)
	meals.RestrictByHoraire(args.Horaire)

	// fetch the sejourGroups already associated
	sejourGroups, err := sej.SelectGroupsBySejours(tx, args.IdSejour)
	if err != nil {
		_ = tx.Rollback()
		return MealExt{}, utils.SQLError(err)
	}
	alreadyAffected, err := sej.SelectMealGroupsByIdMeals(tx, meals.IDs()...)
	if err != nil {
		_ = tx.Rollback()
		return MealExt{}, utils.SQLError(err)
	}
	all := sej.NewIdGroupSetFrom(sejourGroups.IDs())
	for _, affected := range alreadyAffected.IdGroups() {
		delete(all, affected)
	}
	// now affect all
	var groupsL sej.MealGroups
	for id := range all {
		groupsL = append(groupsL, sej.MealGroup{IdMeal: meal.Id, IdGroup: id})
	}
	err = sej.InsertManyMealGroups(tx, groupsL...)
	if err != nil {
		_ = tx.Rollback()
		return MealExt{}, utils.SQLError(err)
	}

	err = tx.Commit()
	if err != nil {
		return MealExt{}, utils.SQLError(err)
	}

	return MealExt{
		Meal:   meal,
		Groups: groupsL,
	}, nil
}

func (ct *Controller) MealsUpdate(c echo.Context) error {
	uID := users.JWTUser(c)

	var args sej.Meal
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateMeal(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateMeal(in sej.Meal, uID us.IdUser) error {
	_, err := ct.checkSejourOwner(in.Sejour, uID)
	if err != nil {
		return err
	}

	meal, err := sej.SelectMeal(ct.db, in.Id)
	if err != nil {
		return utils.SQLError(err)
	}

	meal.AdditionalPeople = in.AdditionalPeople
	meal.Horaire = in.Horaire
	meal.Jour = in.Jour
	_, err = meal.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

func (ct *Controller) MealsDelete(c echo.Context) error {
	uID := users.JWTUser(c)
	idMeal, err := utils.QueryParamInt[sej.IdMeal](c, "idMeal")
	if err != nil {
		return err
	}
	err = ct.deleteMeal(idMeal, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) deleteMeal(idMeal sej.IdMeal, uID us.IdUser) error {
	meal, err := sej.SelectMeal(ct.db, idMeal)
	if err != nil {
		return utils.SQLError(err)
	}
	_, err = ct.checkSejourOwner(meal.Sejour, uID)
	if err != nil {
		return err
	}

	tx, err := ct.db.Begin()
	if err != nil {
		return utils.SQLError(err)
	}
	err = deleteMeals(tx, []sej.IdMeal{meal.Id})
	if err != nil {
		_ = tx.Rollback()
		return err
	}
	err = tx.Commit()
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

type MoveGroupIn struct {
	Group sej.IdGroup
	From  sej.IdMeal
	To    sej.IdMeal
}

// MealsMoveGroup moves a given group from one meal to another,
// and returns the two meals modified
func (ct *Controller) MealsMoveGroup(c echo.Context) error {
	uID := users.JWTUser(c)

	var args MoveGroupIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.moveGroup(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) moveGroup(args MoveGroupIn, uID us.IdUser) (out [2]sej.MealGroups, _ error) {
	meal1, err := sej.SelectMeal(ct.db, args.From)
	if err != nil {
		return out, utils.SQLError(err)
	}
	_, err = ct.checkSejourOwner(meal1.Sejour, uID)
	if err != nil {
		return out, utils.SQLError(err)
	}
	meal2, err := sej.SelectMeal(ct.db, args.To)
	if err != nil {
		return out, utils.SQLError(err)
	}
	_, err = ct.checkSejourOwner(meal2.Sejour, uID)
	if err != nil {
		return out, utils.SQLError(err)
	}

	links, err := sej.SelectMealGroupsByIdMeals(ct.db, meal1.Id, meal2.Id)
	if err != nil {
		return out, utils.SQLError(err)
	}
	dict := links.ByIdMeal()
	currentFrom, currentTo := sej.NewIdGroupSetFrom(dict[args.From].IdGroups()), sej.NewIdGroupSetFrom(dict[args.To].IdGroups())
	delete(currentFrom, args.Group)
	currentTo.Add(args.Group)
	// build the new links to add
	for g := range currentFrom {
		out[0] = append(out[0], sej.MealGroup{IdMeal: meal1.Id, IdGroup: g})
	}
	for g := range currentTo {
		out[1] = append(out[1], sej.MealGroup{IdMeal: meal2.Id, IdGroup: g})
	}
	// replace the newLinks
	tx, err := ct.db.Begin()
	if err != nil {
		return out, utils.SQLError(err)
	}
	_, err = sej.DeleteMealGroupsByIdMeals(tx, meal1.Id, meal2.Id)
	if err != nil {
		_ = tx.Rollback()
		return out, utils.SQLError(err)
	}
	err = sej.InsertManyMealGroups(tx, append(out[0][:], out[1]...)...)
	if err != nil {
		_ = tx.Rollback()
		return out, utils.SQLError(err)
	}
	err = tx.Commit()
	if err != nil {
		return out, utils.SQLError(err)
	}

	return out, nil
}

type AddReceipeIn struct {
	IdMenu    men.IdMenu
	IdReceipe men.IdReceipe
}

// MealsAddReceipe add the given receipe to the given menu,
// returning the updated [MenuExt]
func (ct *Controller) MealsAddReceipe(c echo.Context) error {
	uID := users.JWTUser(c)

	var args AddReceipeIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.addReceipe(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) addReceipe(args AddReceipeIn, uID us.IdUser) (out lib.MenuExt, _ error) {
	menu, err := men.SelectMenu(ct.db, args.IdMenu)
	if err != nil {
		return out, utils.SQLError(err)
	}

	if menu.Owner != uID {
		return out, errAccessForbidden
	}

	tx, err := ct.db.Begin()
	if err != nil {
		return out, utils.SQLError(err)
	}
	// fetch and delete current links
	links, err := men.DeleteMenuReceipesByIdMenus(tx, menu.Id)
	if err != nil {
		_ = tx.Rollback()
		return out, utils.SQLError(err)
	}
	recs := men.NewIdReceipeSetFrom(links.IdReceipes())
	recs.Add(args.IdReceipe) // add the receipe
	err = men.InsertManyMenuReceipes(tx, recs.ToMenuLinks(menu.Id)...)
	if err != nil {
		_ = tx.Rollback()
		return out, utils.SQLError(err)
	}
	err = tx.Commit()
	if err != nil {
		return out, utils.SQLError(err)
	}

	m, err := lib.LoadMenu(ct.db, menu.Id)
	return m, err
}

type AddIngredientIn struct {
	IdSejour     sej.IdSejour
	IdMenu       men.IdMenu
	IdIngredient men.IdIngredient
}

// MealsAddIngredient add the given Ingredient to the given menu,
// returning the updated [MenuExt]
// The quantity default to the last one used in the sejour, and should be edited right away
func (ct *Controller) MealsAddIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args AddIngredientIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.addIngredient(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

// compute an hint for the quantity
func (ct *Controller) ingredientQuantityHint(idSejour sej.IdSejour, idIngredient men.IdIngredient) (men.QuantityR, error) {
	meals, err := sej.SelectMealsBySejours(ct.db, idSejour)
	if err != nil {
		return men.QuantityR{}, utils.SQLError(err)
	}
	mt, err := lib.LoadMenus(ct.db, meals.Menus())
	if err != nil {
		return men.QuantityR{}, err
	}
	menus, _ := mt.Compile()
	for _, menu := range menus {
		for _, ing := range menu.Ingredients {
			if ing.IdIngredient == idIngredient {
				return ing.Quantity, nil
			}
		}
	}

	return men.QuantityR{Val: 10, For: 10, Unite: men.U_Piece}, nil
}

func (ct *Controller) addIngredient(args AddIngredientIn, uID us.IdUser) (out lib.MenuExt, _ error) {
	menu, err := men.SelectMenu(ct.db, args.IdMenu)
	if err != nil {
		return out, utils.SQLError(err)
	}

	if menu.Owner != uID {
		return out, errAccessForbidden
	}

	quantity, err := ct.ingredientQuantityHint(args.IdSejour, args.IdIngredient)
	if err != nil {
		return out, err
	}

	err = men.InsertMenuIngredient(ct.db, men.MenuIngredient{
		IdMenu:       menu.Id,
		IdIngredient: args.IdIngredient,
		Quantity:     quantity,
		Plat:         men.P_Empty,
	})
	if err != nil {
		return out, utils.SQLError(err)
	}

	m, err := lib.LoadMenu(ct.db, menu.Id)
	return m, err
}

type SetMenuIn struct {
	IdMeal sej.IdMeal
	IdMenu men.IdMenu
}

// MealsSetMenu assign the given [Menu] to the given [Meal].
// The old [Menu] is cleaned up if necessary.
// The new [MenuExt] is returned, and the [Meal.Menu] field should be updated on the client.
func (ct *Controller) MealsSetMenu(c echo.Context) error {
	uID := users.JWTUser(c)

	var args SetMenuIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.setMenu(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) setMenu(args SetMenuIn, uID us.IdUser) (out lib.MenuExt, _ error) {
	meal, err := sej.SelectMeal(ct.db, args.IdMeal)
	if err != nil {
		return out, utils.SQLError(err)
	}
	oldMenu := meal.Menu

	_, err = ct.checkSejourOwner(meal.Sejour, uID)
	if err != nil {
		return out, err
	}

	menu, err := men.SelectMenu(ct.db, args.IdMenu)
	if err != nil {
		return out, utils.SQLError(err)
	}

	// personnal or published
	if menu.Owner != uID && !menu.IsPublished {
		return out, errAccessForbidden
	}

	tx, err := ct.db.Begin()
	if err != nil {
		return out, utils.SQLError(err)
	}

	// attribute the new menu
	meal.Menu = args.IdMenu
	_, err = meal.Update(tx)
	if err != nil {
		_ = tx.Rollback()
		return out, utils.SQLError(err)
	}
	// collect the old one if needed
	err = garbageCollectMenus(tx, []men.IdMenu{oldMenu})
	if err != nil {
		_ = tx.Rollback()
		return out, utils.SQLError(err)
	}

	err = tx.Commit()
	if err != nil {
		return out, utils.SQLError(err)
	}

	m, err := lib.LoadMenu(ct.db, menu.Id)
	return m, err
}

func (ct *Controller) MealsUpdateMenuIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args men.MenuIngredient
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.updateMenuIngredient(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) updateMenuIngredient(args men.MenuIngredient, uID us.IdUser) (out lib.MenuExt, _ error) {
	err := lib.UpdateMenuIngredient(ct.db, args, uID)
	if err != nil {
		return out, err
	}

	return lib.LoadMenu(ct.db, args.IdMenu)
}

type RemoveItemIn struct {
	IdMenu    men.IdMenu
	ID        int64
	IsReceipe bool
}

// MealsRemoveItem removes the given receipe or ingredient
// from the given [Menu], and return the updated [MenuExt]
func (ct *Controller) MealsRemoveItem(c echo.Context) error {
	uID := users.JWTUser(c)

	var args RemoveItemIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.removeItemFromMenu(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) removeItemFromMenu(args RemoveItemIn, uID us.IdUser) (out lib.MenuExt, _ error) {
	menu, err := men.SelectMenu(ct.db, args.IdMenu)
	if err != nil {
		return out, utils.SQLError(err)
	}
	if menu.Owner != uID {
		return out, errAccessForbidden
	}

	if args.IsReceipe {
		_, err = men.DeleteMenuReceipesByIdMenuAndIdReceipe(ct.db, menu.Id, men.IdReceipe(args.ID))
	} else {
		_, err = men.DeleteMenuIngredientsByIdMenuAndIdIngredient(ct.db, args.IdMenu, men.IdIngredient(args.ID))
	}
	if err != nil {
		return out, utils.SQLError(err)
	}

	out, err = lib.LoadMenu(ct.db, menu.Id)
	return out, err
}

type SwapMenusIn struct {
	IdMeal1, IdMeal2 sej.IdMeal
}

func (ct *Controller) MealsSwapMenus(c echo.Context) error {
	uID := users.JWTUser(c)

	var args SwapMenusIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.swapMenus(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) swapMenus(args SwapMenusIn, uID us.IdUser) error {
	meal1, err := sej.SelectMeal(ct.db, args.IdMeal1)
	if err != nil {
		return utils.SQLError(err)
	}
	_, err = ct.checkSejourOwner(meal1.Sejour, uID)
	if err != nil {
		return utils.SQLError(err)
	}
	meal2, err := sej.SelectMeal(ct.db, args.IdMeal2)
	if err != nil {
		return utils.SQLError(err)
	}
	_, err = ct.checkSejourOwner(meal2.Sejour, uID)
	if err != nil {
		return utils.SQLError(err)
	}

	meal1.Menu, meal2.Menu = meal2.Menu, meal1.Menu
	tx, err := ct.db.Begin()
	if err != nil {
		return utils.SQLError(err)
	}
	_, err = meal1.Update(tx)
	if err != nil {
		_ = tx.Rollback()
		return utils.SQLError(err)
	}
	_, err = meal2.Update(tx)
	if err != nil {
		_ = tx.Rollback()
		return utils.SQLError(err)
	}
	err = tx.Commit()
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

type PreviewQuantitiesOut struct {
	NbPeople   int
	Quantities []lib.IngredientQuantity
}

func (ct *Controller) MealsPreviewQuantities(c echo.Context) error {
	idMeal, err := utils.QueryParamInt[sej.IdMeal](c, "idMeal")
	if err != nil {
		return err
	}
	out, err := ct.previewQuantities(idMeal)
	if err != nil {
		return err
	}
	return c.JSON(200, out)
}

func (ct *Controller) previewQuantities(idMeal sej.IdMeal) (out PreviewQuantitiesOut, _ error) {
	meal, err := sej.SelectMeal(ct.db, idMeal)
	if err != nil {
		return out, utils.SQLError(err)
	}
	// resolve the number of people
	links, err := sej.SelectMealGroupsByIdMeals(ct.db, idMeal)
	if err != nil {
		return out, utils.SQLError(err)
	}
	groups, err := sej.SelectGroups(ct.db, links.IdGroups()...)
	if err != nil {
		return out, utils.SQLError(err)
	}
	forNb := ResolveSize(links, groups, meal.AdditionalPeople)

	// resolve the menus
	loader, err := lib.LoadMenus(ct.db, []men.IdMenu{meal.Menu})
	if err != nil {
		return out, err
	}
	mm, rm := loader.Compile()
	menu := mm[meal.Menu]

	out.NbPeople = forNb
	out.Quantities = menu.QuantitiesFor(forNb, rm)

	// sort by kind
	sort.Slice(out.Quantities, func(i, j int) bool { return out.Quantities[i].Ingredient.Name < out.Quantities[j].Ingredient.Name })
	sort.SliceStable(out.Quantities, func(i, j int) bool { return out.Quantities[i].Ingredient.Kind < out.Quantities[j].Ingredient.Kind })

	return out, nil
}

func (ct *Controller) MealsExportCookbook(c echo.Context) error {
	uID := users.JWTUser(c)

	var args ExportCookbookIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	fileBytes, filename, err := ct.exportCookbook(args, uID)
	if err != nil {
		return err
	}

	escapedFilename := url.QueryEscape(strings.ReplaceAll(filename, " ", "_"))
	c.Response().Header().Set(echo.HeaderContentDisposition, fmt.Sprintf(`%s; filename=%s`, "attachment", escapedFilename))
	return c.Blob(200, "application/pdf", fileBytes)
}

// ResolveSize adds the size of the groups in [links] (resolved thanks to [groups]),
// and [additionnalPeople]
func ResolveSize(links sej.MealGroups, groups sej.Groups, additionnalPeople int) int {
	forNb := additionnalPeople
	for _, link := range links {
		gr := groups[link.IdGroup]
		forNb += gr.Size
	}
	return forNb
}
