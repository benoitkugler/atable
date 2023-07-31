package sejours

import (
	"database/sql"
	"testing"

	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/users"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func setup(t *testing.T, db tu.TestDB) (_ users.User, _, _ menus.Menu) {
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
		err = menus.InsertManyReceipeIngredients(tx,
			menus.ReceipeIngredient{IdReceipe: rec.Id, IdIngredient: ing1.Id},
			menus.ReceipeIngredient{IdReceipe: rec.Id, IdIngredient: ing2.Id},
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

	return user, menu1, menu2
}

func TestSQL(t *testing.T) {
	db := tu.NewTestDB(t, "../users/gen_create.sql", "../menus/gen_create.sql", "gen_create.sql")
	defer db.Remove()

	user, menu1, menu2 := setup(t, db)

	sejour := randSejour()
	sejour.Owner = user.Id
	sejour, err := sejour.Insert(db)
	tu.AssertNoErr(t, err)

	group1 := randGroup()
	group1.Sejour = sejour.Id
	group1, err = group1.Insert(db)
	tu.AssertNoErr(t, err)
	group2 := randGroup()
	group2.Sejour = sejour.Id
	group2, err = group2.Insert(db)
	tu.AssertNoErr(t, err)

	meal1 := randMeal()
	meal1.Sejour = sejour.Id
	meal1.Menu = menu1.Id
	meal1, err = meal1.Insert(db)
	tu.AssertNoErr(t, err)
	meal2 := randMeal()
	meal2.Sejour = sejour.Id
	meal2.Menu = menu2.Id
	meal2, err = meal2.Insert(db)
	tu.AssertNoErr(t, err)

	db.InTx(func(tx *sql.Tx) {
		err = InsertManyMealGroups(tx,
			MealGroup{IdMeal: meal1.Id, IdGroup: group1.Id},
			MealGroup{IdMeal: meal1.Id, IdGroup: group2.Id},

			MealGroup{IdMeal: meal2.Id, IdGroup: group2.Id},
		)
		tu.AssertNoErr(t, err)
	})
}
