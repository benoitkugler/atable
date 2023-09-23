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

func TestCRUDProfiles(t *testing.T) {
	db := tu.NewTestDB(t, "../../sql/users/gen_create.sql", "../../sql/menus/gen_create.sql", "../../sql/orders/gen_create.sql", "../../sql/sejours/gen_create.sql")

	user, err := users.User{IsAdmin: true, Mail: "test@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	sej, err := sejours.Sejour{Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	ct := NewController(db.DB)

	// setup some ingredients
	ing1, err := menus.Ingredient{Name: "1", Owner: user.Id}.Insert(ct.db)
	tu.AssertNoErr(t, err)
	ing2, err := menus.Ingredient{Name: "2", Owner: user.Id}.Insert(ct.db)
	tu.AssertNoErr(t, err)
	ing3, err := menus.Ingredient{Name: "3", Owner: user.Id}.Insert(ct.db)
	tu.AssertNoErr(t, err)

	profiles, err := ct.getProfiles()
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(profiles) == 0)

	profile, err := ct.createProfile(user.Id)
	tu.AssertNoErr(t, err)

	profile.Name = "Super colo !"
	err = ct.updateProfile(profile, user.Id)
	tu.AssertNoErr(t, err)

	profiles, err = ct.getProfiles()
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(profiles) == 1)

	// update suppliers
	sup, err := ct.addSupplier(orders.Supplier{IdProfile: profile.Id, Name: "Test"}, user.Id)
	tu.AssertNoErr(t, err)

	sup.Name = "New name"
	err = ct.updateSupplier(sup, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.updateProfileMap(UpdateProfileMapIn{
		IdProfile:   profile.Id,
		Ingredients: []menus.IdIngredient{ing1.Id, ing2.Id, ing3.Id},
		NewSupplier: sup.Id,
	}, user.Id)
	tu.AssertNoErr(t, err)
	err = ct.updateProfileMap(UpdateProfileMapIn{
		IdProfile:   profile.Id,
		Ingredients: []menus.IdIngredient{ing2.Id},
		NewSupplier: -1,
	}, user.Id)
	tu.AssertNoErr(t, err)

	ma, err := ct.defaultMapping(DefaultMappingIn{Ingredients: []menus.IdIngredient{ing1.Id, ing2.Id, ing3.Id}, Profile: sejours.NewOptionnalIdProfile(profile.Id)})
	tu.AssertNoErr(t, err)
	tu.Assert(t, reflect.DeepEqual(ma, IngredientMapping{ing1.Id: sup.Id, ing3.Id: sup.Id}))

	err = ct.setDefaultProfile(SetDefaultProfile{IdSejour: sej.Id, IdProfile: profile.Id}, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.deleteSupplier(sup.Id, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.deleteProfile(profile.Id, user.Id)
	tu.AssertNoErr(t, err)

	profiles, err = ct.getProfiles()
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(profiles) == 0)
}
