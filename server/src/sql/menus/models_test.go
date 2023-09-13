package menus

import (
	"database/sql"
	"testing"

	"github.com/benoitkugler/atable/sql/users"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestSQL(t *testing.T) {
	db := tu.NewTestDB(t, "../users/gen_create.sql", "gen_create.sql")
	defer db.Remove()

	user, err := users.User{IsAdmin: true, Mail: "test@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	ing1 := randIngredient()
	ing1.Owner = user.Id
	ing1, err = ing1.Insert(db)
	tu.AssertNoErr(t, err)

	ing2 := randIngredient()
	ing2.Owner = user.Id
	ing2, err = ing2.Insert(db)
	tu.AssertNoErr(t, err)

	rec := randReceipe()
	rec.Owner = user.Id
	rec, err = rec.Insert(db)
	tu.AssertNoErr(t, err)

	menu := randMenu()
	menu.Owner = user.Id
	menu, err = menu.Insert(db)
	tu.AssertNoErr(t, err)

	db.InTx(func(tx *sql.Tx) {
		err = InsertManyReceipeIngredients(tx,
			ReceipeIngredient{IdReceipe: rec.Id, IdIngredient: ing1.Id, Quantity: randReceipeIngredient().Quantity},
			ReceipeIngredient{IdReceipe: rec.Id, IdIngredient: ing2.Id, Quantity: randReceipeIngredient().Quantity},
		)
		tu.AssertNoErr(t, err)

		err = InsertManyMenuReceipes(tx, MenuReceipe{IdMenu: menu.Id, IdReceipe: rec.Id})
		tu.AssertNoErr(t, err)

		item1, item2 := randMenuIngredient(), randMenuIngredient()
		item1.IdMenu, item2.IdMenu = menu.Id, menu.Id
		item1.IdIngredient = ing1.Id
		item2.IdIngredient = ing2.Id
		err = InsertManyMenuIngredients(tx, item1, item2)
		tu.AssertNoErr(t, err)
	})

	_, err = DeleteReceipeById(db, rec.Id) // used in a menu
	tu.Assert(t, err != nil)

	_, err = DeleteMenuById(db, menu.Id)
	tu.AssertNoErr(t, err)

	_, err = DeleteReceipeById(db, rec.Id)
	tu.AssertNoErr(t, err)
}
