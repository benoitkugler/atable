package sejours

import (
	"database/sql"
	"testing"
	"time"

	"github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
	"github.com/benoitkugler/atable/sql/users"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func setup(t *testing.T) (db tu.TestDB, _ users.User) {
	db = tu.NewTestDB(t, "../../sql/users/gen_create.sql", "../../sql/menus/gen_create.sql", "../../sql/sejours/gen_create.sql")

	user, err := users.User{IsAdmin: true, Mail: "test@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	ing1, err := menus.Ingredient{Name: "1"}.Insert(db)
	tu.AssertNoErr(t, err)

	ing2, err := menus.Ingredient{Name: "2"}.Insert(db)
	tu.AssertNoErr(t, err)

	rec, err := menus.Receipe{Owner: user.Id, Name: "1"}.Insert(db)
	tu.AssertNoErr(t, err)

	menu1, err := menus.Menu{Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	menu2, err := menus.Menu{Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	db.InTx(func(tx *sql.Tx) {
		err = menus.InsertManyReceipeItems(tx,
			menus.ReceipeItem{IdReceipe: rec.Id, IdIngredient: ing1.Id},
			menus.ReceipeItem{IdReceipe: rec.Id, IdIngredient: ing2.Id},
		)
		tu.AssertNoErr(t, err)

		err = menus.InsertManyMenuReceipes(tx,
			menus.MenuReceipe{IdMenu: menu1.Id, IdReceipe: rec.Id},
			menus.MenuReceipe{IdMenu: menu2.Id, IdReceipe: rec.Id},
		)
		tu.AssertNoErr(t, err)

		err = menus.InsertManyMenuIngredients(tx,
			menus.MenuIngredient{IdMenu: menu2.Id, IdIngredient: ing1.Id},
		)
		tu.AssertNoErr(t, err)
	})

	sej1, err := sej.Sejour{Owner: user.Id, Start: sej.Date(time.Now()), Name: "Camp 1"}.Insert(db)
	tu.AssertNoErr(t, err)
	_, err = sej.Sejour{Owner: user.Id, Start: sej.Date(time.Now().Add(-48 * time.Hour)), Name: "Camp 2"}.Insert(db)
	tu.AssertNoErr(t, err)

	_, err = sej.Group{Sejour: sej1.Id}.Insert(db)
	tu.AssertNoErr(t, err)
	_, err = sej.Group{Sejour: sej1.Id}.Insert(db)
	tu.AssertNoErr(t, err)
	_, err = sej.Group{Sejour: sej1.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	return db, user
}

func TestSejours(t *testing.T) {
	db, user := setup(t)
	defer db.Remove()

	ct := NewController(db.DB, user)
	sejours, err := ct.getSejours(user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(sejours) == 2)
	tu.Assert(t, len(sejours[0].Groups) == 3)
	tu.Assert(t, len(sejours[1].Groups) == 0)

	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)

	sejour.Sejour.Name = "aslmakm"
	err = ct.updateSejour(sejour.Sejour, user.Id)
	tu.AssertNoErr(t, err)

	group, err := ct.createGroup(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)

	group.Name = "AHH"
	group.Size = 2
	err = ct.updateGroup(group, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.deleteGroup(group.Id, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.deleteSejour(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)
}
