package sejours

import (
	"database/sql"
	"testing"
	"time"

	"github.com/benoitkugler/atable/pass"
	"github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
	"github.com/benoitkugler/atable/sql/users"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func setup(t *testing.T) (db tu.TestDB, _ users.User, _ menus.Menu) {
	db = tu.NewTestDB(t, "../../sql/users/gen_create.sql", "../../sql/menus/gen_create.sql", "../../sql/sejours/gen_create.sql")

	user, err := users.User{IsAdmin: true, Mail: "test@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	ing1, err := menus.Ingredient{Name: "Ing1", Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	ing2, err := menus.Ingredient{Name: "Ing2", Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	rec, err := menus.Receipe{Owner: user.Id, Name: "Receipe1"}.Insert(db)
	tu.AssertNoErr(t, err)

	menu1, err := menus.Menu{Owner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	menu2, err := menus.Menu{Owner: user.Id, IsFavorite: true}.Insert(db)
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

	return db, user, menu2
}

func TestSejours(t *testing.T) {
	db, user, _ := setup(t)
	defer db.Remove()

	ct := NewController(db.DB, "", user, pass.Encrypter{})
	sejours, err := ct.getSejours(user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(sejours) == 2)
	tu.Assert(t, len(sejours[0].Groups) == 3)
	tu.Assert(t, len(sejours[1].Groups) == 0)

	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, sejour.ExportClientURL != "")

	sejour.Sejour.Name = "aslmakm"
	err = ct.updateSejour(sejour.Sejour, user.Id)
	tu.AssertNoErr(t, err)

	_, err = ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 1, Horaire: sej.Cinquieme}, user.Id)
	tu.AssertNoErr(t, err)

	group, err := ct.createGroup(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)

	meals, err := ct.loadMeals(sejour.Sejour.Id, optionnalInt{}, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(meals.Meals[0].Groups) == 2)

	group.Name = "AHH"
	group.Size = 2
	err = ct.updateGroup(group, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.deleteGroup(group.Id, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.deleteSejour(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)
}

func TestDuplicateSejour(t *testing.T) {
	db, user, menu := setup(t)
	defer db.Remove()

	ct := NewController(db.DB, "", user, pass.Encrypter{})

	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)
	mealPrivate, err := ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 1, Horaire: sej.Cinquieme}, user.Id)
	tu.AssertNoErr(t, err)
	mealPublic, err := ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 2, Horaire: sej.Cinquieme}, user.Id)
	tu.AssertNoErr(t, err)
	_, err = ct.setMenu(SetMenuIn{IdMeal: mealPublic.Meal.Id, IdMenu: menu.Id}, user.Id)
	tu.AssertNoErr(t, err)

	newSejour, err := ct.duplicateSejour(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)

	meals, err := ct.loadMeals(newSejour.Sejour.Id, optionnalInt{}, user.Id)
	tu.AssertNoErr(t, err)

	tu.Assert(t, len(meals.Menus) == 2)
	tu.Assert(t, len(meals.Meals) == 2)
	tu.Assert(t, meals.Meals[0].Meal.Menu != mealPrivate.Meal.Menu) // private
	tu.Assert(t, meals.Meals[1].Meal.Menu == menu.Id)               // public
}
