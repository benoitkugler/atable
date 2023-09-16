package order

import (
	"testing"

	"github.com/benoitkugler/atable/sql/orders"
	"github.com/benoitkugler/atable/sql/users"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestCRUDProfiles(t *testing.T) {
	db := tu.NewTestDB(t, "../../sql/users/gen_create.sql", "../../sql/menus/gen_create.sql", "../../sql/orders/gen_create.sql")

	user, err := users.User{IsAdmin: true, Mail: "test@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	ct := NewController(db.DB)

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

	// TODO update mapping

	err = ct.deleteSupplier(sup.Id, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.deleteProfile(profile.Id, user.Id)
	tu.AssertNoErr(t, err)

	profiles, err = ct.getProfiles()
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(profiles) == 0)
}
