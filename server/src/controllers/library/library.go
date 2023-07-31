package library

import (
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/benoitkugler/atable/controllers/users"
	men "github.com/benoitkugler/atable/sql/menus"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
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
func (ct *Controller) inTx(fn func(tx *sql.Tx) error) error {
	tx, err := ct.db.Begin()
	if err != nil {
		return utils.SQLError(err)
	}
	err = fn(tx)
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
	menu, err := men.SelectMenu(ct.db, idMenu)
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

	out, err := men.SelectReceipesByOwners(ct.db, uID, ct.admin.Id)
	if err != nil {
		return utils.SQLError(err)
	}

	return c.JSON(200, out)
}

func (ct *Controller) LibraryCreateIngredient(c echo.Context) error {
	var args men.Ingredient
	if err := c.Bind(&args); err != nil {
		return err
	}

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
	menu, err := men.Menu{Owner: uID, IsFavorite: true}.Insert(ct.db)
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
	rec, err := men.Receipe{Owner: uID, Name: fmt.Sprintf("Recette %d", time.Now().UnixMilli())}.Insert(ct.db)
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
	m, _, err := loadReceipes(ct.db, []men.IdReceipe{id}, nil)
	if err != nil {
		return ReceipeExt{}, err
	}
	return m[id], nil
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
	_, err = receipe.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

type AddReceipeIngredientIn struct {
	men.IdReceipe
	men.IdIngredient
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
	_, err := ct.checkReceipeOwner(args.IdReceipe, uID)
	if err != nil {
		return ReceipeIngredientExt{}, err
	}

	ing, err := men.SelectIngredient(ct.db, args.IdIngredient)
	if err != nil {
		return ReceipeIngredientExt{}, utils.SQLError(err)
	}
	quantity := men.QuantityR{Val: 1, Unite: men.U_Piece, For: 10}
	link := men.ReceipeItem{
		IdReceipe:    args.IdReceipe,
		IdIngredient: args.IdIngredient,
		Quantity:     quantity,
	}

	err = ct.inTx(func(tx *sql.Tx) error { return men.InsertManyReceipeItems(tx, link) })

	return ReceipeIngredientExt{Ingredient: ing, Quantity: quantity}, err
}

func (ct *Controller) LibraryUpdateReceipeIngredient(c echo.Context) error {
	uID := users.JWTUser(c)

	var args men.ReceipeItem
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateReceipeIngredient(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateReceipeIngredient(link men.ReceipeItem, uID us.IdUser) error {
	_, err := ct.checkReceipeOwner(link.IdReceipe, uID)
	if err != nil {
		return err
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		_, err = men.DeleteReceipeItemsByIdReceipeAndIdIngredient(tx, link.IdReceipe, link.IdIngredient)
		if err != nil {
			return utils.SQLError(err)
		}
		err = men.InsertManyReceipeItems(tx, link)
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
	_, err := ct.checkReceipeOwner(idR, uID)
	if err != nil {
		return err
	}

	_, err = men.DeleteReceipeItemsByIdReceipeAndIdIngredient(ct.db, idR, idG)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
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
	_, err := ct.checkMenuOwner(args.IdMenu, uID)
	if err != nil {
		return MenuIngredientExt{}, err
	}

	ing, err := men.SelectIngredient(ct.db, args.IdIngredient)
	if err != nil {
		return MenuIngredientExt{}, utils.SQLError(err)
	}
	quantity := men.QuantityR{Val: 1, Unite: men.U_Piece, For: 10}
	link := men.MenuIngredient{
		IdMenu:       args.IdMenu,
		IdIngredient: args.IdIngredient,
		Quantity:     quantity,
		Plat:         men.P_Empty,
	}

	err = ct.inTx(func(tx *sql.Tx) error { return men.InsertManyMenuIngredients(tx, link) })

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
	_, err := ct.checkMenuOwner(args.IdMenu, uID)
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

	err = ct.inTx(func(tx *sql.Tx) error { return men.InsertManyMenuReceipes(tx, link) })

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
	_, err := ct.checkMenuOwner(link.IdMenu, uID)
	if err != nil {
		return err
	}

	err = ct.inTx(func(tx *sql.Tx) error {
		_, err = men.DeleteMenuIngredientsByIdMenuAndIdIngredient(tx, link.IdMenu, link.IdIngredient)
		if err != nil {
			return utils.SQLError(err)
		}
		err = men.InsertManyMenuIngredients(tx, link)
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
	_, err := ct.checkMenuOwner(idR, uID)
	if err != nil {
		return err
	}

	_, err = men.DeleteMenuIngredientsByIdMenuAndIdIngredient(ct.db, idR, idG)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
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
	_, err := ct.checkMenuOwner(idR, uID)
	if err != nil {
		return err
	}

	_, err = men.DeleteMenuReceipesByIdMenuAndIdReceipe(ct.db, idR, idG)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
}

type ResourceHeader struct {
	Title       string
	ID          int64
	IsPersonnal bool // if false, it is owned by the admin account
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
	men.Menu
	Ingredients []MenuIngredientExt
	Receipes    []men.Receipe
}

// resolve the receipe, and return the `additionalIngredients`
func loadReceipes(db men.DB, ids []men.IdReceipe, additionalIngredients []men.IdIngredient) (map[men.IdReceipe]ReceipeExt, men.Ingredients, error) {
	receipes, err := men.SelectReceipes(db, ids...)
	if err != nil {
		return nil, nil, utils.SQLError(err)
	}
	links, err := men.SelectReceipeItemsByIdReceipes(db, receipes.IDs()...)
	if err != nil {
		return nil, nil, utils.SQLError(err)
	}

	// load ingredients used in receipes, as well as given
	ingredients, err := men.SelectIngredients(db, append(links.IdIngredients(), additionalIngredients...)...)
	if err != nil {
		return nil, nil, utils.SQLError(err)
	}

	receipeToIngredients := links.ByIdReceipe()

	// build receipes only once
	receipeMap := make(map[men.IdReceipe]ReceipeExt)
	for _, receipe := range receipes {
		ings := receipeToIngredients[receipe.Id]
		item := ReceipeExt{
			Receipe:     receipe,
			Ingredients: make([]ReceipeIngredientExt, len(ings)),
		}
		for i, link := range ings {
			ing := ingredients[link.IdIngredient]
			item.Ingredients[i] = ReceipeIngredientExt{
				Ingredient: ing,
				Quantity:   link.Quantity,
			}
		}
		receipeMap[receipe.Id] = item
	}

	return receipeMap, ingredients, nil
}

// LoadMenus resolves the receipes and ingredients for
// the given menus.
func LoadMenus(db men.DB, ids []men.IdMenu) (map[men.IdMenu]MenuExt, error) {
	menus, err := men.SelectMenus(db, ids...)
	if err != nil {
		return nil, utils.SQLError(err)
	}

	// load the menu contents
	links1, err := men.SelectMenuIngredientsByIdMenus(db, menus.IDs()...)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	links2, err := men.SelectMenuReceipesByIdMenus(db, menus.IDs()...)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	menuToIngredients, menuToReceipes := links1.ByIdMenu(), links2.ByIdMenu()

	receipeMap, ingredients, err := loadReceipes(db, links2.IdReceipes(), links1.IdIngredients())
	if err != nil {
		return nil, err
	}

	// build the menus
	out := make(map[men.IdMenu]MenuExt, len(menus))
	for _, menu := range menus {
		ings, recs := menuToIngredients[menu.Id], menuToReceipes[menu.Id]
		mIngredients := make([]MenuIngredientExt, len(ings))
		for i, link := range ings {
			mIngredients[i] = MenuIngredientExt{
				MenuIngredient: link,
				Ingredient:     ingredients[link.IdIngredient],
			}
		}

		mReceipes := make([]men.Receipe, len(recs))
		for i, link := range recs {
			mReceipes[i] = receipeMap[link.IdReceipe].Receipe
		}
		out[menu.Id] = MenuExt{menu, mIngredients, mReceipes}
	}

	return out, nil
}

// LoadMenu is a convenience helper, calling [LoadMenus] with only one menu.
func LoadMenu(db men.DB, id men.IdMenu) (MenuExt, error) {
	m, err := LoadMenus(db, []men.IdMenu{id})
	return m[id], err
}
