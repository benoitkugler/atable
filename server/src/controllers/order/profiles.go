package order

import (
	"database/sql"
	"sort"

	"github.com/benoitkugler/atable/controllers/users"
	"github.com/benoitkugler/atable/sql/menus"
	ord "github.com/benoitkugler/atable/sql/orders"
	sej "github.com/benoitkugler/atable/sql/sejours"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

type SupplierExt struct {
	Id          ord.IdSupplier
	Kinds       []menus.IngredientKind
	Ingredients []menus.IdIngredient
}

type ProfileExt []SupplierExt

type ProfileHeader struct {
	Profile   ord.Profile
	Suppliers ord.Suppliers
}

func (ct *Controller) OrderGetProfiles(c echo.Context) error {
	out, err := ct.getProfiles()
	if err != nil {
		return err
	}
	return c.JSON(200, out)
}

func (ct *Controller) getProfiles() ([]ProfileHeader, error) {
	profiles, err := ord.SelectAllProfiles(ct.db)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	suppliers, err := ord.SelectAllSuppliers(ct.db)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	byProfile := suppliers.ByIdProfile()
	out := make([]ProfileHeader, 0, len(profiles))
	for _, profile := range profiles {
		out = append(out, ProfileHeader{
			Profile:   profile,
			Suppliers: byProfile[profile.Id],
		})
	}

	sort.Slice(out, func(i, j int) bool { return out[i].Profile.Name < out[j].Profile.Name })

	return out, nil
}

func (ct *Controller) OrderLoadProfile(c echo.Context) error {
	id, err := utils.QueryParamInt64(c, "idProfile")
	if err != nil {
		return err
	}
	out, err := ct.loadProfile(ord.IdProfile(id))
	if err != nil {
		return err
	}
	return c.JSON(200, out)
}

func (ct *Controller) loadProfile(id ord.IdProfile) (ProfileExt, error) {
	suppliers, err := ord.SelectSuppliersByIdProfiles(ct.db, id)
	if err != nil {
		return nil, utils.SQLError(err)
	}

	links1, err := ord.SelectIngredientkindSuppliersByIdProfiles(ct.db, id)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	m1 := links1.ByIdSupplier()

	links2, err := ord.SelectIngredientSuppliersByIdProfiles(ct.db, id)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	m2 := links2.ByIdSupplier()

	out := make(ProfileExt, 0, len(suppliers))
	for _, supplier := range suppliers {
		out = append(out, SupplierExt{
			Id:          supplier.Id,
			Kinds:       m1[supplier.Id].Kinds(),
			Ingredients: m2[supplier.Id].IdIngredients(),
		})
	}
	return out, nil
}

func (ct *Controller) OrderUpdateProfile(c echo.Context) error {
	uID := users.JWTUser(c)

	var args ord.Profile
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateProfile(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) updateProfile(args ord.Profile, uID uID) error {
	profile, err := ct.checkProfileOwner(args.Id, uID)
	if err != nil {
		return err
	}

	profile.Name = args.Name
	_, err = profile.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}

	return nil
}

func (ct *Controller) OrderCreateProfile(c echo.Context) error {
	uID := users.JWTUser(c)

	out, err := ct.createProfile(uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) createProfile(uID uID) (ord.Profile, error) {
	out, err := ord.Profile{IdOwner: uID}.Insert(ct.db)
	if err != nil {
		return out, utils.SQLError(err)
	}

	return out, nil
}

func (ct *Controller) OrderDeleteProfile(c echo.Context) error {
	uID := users.JWTUser(c)

	id_, err := utils.QueryParamInt64(c, "id")
	if err != nil {
		return err
	}

	err = ct.deleteProfile(ord.IdProfile(id_), uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) deleteProfile(id ord.IdProfile, uID uID) error {
	_, err := ct.checkProfileOwner(id, uID)
	if err != nil {
		return err
	}
	_, err = ord.DeleteProfileById(ct.db, id)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

func (ct *Controller) OrderAddSupplier(c echo.Context) error {
	uID := users.JWTUser(c)

	var args ord.Supplier
	if err := c.Bind(&args); err != nil {
		return err
	}
	out, err := ct.addSupplier(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) checkProfileOwner(id ord.IdProfile, uID uID) (ord.Profile, error) {
	profile, err := ord.SelectProfile(ct.db, id)
	if err != nil {
		return ord.Profile{}, utils.SQLError(err)
	}
	if profile.IdOwner != uID {
		return ord.Profile{}, errAccessForbidden
	}
	return profile, nil
}

func (ct *Controller) addSupplier(args ord.Supplier, uID uID) (ord.Supplier, error) {
	if _, err := ct.checkProfileOwner(args.IdProfile, uID); err != nil {
		return ord.Supplier{}, err
	}

	supplier, err := args.Insert(ct.db)
	if err != nil {
		return ord.Supplier{}, utils.SQLError(err)
	}
	return supplier, nil
}

func (ct *Controller) OrderUpdateSupplier(c echo.Context) error {
	uID := users.JWTUser(c)

	var args ord.Supplier
	if err := c.Bind(&args); err != nil {
		return err
	}
	err := ct.updateSupplier(args, uID)
	if err != nil {
		return err
	}
	return c.NoContent(200)
}

func (ct *Controller) updateSupplier(args ord.Supplier, uID uID) error {
	supplier, err := ord.SelectSupplier(ct.db, args.Id)
	if err != nil {
		return utils.SQLError(err)
	}

	if _, err := ct.checkProfileOwner(supplier.IdProfile, uID); err != nil {
		return err
	}

	supplier.Name = args.Name
	_, err = supplier.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

func (ct *Controller) OrderDeleteSupplier(c echo.Context) error {
	uID := users.JWTUser(c)

	id_, err := utils.QueryParamInt64(c, "id")
	if err != nil {
		return err
	}

	err = ct.deleteSupplier(ord.IdSupplier(id_), uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) deleteSupplier(id ord.IdSupplier, uID uID) error {
	supplier, err := ord.SelectSupplier(ct.db, id)
	if err != nil {
		return utils.SQLError(err)
	}

	if _, err := ct.checkProfileOwner(supplier.IdProfile, uID); err != nil {
		return err
	}

	_, err = ord.DeleteSupplierById(ct.db, id) // links are cascaded
	if err != nil {
		return utils.SQLError(err)
	}
	return nil
}

type UpdateProfileMapIngIn struct {
	IdProfile   ord.IdProfile
	Ingredients []menus.IdIngredient
	NewSupplier ord.IdSupplier // -1 to remove the supplier
}

func (ct *Controller) OrderUpdateProfileMapIng(c echo.Context) error {
	user := users.JWTUser(c)

	var args UpdateProfileMapIngIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateProfileMapIng(args, user)
	if err != nil {
		return err
	}

	out, err := ct.loadProfile(args.IdProfile)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) updateProfileMapIng(args UpdateProfileMapIngIn, uID uID) error {
	if _, err := ct.checkProfileOwner(args.IdProfile, uID); err != nil {
		return err
	}

	err := ct.inTx(func(tx *sql.Tx) error {
		err := ord.RemoveSupplierFor(tx, args.Ingredients, args.IdProfile)
		if err != nil {
			return utils.SQLError(err)
		}
		if args.NewSupplier != -1 {
			links := make([]ord.IngredientSupplier, len(args.Ingredients))
			for i, id := range args.Ingredients {
				links[i] = ord.IngredientSupplier{IdIngredient: id, IdSupplier: args.NewSupplier, IdProfile: args.IdProfile}
			}
			err = ord.InsertManyIngredientSuppliers(tx, links...)
			if err != nil {
				return utils.SQLError(err)
			}
		}

		return nil
	})

	return err
}

type UpdateProfileMapKindIn struct {
	IdProfile ord.IdProfile
	Supplier  ord.IdSupplier
	Kinds     []menus.IngredientKind
}

func (ct *Controller) OrderUpdateProfileMapKind(c echo.Context) error {
	user := users.JWTUser(c)

	var args UpdateProfileMapKindIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.updateProfileMapKind(args, user)
	if err != nil {
		return err
	}

	out, err := ct.loadProfile(args.IdProfile)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) updateProfileMapKind(args UpdateProfileMapKindIn, uID uID) error {
	if _, err := ct.checkProfileOwner(args.IdProfile, uID); err != nil {
		return err
	}

	err := ct.inTx(func(tx *sql.Tx) error {
		err := ord.RemoveSupplierForKinds(tx, args.Kinds, args.IdProfile)
		if err != nil {
			return utils.SQLError(err)
		}
		links := make(ord.IngredientkindSuppliers, len(args.Kinds))
		for i, k := range args.Kinds {
			links[i] = ord.IngredientkindSupplier{Kind: k, IdSupplier: args.Supplier, IdProfile: args.IdProfile}
		}
		err = ord.InsertManyIngredientkindSuppliers(tx, links...)
		if err != nil {
			return utils.SQLError(err)
		}

		return nil
	})

	return err
}

type TidyIn struct {
	Id ord.IdProfile
}

func (ct *Controller) OrderTidyMapping(c echo.Context) error {
	user := users.JWTUser(c)

	var args TidyIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.tidyProfileMapping(args.Id, user)
	if err != nil {
		return err
	}

	out, err := ct.loadProfile(args.Id)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

// remove individual ingredients already mapped by a kind
// DO NOT commit/rollback
func (ct *Controller) tidyProfileMapping(id ord.IdProfile, user uID) error {
	if _, err := ct.checkProfileOwner(id, user); err != nil {
		return err
	}

	err := ct.inTx(func(tx *sql.Tx) error {
		links1, err := ord.SelectIngredientkindSuppliersByIdProfiles(tx, id)
		if err != nil {
			return utils.SQLError(err)
		}
		byKind := links1.ByKind()

		links2, err := ord.SelectIngredientSuppliersByIdProfiles(tx, id)
		if err != nil {
			return utils.SQLError(err)
		}

		ingredients, err := menus.SelectIngredients(tx, links2.IdIngredients()...)
		if err != nil {
			return utils.SQLError(err)
		}

		for _, link := range links2 {
			kind := ingredients[link.IdIngredient].Kind
			// do we already hame the same kind -> supplier mapping ?
			if byKind[kind] == link.IdSupplier {
				_, err = ord.DeleteIngredientSuppliersByIdProfileAndIdIngredient(tx, link.IdProfile, link.IdIngredient)
				if err != nil {
					return utils.SQLError(err)
				}
			}
		}

		return nil
	})
	return err
}

type SetDefaultProfile struct {
	IdSejour  sej.IdSejour
	IdProfile ord.IdProfile
}

func (ct *Controller) OrderSetDefaultProfile(c echo.Context) error {
	uID := users.JWTUser(c)

	var args SetDefaultProfile
	if err := c.Bind(&args); err != nil {
		return err
	}

	err := ct.setDefaultProfile(args, uID)
	if err != nil {
		return err
	}

	return c.NoContent(200)
}

func (ct *Controller) setDefaultProfile(args SetDefaultProfile, uID uID) error {
	sejour, err := ct.checkSejourOwner(args.IdSejour, uID)
	if err != nil {
		return err
	}

	sejour.IdProfile = sej.NewOptionnalIdProfile(args.IdProfile)
	_, err = sejour.Update(ct.db)
	if err != nil {
		return err
	}

	return nil
}

type DefaultMappingIn struct {
	Ingredients []menus.IdIngredient
	Profile     sej.OptionnalIdProfile
}

func (ct *Controller) OrderGetDefaultMapping(c echo.Context) error {
	// uID := users.JWTUser(c)

	var args DefaultMappingIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.defaultMapping(args)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) defaultMapping(args DefaultMappingIn) (IngredientMapping, error) {
	if !args.Profile.Valid {
		return nil, nil
	}

	// load the ingredient kinds
	ingredients, err := menus.SelectIngredients(ct.db, args.Ingredients...)
	if err != nil {
		return nil, utils.SQLError(err)
	}

	// load the profile
	links1, err := ord.SelectIngredientkindSuppliersByIdProfiles(ct.db, args.Profile.IdProfile)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	byKind := links1.ByKind()

	links2, err := ord.SelectIngredientSuppliersByIdProfiles(ct.db, args.Profile.IdProfile)
	if err != nil {
		return nil, utils.SQLError(err)
	}
	byIngredient := links2.ByIdIngredient()

	out := make(IngredientMapping)
	for _, idIng := range args.Ingredients {
		kind := ingredients[idIng].Kind
		// individual exceptions takes priority
		if supplier, ok := byIngredient[idIng]; ok {
			out[idIng] = supplier[0].IdSupplier // valid thanks to a unique constraint
		} else if supplier, ok := byKind[kind]; ok {
			out[idIng] = supplier
		}
	}

	return out, nil
}
