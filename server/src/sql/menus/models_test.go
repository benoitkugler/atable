package menus

import (
	"database/sql"
	"testing"

	"atable/sql/users"
	tu "atable/utils/testutils"
)

func TestSQL(t *testing.T) {
	db := tu.NewTestDB(t, "../users/gen_create.sql", "gen_create.sql")
	defer db.Remove()

	user, err := users.User{IsAdmin: true, Mail: "test@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	ing1, err := randIngredient().Insert(db)
	tu.AssertNoErr(t, err)

	ing2, err := randIngredient().Insert(db)
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
		err = InsertManyReceipeItems(tx,
			ReceipeItem{IdReceipe: rec.Id, IdIngredient: ing1.Id, Quantity: randReceipeItem().Quantity},
			ReceipeItem{IdReceipe: rec.Id, IdIngredient: ing2.Id, Quantity: randReceipeItem().Quantity},
		)
		tu.AssertNoErr(t, err)

		err = InsertManyMenuRecettes(tx, MenuRecette{IdMenu: menu.Id, IdReceipe: rec.Id})
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
