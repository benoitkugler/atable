// Package sejours implements the routes
// required to define and update the ingredients,
// receipes and meals of one (or many) camps.
package sejours

import (
	"database/sql"
	"errors"
	"fmt"
	"os"
	"sort"
	"time"

	"github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/controllers/users"
	"github.com/benoitkugler/atable/pass"
	men "github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/benoitkugler/textprocessing/fontconfig"
	"github.com/benoitkugler/textprocessing/pango/fcfonts"
	"github.com/benoitkugler/webrender/text"

	"github.com/labstack/echo/v4"
)

var errAccessForbidden = errors.New("resource access forbidden")

type Controller struct {
	db    *sql.DB
	host  string
	admin us.User
	key   pass.Encrypter

	// used for pdf creation
	fc text.FontConfiguration
}

func NewController(db *sql.DB, host string, admin us.User, key pass.Encrypter) *Controller {
	return &Controller{db: db, host: host, admin: admin, key: key}
}

// LoadFontconfig setup the fonts used by goweasyprint,
// and must be called once at startup.
func (ct *Controller) LoadFontconfig() error {
	const scanPath = "fontconfig.bin"

	if _, err := os.Stat(scanPath); err != nil {
		fmt.Println("Scaning fonts...")
		_, err = fontconfig.ScanAndCache(scanPath)
		if err != nil {
			return err
		}
		fmt.Println("Done.")
	}

	fs, err := fontconfig.LoadFontsetFile(scanPath)
	if err != nil {
		return err
	}

	ct.fc = text.NewFontConfigurationPango(fcfonts.NewFontMap(fontconfig.Standard.Copy(), fs))

	return nil
}

// SejoursGet return the [Sejour]s owned by the user
func (ct *Controller) SejoursGet(c echo.Context) error {
	uID := users.JWTUser(c)

	out, err := ct.getSejours(uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

type SejourExt struct {
	Sejour sej.Sejour
	Groups []sej.Group

	// URL for a JSON file, to use in the client mobile app
	ExportClientURL string

	Label string // name and year
}

func (ct *Controller) newSejourExt(sejour sej.Sejour, groups sej.Groups) SejourExt {
	var groupList []sej.Group
	for _, gr := range groups {
		groupList = append(groupList, gr)
	}
	sort.Slice(groupList, func(i, j int) bool { return groupList[i].Id < groupList[j].Id })

	cryptedID := ct.key.EncryptID(int64(sejour.Id))
	clientURL := utils.BuildUrl(ct.host, ClientEnpoint,
		map[string]string{
			clientQueryParam:       string(cryptedID),
			clientQueryParamSejour: sejour.Label(),
		})

	return SejourExt{
		Sejour:          sejour,
		Groups:          groupList,
		ExportClientURL: clientURL,
		Label:           sejour.Label(),
	}
}

func (ct *Controller) getSejours(uID us.IdUser) ([]SejourExt, error) {
	sejours, err := sej.SelectSejoursByOwners(ct.db, uID)
	if err != nil {
		return nil, utils.SQLError(err)
	}

	groups, err := sej.SelectGroupsBySejours(ct.db, sejours.IDs()...)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	groupsMap := groups.BySejour()

	out := make([]SejourExt, 0, len(sejours))
	for _, sejour := range sejours {
		out = append(out, ct.newSejourExt(sejour, groupsMap[sejour.Id]))
	}

	// more recent first
	sort.Slice(out, func(i, j int) bool { return out[i].Sejour.Start.T().After(out[j].Sejour.Start.T()) })

	return out, nil
}

// SejoursCreate creates a [Sejour] with a default group.
func (ct *Controller) SejoursCreate(c echo.Context) error {
	uID := users.JWTUser(c)

	out, err := ct.createSejour(uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) createSejour(uID us.IdUser) (SejourExt, error) {
	tx, err := ct.db.Begin()
	if err != nil {
		return SejourExt{}, utils.SQLError(err)
	}

	sejour, err := sej.Sejour{Owner: uID, Start: sej.Date(time.Now())}.Insert(tx)
	if err != nil {
		_ = tx.Rollback()
		return SejourExt{}, utils.SQLError(err)
	}

	// add a defaut group
	group, err := sej.Group{Sejour: sejour.Id, Size: 25}.Insert(tx)
	if err != nil {
		_ = tx.Rollback()
		return SejourExt{}, utils.SQLError(err)
	}

	err = tx.Commit()
	if err != nil {
		return SejourExt{}, utils.SQLError(err)
	}

	return ct.newSejourExt(sejour, sej.Groups{group.Id: group}), nil
}

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

func (ct *Controller) SejoursUpdate(c echo.Context) error {
	uID := users.JWTUser(c)

	var args sej.Sejour
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateSejour(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateSejour(in sej.Sejour, uID us.IdUser) error {
	sejour, err := ct.checkSejourOwner(in.Id, uID)
	if err != nil {
		return err
	}

	sejour.Name = in.Name
	sejour.Start = in.Start
	_, err = sejour.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
}

func (ct *Controller) SejoursDelete(c echo.Context) error {
	uID := users.JWTUser(c)

	id, err := utils.QueryParamInt[sej.IdSejour](c, "id")
	if err != nil {
		return err
	}

	err = ct.deleteSejour(id, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) deleteSejour(id sej.IdSejour, uID us.IdUser) error {
	_, err := ct.checkSejourOwner(id, uID)
	if err != nil {
		return err
	}

	_, err = sej.DeleteSejourById(ct.db, id)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
}

// SejoursCreateGroupe adds a [Group] to the given sejour,
// also adding this group to all existing meals.
func (ct *Controller) SejoursCreateGroupe(c echo.Context) error {
	uID := users.JWTUser(c)

	id, err := utils.QueryParamInt[sej.IdSejour](c, "idSejour")
	if err != nil {
		return err
	}

	out, err := ct.createGroup(id, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) createGroup(idSejour sej.IdSejour, uID us.IdUser) (sej.Group, error) {
	_, err := ct.checkSejourOwner(idSejour, uID)
	if err != nil {
		return sej.Group{}, err
	}

	group, err := sej.Group{Sejour: idSejour, Size: 25, Name: "Groupe"}.Insert(ct.db)
	if err != nil {
		return sej.Group{}, utils.SQLError(err)
	}

	err = utils.InTx(ct.db, func(tx *sql.Tx) error {
		meals, err := sej.SelectMealsBySejours(tx, idSejour)
		if err != nil {
			return utils.SQLError(err)
		}
		var links sej.MealGroups
		for _, meal := range meals {
			links = append(links, sej.MealGroup{IdMeal: meal.Id, IdGroup: group.Id})
		}
		err = sej.InsertManyMealGroups(tx, links...)
		if err != nil {
			return utils.SQLError(err)
		}
		return nil
	})

	return group, err
}

func (ct *Controller) SejoursUpdateGroupe(c echo.Context) error {
	uID := users.JWTUser(c)

	var args sej.Group
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateGroup(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateGroup(in sej.Group, uID us.IdUser) error {
	group, err := sej.SelectGroup(ct.db, in.Id)
	if err != nil {
		return utils.SQLError(err)
	}

	_, err = ct.checkSejourOwner(group.Sejour, uID)
	if err != nil {
		return err
	}

	group.Name = in.Name
	group.Color = in.Color
	group.Size = in.Size
	_, err = group.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
}

func (ct *Controller) SejoursDeleteGroupe(c echo.Context) error {
	uID := users.JWTUser(c)

	id, err := utils.QueryParamInt[sej.IdGroup](c, "idGroup")
	if err != nil {
		return err
	}

	err = ct.deleteGroup(id, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) deleteGroup(id sej.IdGroup, uID us.IdUser) error {
	group, err := sej.SelectGroup(ct.db, id)
	if err != nil {
		return utils.SQLError(err)
	}

	_, err = ct.checkSejourOwner(group.Sejour, uID)
	if err != nil {
		return err
	}

	_, err = sej.DeleteGroupById(ct.db, group.Id)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
}

// SejoursDuplicate duplicate a sejour and all the associated meals and (private) menus
func (ct *Controller) SejoursDuplicate(c echo.Context) error {
	uID := users.JWTUser(c)

	id, err := utils.QueryParamInt[sej.IdSejour](c, "idSejour")
	if err != nil {
		return err
	}

	sejour, err := ct.duplicateSejour(id, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, sejour)
}

func (ct *Controller) duplicateSejour(id sej.IdSejour, uID us.IdUser) (SejourExt, error) {
	origin, err := ct.checkSejourOwner(id, uID)
	if err != nil {
		return SejourExt{}, err
	}

	// deep copy
	tx, err := ct.db.Begin()
	if err != nil {
		return SejourExt{}, utils.SQLError(err)
	}
	newSejour, newGroups, err := duplicateSejour(origin, tx)
	if err != nil {
		_ = tx.Rollback()
		return SejourExt{}, err
	}
	err = tx.Commit()
	if err != nil {
		return SejourExt{}, utils.SQLError(err)
	}

	return ct.newSejourExt(newSejour, newGroups), nil
}

// do not COMMIT or ROLLBACK
func duplicateSejour(origin sej.Sejour, tx *sql.Tx) (sej.Sejour, sej.Groups, error) {
	newSejour, err := origin.Insert(tx)
	if err != nil {
		return sej.Sejour{}, nil, utils.SQLError(err)
	}

	groups, err := sej.SelectGroupsBySejours(tx, origin.Id)
	if err != nil {
		return sej.Sejour{}, nil, utils.SQLError(err)
	}
	meals, err := sej.SelectMealsBySejours(tx, origin.Id)
	if err != nil {
		return sej.Sejour{}, nil, utils.SQLError(err)
	}
	links, err := sej.SelectMealGroupsByIdMeals(tx, meals.IDs()...)
	if err != nil {
		return sej.Sejour{}, nil, utils.SQLError(err)
	}
	mealGroups := links.ByIdMeal()
	menus, err := men.SelectMenus(tx, meals.Menus()...)
	if err != nil {
		return sej.Sejour{}, nil, utils.SQLError(err)
	}

	// groups :
	// adjust the ID and stores the old -> new mapping
	mapping := map[sej.IdGroup]sej.IdGroup{}
	newGroups := sej.Groups{}
	for _, oldGroup := range groups {
		newGroup := oldGroup
		newGroup.Sejour = newSejour.Id
		newGroup, err = newGroup.Insert(tx)
		if err != nil {
			return sej.Sejour{}, nil, utils.SQLError(err)
		}
		mapping[oldGroup.Id] = newGroup.Id
		newGroups[newGroup.Id] = newGroup
	}

	// meals :
	// adjust the ID and create the links
	var newLinks sej.MealGroups
	for _, oldMeal := range meals {
		menu := menus[oldMeal.Menu]
		if !menu.IsFavorite { // the menu is hidden : duplicate
			menu, err = library.DuplicateMenu(tx, menu)
			if err != nil {
				return sej.Sejour{}, nil, utils.SQLError(err)
			}
		}

		newMeal := oldMeal
		newMeal.Menu = menu.Id // needed if [menu] has been duplicated
		newMeal.Sejour = newSejour.Id
		newMeal, err = newMeal.Insert(tx)
		if err != nil {
			return sej.Sejour{}, nil, utils.SQLError(err)
		}
		for _, oldGroup := range mealGroups[oldMeal.Id] {
			newGroup := mapping[oldGroup.IdGroup]
			newLinks = append(newLinks, sej.MealGroup{IdMeal: newMeal.Id, IdGroup: newGroup})
		}
	}

	err = sej.InsertManyMealGroups(tx, newLinks...)
	if err != nil {
		return sej.Sejour{}, nil, utils.SQLError(err)
	}

	return newSejour, newGroups, nil
}
