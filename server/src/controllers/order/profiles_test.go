package order

import (
	"reflect"
	"testing"

	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/orders"
	"github.com/benoitkugler/atable/sql/sejours"
	"github.com/benoitkugler/atable/sql/users"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func setup(t *testing.T) (_ tu.TestDB, _ sejours.Sejour, i1, i2, i3 menus.Ingredient) {
	db := tu.NewTestDB(t, "../../sql/users/gen_create.sql", "../../sql/menus/gen_create.sql", "../../sql/orders/gen_create.sql", "../../sql/sejours/gen_create.sql")

	user, err := users.User{IsAdmin: true, Mail: "test@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	sej, err := sejours.Sejour{Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	// setup some ingredients
	i1, err = menus.Ingredient{Name: "1", Owner: user.Id, Kind: menus.I_Boulangerie}.Insert(db)
	tu.AssertNoErr(t, err)
	i2, err = menus.Ingredient{Name: "2", Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)
	i3, err = menus.Ingredient{Name: "3", Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	return db, sej, i1, i2, i3
}

func TestCRUDProfiles(t *testing.T) {
	db, sej, ing1, ing2, ing3 := setup(t)
	user := sej.Owner
	ct := NewController(db.DB)

	profiles, err := ct.getProfiles()
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(profiles) == 0)

	profile, err := ct.createProfile(user)
	tu.AssertNoErr(t, err)

	profile.Name = "Super colo !"
	err = ct.updateProfile(profile, user)
	tu.AssertNoErr(t, err)

	profiles, err = ct.getProfiles()
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(profiles) == 1)

	// update suppliers
	sup, err := ct.addSupplier(orders.Supplier{IdProfile: profile.Id, Name: "Test"}, user)
	tu.AssertNoErr(t, err)

	sup.Name = "New name"
	err = ct.updateSupplier(sup, user)
	tu.AssertNoErr(t, err)

	err = ct.updateProfileMapIng(UpdateProfileMapIngIn{
		IdProfile:   profile.Id,
		Ingredients: []menus.IdIngredient{ing1.Id, ing2.Id, ing3.Id},
		NewSupplier: sup.Id,
	}, user)
	tu.AssertNoErr(t, err)
	err = ct.updateProfileMapIng(UpdateProfileMapIngIn{
		IdProfile:   profile.Id,
		Ingredients: []menus.IdIngredient{ing2.Id},
		NewSupplier: -1,
	}, user)
	tu.AssertNoErr(t, err)

	ma, err := ct.defaultMapping(DefaultMappingIn{Ingredients: []menus.IdIngredient{ing1.Id, ing2.Id, ing3.Id}, Profile: profile.Id})
	tu.AssertNoErr(t, err)
	tu.Assert(t, reflect.DeepEqual(ma, IngredientMapping{ing1.Id: sup.Id, ing3.Id: sup.Id}))

	err = ct.setDefaultProfile(SetDefaultProfile{IdSejour: sej.Id, IdProfile: profile.Id}, user)
	tu.AssertNoErr(t, err)

	err = ct.deleteSupplier(sup.Id, user)
	tu.AssertNoErr(t, err)

	err = ct.deleteProfile(profile.Id, user)
	tu.AssertNoErr(t, err)

	profiles, err = ct.getProfiles()
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(profiles) == 0)
}

func TestNormalizeProfile(t *testing.T) {
	db, sej, ing1, ing2, ing3 := setup(t)
	user := sej.Owner
	ct := NewController(db.DB)

	profile, err := ct.createProfile(user)
	tu.AssertNoErr(t, err)

	sup, err := ct.addSupplier(orders.Supplier{IdProfile: profile.Id, Name: "Test"}, user)
	tu.AssertNoErr(t, err)

	err = ct.updateProfileMapIng(UpdateProfileMapIngIn{
		IdProfile:   profile.Id,
		Ingredients: []menus.IdIngredient{ing1.Id, ing2.Id, ing3.Id},
		NewSupplier: sup.Id,
	}, user)
	tu.AssertNoErr(t, err)
	err = ct.updateProfileMapKind(UpdateProfileMapKindIn{
		IdProfile: profile.Id,
		Supplier:  sup.Id,
		Kinds:     []menus.IngredientKind{menus.I_Boulangerie},
	}, user)
	tu.AssertNoErr(t, err)

	err = ct.tidyProfileMapping(profile.Id, user)
	tu.AssertNoErr(t, err)

	l, err := orders.SelectAllIngredientSuppliers(ct.db)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(l) == 2) // ing1 in boulangerie is redundant
}
