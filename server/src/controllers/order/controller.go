package order

import (
	"database/sql"
	"errors"
	"fmt"
	"net/url"
	"sort"
	"strings"

	lib "github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/controllers/sejours"
	"github.com/benoitkugler/atable/controllers/users"
	men "github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/orders"
	sej "github.com/benoitkugler/atable/sql/sejours"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

type uID = us.IdUser

var errAccessForbidden = errors.New("resource access forbidden")

type Controller struct {
	db *sql.DB
}

func NewController(db *sql.DB) *Controller { return &Controller{db: db} }

func (ct *Controller) inTx(fn func(tx *sql.Tx) error) error { return utils.InTx(ct.db, fn) }

func (ct *Controller) checkSejourOwner(id sej.IdSejour, uID uID) (sej.Sejour, error) {
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

	id, err := utils.QueryParamInt[sej.IdSejour](c, "idSejour")
	if err != nil {
		return err
	}

	out, err := ct.getDays(id, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) getDays(id sej.IdSejour, uID uID) ([]int, error) {
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

func (iq IngredientQuantities) total() []lib.Quantity {
	byQuantite := map[men.Unite]float64{}
	for _, qu := range iq.Quantities {
		byQuantite[qu.Quantity.Unite] += qu.Quantity.Val
	}
	out := make([]lib.Quantity, 0, len(byQuantite))
	for unite, val := range byQuantite {
		out = append(out, lib.Quantity{Unite: unite, Val: val})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Unite < out[j].Unite })
	return out
}

type QuantityMeal struct {
	Quantity lib.Quantity
	Origin   sej.IdMeal
}

func (ct *Controller) compileIngredients(args CompileIngredientsIn, uID uID) (out CompileIngredientsOut, _ error) {
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
		quantities := menu.QuantitiesFor(for_, receipes)
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
	for id, qus := range tmp {
		out.Ingredients = append(out.Ingredients, IngredientQuantities{Ingredient: mt.Ingredients[id], Quantities: qus})
	}
	// sort by categorie
	sort.Slice(out.Ingredients, func(i, j int) bool { return out.Ingredients[i].Ingredient.Kind < out.Ingredients[j].Ingredient.Kind })

	return out, nil
}

type ExportExcelIn struct {
	IdSejour sej.IdSejour
	Data     CompileIngredientsOut
	Mapping  IngredientMapping
}

func (ct *Controller) OrderExportExcel(c echo.Context) error {
	uID := users.JWTUser(c)

	var args ExportExcelIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	fileBytes, filename, err := ct.exportExcel(args, uID)
	if err != nil {
		return err
	}

	escapedFilename := url.QueryEscape(strings.ReplaceAll(filename, " ", "_"))
	c.Response().Header().Set(echo.HeaderContentDisposition, fmt.Sprintf(`%s; filename=%s`, "attachment", escapedFilename))
	return c.Blob(200, "application/vnd.ms-excel", fileBytes)
}

func (ct *Controller) exportExcel(args ExportExcelIn, uID uID) ([]byte, string, error) {
	sejour, err := ct.checkSejourOwner(args.IdSejour, uID)
	if err != nil {
		return nil, "", err
	}

	ee := exportExcel{
		CompileIngredientsOut: args.Data,
		sejour:                sejour,
	}

	// default to ingredient kind
	if len(args.Mapping) == 0 {
		ee.suppliers, ee.mapping = ingredientKindMapping(args.Data.Ingredients)
	} else {
		// load the suppliers
		suppliers, err := orders.SelectAllSuppliers(ct.db)
		if err != nil {
			return nil, "", utils.SQLError(err)
		}
		ee.suppliers, ee.mapping = suppliers, args.Mapping
	}

	buf, err := ee.ToExcel()
	if err != nil {
		return nil, "", err
	}

	filename := fmt.Sprintf("Ingrédients %s.xlsx", sejour.Name)

	return buf.Bytes(), filename, nil
}
