package order

import (
	"database/sql"
	"errors"
	"sort"

	lib "github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/controllers/sejours"
	"github.com/benoitkugler/atable/controllers/users"
	men "github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

var errAccessForbidden = errors.New("resource access forbidden")

type Controller struct {
	db *sql.DB
}

func NewController(db *sql.DB) *Controller { return &Controller{db: db} }

func (ct *Controller) checkSejourOwner(id sej.IdSejour, uID us.IdUser) (sej.Sejour, error) {
	sejour, err := sej.SelectSejour(ct.db, id)
	if err != nil {
		return sej.Sejour{}, utils.SQLError(err)
	}

	if sejour.Owner != uID {
		return sej.Sejour{}, errAccessForbidden
	}

	return sejour, nil
}

// OrderGetDays returns the offsets containing at least one meal,
// for the given sejour
func (ct *Controller) OrderGetDays(c echo.Context) error {
	uID := users.JWTUser(c)

	id_, err := utils.QueryParamInt64(c, "idSejour")
	if err != nil {
		return err
	}

	out, err := ct.getDays(sej.IdSejour(id_), uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) getDays(id sej.IdSejour, uID us.IdUser) ([]int, error) {
	_, err := ct.checkSejourOwner(id, uID)
	if err != nil {
		return nil, err
	}

	meals, err := sej.SelectMealsBySejours(ct.db, id)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	tmp := make(map[int]bool)
	for _, meal := range meals {
		tmp[meal.Jour] = true
	}
	out := make([]int, 0, len(tmp))
	for offset := range tmp {
		out = append(out, offset)
	}
	sort.Ints(out)
	return out, nil
}

type CompileIngredientsIn struct {
	IdSejour   sej.IdSejour
	DayOffsets []int
}

// OrderCompileIngredients compiles the ingredients required for the given sejour
// and days
func (ct *Controller) OrderCompileIngredients(c echo.Context) error {
	uID := users.JWTUser(c)

	var args CompileIngredientsIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.compileIngredients(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

type CompileIngredientsOut struct {
	Meals       sej.Meals
	Ingredients []IngredientQuantities
}

type IngredientQuantities struct {
	Ingredient men.Ingredient
	Quantities []QuantityMeal
}

type QuantityMeal struct {
	Quantity lib.Quantity
	Origin   sej.IdMeal
}

func (ct *Controller) compileIngredients(args CompileIngredientsIn, uID us.IdUser) (out CompileIngredientsOut, _ error) {
	_, err := ct.checkSejourOwner(args.IdSejour, uID)
	if err != nil {
		return out, err
	}

	groups, err := sej.SelectGroupsBySejours(ct.db, args.IdSejour)
	if err != nil {
		return out, utils.SQLError(err)
	}
	meals, err := sej.SelectMealsBySejours(ct.db, args.IdSejour)
	if err != nil {
		return out, utils.SQLError(err)
	}
	meals.RestrictByDays(args.DayOffsets)

	links, err := sej.SelectMealGroupsByIdMeals(ct.db, meals.IDs()...)
	if err != nil {
		return out, utils.SQLError(err)
	}
	mealToGroups := links.ByIdMeal()

	mt, err := lib.LoadMenus(ct.db, meals.Menus())
	if err != nil {
		return out, err
	}
	menus, receipes := mt.Compile()

	tmp := make(map[men.IdIngredient][]QuantityMeal)
	for _, meal := range meals {
		for_ := sejours.ResolveSize(mealToGroups[meal.Id], groups, meal.AdditionalPeople)
		menu := menus[meal.Menu]
		quantities := menu.QuantitiesFor(for_, mt.Ingredients, receipes)
		// merge to the global map, adding the meal origin
		for _, qu := range quantities {
			l := tmp[qu.Ingredient.Id]
			for _, use := range qu.Quantities {
				l = append(l, QuantityMeal{Quantity: use, Origin: meal.Id})
			}
			tmp[qu.Ingredient.Id] = l
		}
	}

	out.Meals = meals
	out.Ingredients = make([]IngredientQuantities, 0, len(tmp))
	for i, qus := range tmp {
		out.Ingredients = append(out.Ingredients, IngredientQuantities{Ingredient: mt.Ingredients[i], Quantities: qus})
	}
	// sort by categorie
	sort.Slice(out.Ingredients, func(i, j int) bool { return out.Ingredients[i].Ingredient.Kind < out.Ingredients[j].Ingredient.Kind })

	return out, nil
}
