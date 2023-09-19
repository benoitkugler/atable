package library

import (
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/benoitkugler/atable/controllers/users"
	men "github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/sejours"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
	"github.com/lib/pq"
)

var errAccessForbidden = errors.New("resource access forbidden")

type Controller struct {
	db    *sql.DB
	admin us.User
}

func NewController(db *sql.DB, admin us.User) *Controller {
	return &Controller{db: db, admin: admin}
}

// handle commit / rollback
func (ct *Controller) inTx(fn func(tx *sql.Tx) error) error { return utils.InTx(ct.db, fn) }

func (ct *Controller) checkReceipeOwner(idReceipe men.IdReceipe, uID us.IdUser) (men.Receipe, error) {
	receipe, err := men.SelectReceipe(ct.db, idReceipe)
	if err != nil {
		return receipe, utils.SQLError(err)
	}
	if receipe.Owner != uID {
		return receipe, errAccessForbidden
	}
	return receipe, nil
}

func (ct *Controller) checkMenuOwner(idMenu men.IdMenu, uID us.IdUser) (men.Menu, error) {
	return checkMenuOwner(ct.db, idMenu, uID)
}

func checkMenuOwner(db men.DB, idMenu men.IdMenu, uID us.IdUser) (men.Menu, error) {
	menu, err := men.SelectMenu(db, idMenu)
	if err != nil {
		return menu, utils.SQLError(err)
	}
	if menu.Owner != uID {
		return menu, errAccessForbidden
	}
	return menu, nil
}

// LibraryLoadIngredients returns all available ingredients
func (ct *Controller) LibraryLoadIngredients(c echo.Context) error {
	out, err := men.SelectAllIngredients(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}

	return c.JSON(200, out)
}

// LibraryLoadReceipes returns the Receipes available to the user.
func (ct *Controller) LibraryLoadReceipes(c echo.Context) error {
	uID := users.JWTUser(c)

	out, err := men.SelectAllReceipes(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}
	out.RestrictVisibleBy(uID)

	return c.JSON(200, out)
}

func (ct *Controller) LibraryCreateIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args men.Ingredient
	if err := c.Bind(&args); err != nil {
		return err
	}

	args.Owner = uID
	args.Name = utils.UpperFirst(args.Name)
	ing, err := args.Insert(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}

	return c.JSON(200, ing)
}

// LibraryCreateMenu creates a favorite menu for the given user
func (ct *Controller) LibraryCreateMenu(c echo.Context) error {
	uID := users.JWTUser(c)

	out, err := ct.createMenu(uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) createMenu(uID us.IdUser) (out ResourceHeader, _ error) {
	menu, err := men.Menu{Owner: uID, IsFavorite: true, Updated: men.Time(time.Now())}.Insert(ct.db)
	if err != nil {
		return out, utils.SQLError(err)
	}
	return ResourceHeader{
		Title:       "",
		ID:          int64(menu.Id),
		IsPersonnal: true,
	}, nil
}

// LibraryCreateReceipe creates a Receipe for the given user
func (ct *Controller) LibraryCreateReceipe(c echo.Context) error {
	uID := users.JWTUser(c)

	out, err := ct.createReceipe(uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) createReceipe(uID us.IdUser) (out ReceipeHeader, _ error) {
	rec, err := men.Receipe{
		Owner:   uID,
		Name:    fmt.Sprintf("Recette %d", time.Now().UnixMilli()),
		Updated: men.Time(time.Now()),
	}.Insert(ct.db)
	if err != nil {
		return out, utils.SQLError(err)
	}
	return ReceipeHeader{
		ResourceHeader: ResourceHeader{
			Title:       rec.Name,
			ID:          int64(rec.Id),
			IsPersonnal: true,
		},
		Plat: rec.Plat,
	}, nil
}

// LibraryLoadReceipe load the full content of the given receipe
func (ct *Controller) LibraryLoadReceipe(c echo.Context) error {
	// uID := users.JWTUser(c)
	id_, err := utils.QueryParamInt64(c, "idReceipe")
	if err != nil {
		return err
	}

	out, err := ct.loadReceipe(men.IdReceipe(id_))
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) loadReceipe(id men.IdReceipe) (ReceipeExt, error) {
	m, err := loadReceipes(ct.db, []men.IdReceipe{id}, nil)
	if err != nil {
		return ReceipeExt{}, err
	}
	_, ma := m.Compile()
	return ma[id], nil
}

func (ct *Controller) LibraryUpdateReceipe(c echo.Context) error {
	uID := users.JWTUser(c)

	var args men.Receipe
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateReceipe(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateReceipe(args men.Receipe, uID us.IdUser) error {
	receipe, err := ct.checkReceipeOwner(args.Id, uID)
	if err != nil {
		return err
	}

	receipe.Name = args.Name
	receipe.Description = args.Description
	receipe.Plat = args.Plat
	receipe.IsPublished = args.IsPublished
	receipe.Updated = men.Time(time.Now())
	_, err = receipe.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

// LibraryDeleteReceipe delete the receipe, unless it is used in menu
func (ct *Controller) LibraryDeleteReceipe(c echo.Context) error {
	uID := users.JWTUser(c)

	id, err := utils.QueryParamInt64(c, "idReceipe")
	if err != nil {
		return err
	}

	err = ct.deleteReceipe(men.IdReceipe(id), uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) deleteReceipe(id men.IdReceipe, uID us.IdUser) error {
	_, err := ct.checkReceipeOwner(id, uID)
	if err != nil {
		return err
	}

	links, err := men.SelectMenuReceipesByIdReceipes(ct.db, id)
	if err != nil {
		return err
	}

	nbMenus := len(links)
	if nbMenus != 0 {
		return fmt.Errorf("La recette est utilisé dans %d menus.", nbMenus)
	}

	// we can safely delete the receipe
	_, err = men.DeleteReceipeById(ct.db, id)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

type AddReceipeIngredientIn struct {
	men.IdReceipe
	men.IdIngredient
	InitialFor int // 0 to let the server decide
}

func (ct *Controller) LibraryAddReceipeIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args AddReceipeIngredientIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.addReceipeIngredient(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) addReceipeIngredient(args AddReceipeIngredientIn, uID us.IdUser) (ReceipeIngredientExt, error) {
	receipe, err := ct.checkReceipeOwner(args.IdReceipe, uID)
	if err != nil {
		return ReceipeIngredientExt{}, err
	}

	ing, err := men.SelectIngredient(ct.db, args.IdIngredient)
	if err != nil {
		return ReceipeIngredientExt{}, utils.SQLError(err)
	}
	for_ := args.InitialFor
	if for_ == 0 {
		for_ = 10
	}
	quantity := men.QuantityR{Val: 10, Unite: men.U_Piece, For: for_}
	link := men.ReceipeIngredient{
		IdReceipe:    args.IdReceipe,
		IdIngredient: args.IdIngredient,
		Quantity:     quantity,
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		err := men.InsertReceipeIngredient(tx, link)
		if err != nil {
			return utils.SQLError(err)
		}
		receipe.Updated = men.Time(time.Now())
		_, err = receipe.Update(tx)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return ReceipeIngredientExt{Ingredient: ing, Quantity: quantity}, err
}

func (ct *Controller) LibraryUpdateReceipeIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args men.ReceipeIngredient
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateReceipeIngredient(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateReceipeIngredient(link men.ReceipeIngredient, uID us.IdUser) error {
	receipe, err := ct.checkReceipeOwner(link.IdReceipe, uID)
	if err != nil {
		return err
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		_, err = men.DeleteReceipeIngredientsByIdReceipeAndIdIngredient(tx, link.IdReceipe, link.IdIngredient)
		if err != nil {
			return utils.SQLError(err)
		}
		err = men.InsertReceipeIngredient(tx, link)
		if err != nil {
			return utils.SQLError(err)
		}
		receipe.Updated = men.Time(time.Now())
		_, err = receipe.Update(tx)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return err
}

func (ct *Controller) LibraryDeleteReceipeIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	idR_, err := utils.QueryParamInt64(c, "idReceipe")
	if err != nil {
		return err
	}
	idG_, err := utils.QueryParamInt64(c, "idIngredient")
	if err != nil {
		return err
	}

	err = ct.deleteReceipeIngredient(men.IdReceipe(idR_), men.IdIngredient(idG_), uID)
	if err != nil {
		return err
	}
	return c.NoContent(200)
}

func (ct *Controller) deleteReceipeIngredient(idR men.IdReceipe, idG men.IdIngredient, uID us.IdUser) error {
	receipe, err := ct.checkReceipeOwner(idR, uID)
	if err != nil {
		return err
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		_, err = men.DeleteReceipeIngredientsByIdReceipeAndIdIngredient(tx, idR, idG)
		if err != nil {
			return utils.SQLError(err)
		}
		receipe.Updated = men.Time(time.Now())
		_, err = receipe.Update(tx)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return err
}

// LibraryLoadMenu load the full content of the given Menu
func (ct *Controller) LibraryLoadMenu(c echo.Context) error {
	// uID := users.JWTUser(c)
	id_, err := utils.QueryParamInt64(c, "idMenu")
	if err != nil {
		return err
	}

	out, err := LoadMenu(ct.db, men.IdMenu(id_))
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) LibraryUpdateMenu(c echo.Context) error {
	uID := users.JWTUser(c)

	var args men.Menu
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateMenu(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateMenu(args men.Menu, uID us.IdUser) error {
	menu, err := ct.checkMenuOwner(args.Id, uID)
	if err != nil {
		return err
	}

	menu.IsPublished = args.IsPublished
	menu.IsFavorite = args.IsFavorite
	menu.Updated = men.Time(time.Now())
	_, err = menu.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

// LibraryDeleteMenu delete the menu, unless it is used in meals
func (ct *Controller) LibraryDeleteMenu(c echo.Context) error {
	uID := users.JWTUser(c)

	id, err := utils.QueryParamInt64(c, "idMenu")
	if err != nil {
		return err
	}

	err = ct.deleteMenu(men.IdMenu(id), uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) deleteMenu(id men.IdMenu, uID us.IdUser) error {
	_, err := ct.checkMenuOwner(id, uID)
	if err != nil {
		return err
	}

	links, err := sejours.SelectMealsByMenus(ct.db, id)
	if err != nil {
		return err
	}

	nbMeals := len(links)
	if nbMeals != 0 {
		return fmt.Errorf("Le menu est utilisé dans %d repas.", nbMeals)
	}

	// we can safely delete the menu
	_, err = men.DeleteMenuById(ct.db, id)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

type AddMenuIngredientIn struct {
	men.IdMenu
	men.IdIngredient
}

func (ct *Controller) LibraryAddMenuIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args AddMenuIngredientIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.addMenuIngredient(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) addMenuIngredient(args AddMenuIngredientIn, uID us.IdUser) (MenuIngredientExt, error) {
	menu, err := ct.checkMenuOwner(args.IdMenu, uID)
	if err != nil {
		return MenuIngredientExt{}, err
	}

	ing, err := men.SelectIngredient(ct.db, args.IdIngredient)
	if err != nil {
		return MenuIngredientExt{}, utils.SQLError(err)
	}
	quantity := men.QuantityR{Val: 10, Unite: men.U_Piece, For: 10}
	link := men.MenuIngredient{
		IdMenu:       args.IdMenu,
		IdIngredient: args.IdIngredient,
		Quantity:     quantity,
		Plat:         men.P_Empty,
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		err = men.InsertMenuIngredient(tx, link)
		if err != nil {
			return utils.SQLError(err)
		}
		menu.Updated = men.Time(time.Now())
		_, err = menu.Update(tx)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return MenuIngredientExt{Ingredient: ing, MenuIngredient: link}, err
}

type AddMenuReceipeIn struct {
	men.IdMenu
	men.IdReceipe
}

func (ct *Controller) LibraryAddMenuReceipe(c echo.Context) error {
	uID := users.JWTUser(c)

	var args AddMenuReceipeIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.addMenuReceipe(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) addMenuReceipe(args AddMenuReceipeIn, uID us.IdUser) (men.Receipe, error) {
	menu, err := ct.checkMenuOwner(args.IdMenu, uID)
	if err != nil {
		return men.Receipe{}, err
	}

	rec, err := men.SelectReceipe(ct.db, args.IdReceipe)
	if err != nil {
		return men.Receipe{}, utils.SQLError(err)
	}

	link := men.MenuReceipe{
		IdMenu:    args.IdMenu,
		IdReceipe: args.IdReceipe,
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		err = men.InsertMenuReceipe(tx, link)
		if err != nil {
			return utils.SQLError(err)
		}
		menu.Updated = men.Time(time.Now())
		_, err = menu.Update(tx)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return rec, err
}

func (ct *Controller) LibraryUpdateMenuIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args men.MenuIngredient
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateMenuIngredient(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateMenuIngredient(link men.MenuIngredient, uID us.IdUser) error {
	return UpdateMenuIngredient(ct.db, link, uID)
}

func UpdateMenuIngredient(db *sql.DB, link men.MenuIngredient, uID us.IdUser) error {
	menu, err := checkMenuOwner(db, link.IdMenu, uID)
	if err != nil {
		return err
	}

	err = utils.InTx(db, func(tx *sql.Tx) error {
		_, err = men.DeleteMenuIngredientsByIdMenuAndIdIngredient(tx, link.IdMenu, link.IdIngredient)
		if err != nil {
			return utils.SQLError(err)
		}
		err = men.InsertMenuIngredient(tx, link)
		if err != nil {
			return utils.SQLError(err)
		}
		menu.Updated = men.Time(time.Now())
		_, err = menu.Update(tx)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return err
}

func (ct *Controller) LibraryDeleteMenuIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	idR_, err := utils.QueryParamInt64(c, "idMenu")
	if err != nil {
		return err
	}
	idG_, err := utils.QueryParamInt64(c, "idIngredient")
	if err != nil {
		return err
	}

	err = ct.deleteMenuIngredient(men.IdMenu(idR_), men.IdIngredient(idG_), uID)
	if err != nil {
		return err
	}
	return c.NoContent(200)
}

func (ct *Controller) deleteMenuIngredient(idR men.IdMenu, idG men.IdIngredient, uID us.IdUser) error {
	menu, err := ct.checkMenuOwner(idR, uID)
	if err != nil {
		return err
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		_, err = men.DeleteMenuIngredientsByIdMenuAndIdIngredient(tx, idR, idG)
		if err != nil {
			return utils.SQLError(err)
		}
		menu.Updated = men.Time(time.Now())
		_, err = menu.Update(tx)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return err
}

func (ct *Controller) LibraryDeleteMenuReceipe(c echo.Context) error {
	uID := users.JWTUser(c)

	idR_, err := utils.QueryParamInt64(c, "idMenu")
	if err != nil {
		return err
	}
	idG_, err := utils.QueryParamInt64(c, "idReceipe")
	if err != nil {
		return err
	}

	err = ct.deleteMenuReceipe(men.IdMenu(idR_), men.IdReceipe(idG_), uID)
	if err != nil {
		return err
	}
	return c.NoContent(200)
}

func (ct *Controller) deleteMenuReceipe(idR men.IdMenu, idG men.IdReceipe, uID us.IdUser) error {
	menu, err := ct.checkMenuOwner(idR, uID)
	if err != nil {
		return err
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		_, err = men.DeleteMenuReceipesByIdMenuAndIdReceipe(tx, idR, idG)
		if err != nil {
			return utils.SQLError(err)
		}
		menu.Updated = men.Time(time.Now())
		_, err = menu.Update(tx)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return err
}

type ResourceHeader struct {
	Title       string
	ID          int64
	IsPersonnal bool // if false, it is owned by an other user
}

type ReceipeHeader struct {
	ResourceHeader
	Plat men.PlatKind
}

type IngredientHeader struct {
	ResourceHeader
	Kind men.IngredientKind
}

type MenuIngredientExt struct {
	men.MenuIngredient
	Ingredient men.Ingredient
}

type ReceipeIngredientExt struct {
	men.Ingredient
	Quantity men.QuantityR
}

type ReceipeExt struct {
	Receipe     men.Receipe
	Ingredients []ReceipeIngredientExt
}

type MenuExt struct {
	Menu        men.Menu
	Ingredients []MenuIngredientExt
	Receipes    []men.Receipe
}

// resolve the receipe, and return the `additionalIngredients`
// the Menu fields of the returned value are empty
func loadReceipes(db men.DB, ids []men.IdReceipe, additionalIngredients []men.IdIngredient) (MenuTables, error) {
	receipes, err := men.SelectReceipes(db, ids...)
	if err != nil {
		return MenuTables{}, utils.SQLError(err)
	}
	links, err := men.SelectReceipeIngredientsByIdReceipes(db, receipes.IDs()...)
	if err != nil {
		return MenuTables{}, utils.SQLError(err)
	}

	// load ingredients used in receipes, as well as given
	ingredients, err := men.SelectIngredients(db, append(links.IdIngredients(), additionalIngredients...)...)
	if err != nil {
		return MenuTables{}, utils.SQLError(err)
	}

	return MenuTables{
		Ingredients:        ingredients,
		Receipes:           receipes,
		ReceipeIngredients: links,
	}, nil
}

// LoadMenus resolves the receipes and ingredients for
// the given menus
func LoadMenus(db men.DB, ids []men.IdMenu) (MenuTables, error) {
	menus, err := men.SelectMenus(db, ids...)
	if err != nil {
		return MenuTables{}, utils.SQLError(err)
	}

	// load the menu contents
	links1, err := men.SelectMenuIngredientsByIdMenus(db, menus.IDs()...)
	if err != nil {
		return MenuTables{}, utils.SQLError(err)
	}
	links2, err := men.SelectMenuReceipesByIdMenus(db, menus.IDs()...)
	if err != nil {
		return MenuTables{}, utils.SQLError(err)
	}

	mt, err := loadReceipes(db, links2.IdReceipes(), links1.IdIngredients())
	if err != nil {
		return MenuTables{}, err
	}

	mt.Menus = menus
	mt.MenuIngredients = links1
	mt.MenuReceipes = links2

	return mt, nil
}

// LoadMenu is a convenience helper, calling [LoadMenus] with only one menu.
func LoadMenu(db men.DB, id men.IdMenu) (MenuExt, error) {
	m, err := LoadMenus(db, []men.IdMenu{id})
	ma, _ := m.Compile()
	return ma[id], err
}

type MenuTables struct {
	Ingredients        men.Ingredients
	Receipes           men.Receipes
	ReceipeIngredients men.ReceipeIngredients
	Menus              men.Menus
	MenuReceipes       men.MenuReceipes
	MenuIngredients    men.MenuIngredients
}

// Compile resolve the link tables
func (mt MenuTables) Compile() (map[men.IdMenu]MenuExt, map[men.IdReceipe]ReceipeExt) {
	// build the receipes
	receipeToIngredients := mt.ReceipeIngredients.ByIdReceipe()
	receipeMap := make(map[men.IdReceipe]ReceipeExt)
	for _, receipe := range mt.Receipes {
		ings := receipeToIngredients[receipe.Id]
		item := ReceipeExt{
			Receipe:     receipe,
			Ingredients: make([]ReceipeIngredientExt, len(ings)),
		}
		for i, link := range ings {
			ing := mt.Ingredients[link.IdIngredient]
			item.Ingredients[i] = ReceipeIngredientExt{
				Ingredient: ing,
				Quantity:   link.Quantity,
			}
		}
		receipeMap[receipe.Id] = item
	}

	// build the menus
	menuToIngredients, menuToReceipes := mt.MenuIngredients.ByIdMenu(), mt.MenuReceipes.ByIdMenu()
	menusMap := make(map[men.IdMenu]MenuExt, len(mt.Menus))
	for _, menu := range mt.Menus {
		ings, recs := menuToIngredients[menu.Id], menuToReceipes[menu.Id]
		mIngredients := make([]MenuIngredientExt, len(ings))
		for i, link := range ings {
			mIngredients[i] = MenuIngredientExt{
				MenuIngredient: link,
				Ingredient:     mt.Ingredients[link.IdIngredient],
			}
		}

		mReceipes := make([]men.Receipe, len(recs))
		for i, link := range recs {
			mReceipes[i] = receipeMap[link.IdReceipe].Receipe
		}
		menusMap[menu.Id] = MenuExt{menu, mIngredients, mReceipes}
	}
	return menusMap, receipeMap
}

type Quantity struct {
	Unite men.Unite
	Val   float64
}

// normalize applies the trivial conversions
func (qu Quantity) normalize() Quantity {
	if qu.Unite == men.U_G {
		return Quantity{Unite: men.U_Kg, Val: qu.Val / 1000}
	} else if qu.Unite == men.U_CL {
		return Quantity{Unite: men.U_L, Val: qu.Val / 100}
	}
	return qu
}

type IngredientQuantity struct {
	Ingredient men.Ingredient
	Quantities []Quantity
}

func (me MenuExt) QuantitiesFor(nbPeople int, ingredients men.Ingredients, receipes map[men.IdReceipe]ReceipeExt) []IngredientQuantity {
	quantities := make(map[men.IdIngredient][]Quantity)
	for _, ing := range me.Ingredients {
		quantities[ing.IdIngredient] = append(quantities[ing.IdIngredient], Quantity{
			Unite: ing.Quantity.Unite,
			Val:   ing.Quantity.ResolveFor(nbPeople),
		})
	}
	for _, rec := range me.Receipes {
		rec := receipes[rec.Id]
		for _, ing := range rec.Ingredients {
			quantities[ing.Id] = append(quantities[ing.Id], Quantity{
				Unite: ing.Quantity.Unite,
				Val:   ing.Quantity.ResolveFor(nbPeople),
			})
		}
	}

	out := make([]IngredientQuantity, 0, len(quantities))
	for idIngredient, l := range quantities {
		byQuantity := map[men.Unite]float64{}
		for _, use := range l {
			use = use.normalize()
			byQuantity[use.Unite] = byQuantity[use.Unite] + use.Val
		}
		var uniqueQuantities []Quantity
		for u, v := range byQuantity {
			uniqueQuantities = append(uniqueQuantities, Quantity{u, v})
		}
		out = append(out, IngredientQuantity{ingredients[idIngredient], uniqueQuantities})
	}
	return out
}

// Ingredients API

func (ct *Controller) LibraryUpdateIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args men.Ingredient
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateIngredient(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateIngredient(args men.Ingredient, userID us.IdUser) error {
	ingredient, err := men.SelectIngredient(ct.db, args.Id)
	if err != nil {
		return utils.SQLError(err)
	}
	// check the owner
	if ingredient.Owner != userID {
		return errAccessForbidden
	}
	ingredient.Kind = args.Kind
	ingredient.Name = args.Name
	_, err = ingredient.Update(ct.db)
	if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" /*unique_violation*/ {
		return fmt.Errorf("Le nom %s est déjà présent.", args.Name)
	}
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

func (ct *Controller) LibraryDeleteIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	idI_, err := utils.QueryParamInt64(c, "idIngredient")
	if err != nil {
		return err
	}

	out, err := ct.deleteIngredient(men.IdIngredient(idI_), uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

type DeleteIngredientOut struct {
	Deleted      bool // true if the ingredient has properly been deleted
	UsesReceipes []men.IdReceipe
	UsesMenus    []men.IdMenu
}

func (ct *Controller) deleteIngredient(id men.IdIngredient, userID us.IdUser) (DeleteIngredientOut, error) {
	ingredient, err := men.SelectIngredient(ct.db, id)
	if err != nil {
		return DeleteIngredientOut{}, utils.SQLError(err)
	}
	// check the owner
	if ingredient.Owner != userID {
		return DeleteIngredientOut{}, errAccessForbidden
	}

	// check the ingredient is not used
	links1, err := men.SelectReceipeIngredientsByIdIngredients(ct.db, id)
	if err != nil {
		return DeleteIngredientOut{}, utils.SQLError(err)
	}
	links2, err := men.SelectMenuIngredientsByIdIngredients(ct.db, id)
	if err != nil {
		return DeleteIngredientOut{}, utils.SQLError(err)
	}

	out := DeleteIngredientOut{
		UsesReceipes: links1.IdReceipes(),
		UsesMenus:    links2.IdMenus(),
	}
	if len(out.UsesReceipes)+len(out.UsesMenus) == 0 {
		_, err = men.DeleteIngredientById(ct.db, id)
		if err != nil {
			return DeleteIngredientOut{}, utils.SQLError(err)
		}
		out.Deleted = true
	}

	return out, nil
}
