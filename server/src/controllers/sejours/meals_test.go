package sejours

import (
	"fmt"
	"testing"

	"github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestMeals(t *testing.T) {
	db, user, _ := setup(t)
	defer db.Remove()

	ct := NewController(db.DB, user)
	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)

	out, err := ct.getMeals(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out) == 0)
}

func TestAssitantMeals(t *testing.T) {
	db, user, _ := setup(t)
	defer db.Remove()

	ct := NewController(db.DB, user)
	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)
	group1 := sejour.Groups[0]

	group2, err := ct.createGroup(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)

	err = ct.assistantMeals(AssistantMealsIn{
		IdSejour:           sejour.Sejour.Id,
		DaysNumber:         5,
		Excursions:         map[int][]sej.IdGroup{0: {group1.Id}, 1: {group2.Id}, 2: {group1.Id, group2.Id}},
		WithGouter:         true,
		GroupsForCinquieme: []sej.IdGroup{group1.Id},
		DeleteExisting:     true,
	}, user.Id)
	tu.AssertNoErr(t, err)

	meals, err := ct.getMeals(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)
	fmt.Println(len(meals), 8+1+8+1+4+1+5+5)
	tu.Assert(t, len(meals) == 8+1+8+1+4+1+5+5)
}

func TestSearch(t *testing.T) {
	db, user, _ := setup(t)
	defer db.Remove()

	ct := NewController(db.DB, user)
	out, err := ct.searchResource("ing", user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out.Ingredients) == 2 && len(out.Menus) == 1 && len(out.Receipes) == 0) // two ings and one menu

	out, err = ct.searchResource("rec", user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out.Ingredients) == 0 && len(out.Menus) == 1 && len(out.Receipes) == 1) // one rec and one menu (the other is not favorite)
}

func TestSQLMeals(t *testing.T) {
	db, user, _ := setup(t)
	defer db.Remove()
	ct := NewController(db.DB, user)

	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)
	_, err = ct.createGroup(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)

	out, err := ct.loadMeals(sejour.Sejour.Id, 0, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out.Meals) == 0 && len(out.Groups) == 2)

	m, err := ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 0, Horaire: sej.PetitDejeuner}, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(m.Groups) == 2)

	m, err = ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 0, Horaire: sej.PetitDejeuner}, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(m.Groups) == 0)

	m, err = ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 0, Horaire: sej.Diner}, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(m.Groups) == 2)

	m, err = ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 1, Horaire: sej.Diner}, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(m.Groups) == 2)

	m, err = ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: -1, Horaire: sej.Diner}, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(m.Groups) == 2)

	out, err = ct.loadMeals(sejour.Sejour.Id, 0, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out.Meals) == 3 && len(out.Groups) == 2)

	err = ct.deleteMeal(m.Meal.Id, user.Id)
	tu.AssertNoErr(t, err)
}

func TestMoveGroups(t *testing.T) {
	db, user, _ := setup(t)
	defer db.Remove()
	ct := NewController(db.DB, user)

	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)
	g2, err := ct.createGroup(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)

	m1, err := ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id}, user.Id)
	tu.AssertNoErr(t, err)
	m2, err := ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id}, user.Id)
	tu.AssertNoErr(t, err)

	out, err := ct.moveGroup(MoveGroupIn{Group: g2.Id, From: m1.Meal.Id, To: m2.Meal.Id}, user.Id)
	tu.AssertNoErr(t, err)
	// createMeal assign all non affected groups
	tu.Assert(t, len(out[0]) == 1 && len(out[1]) == 1)
}

func TestUpdateMenu(t *testing.T) {
	db, user, menu := setup(t)
	defer db.Remove()
	ct := NewController(db.DB, user)

	rec, err := menus.Receipe{Owner: user.Id, Name: "Receipe2"}.Insert(db)
	tu.AssertNoErr(t, err)

	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)

	meal, err := ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id}, user.Id)
	tu.AssertNoErr(t, err)

	out, err := ct.addReceipe(AddReceipeIn{IdMenu: meal.Meal.Menu, IdReceipe: rec.Id}, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out.Receipes) == 1)

	out, err = ct.addIngredient(AddIngredientIn{IdMenu: meal.Meal.Menu, IdIngredient: 2}, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out.Ingredients) == 1)

	_, err = ct.updateMenuIngredient(menus.MenuIngredient{IdMenu: meal.Meal.Menu, IdIngredient: 2, Quantity: menus.QuantityR{}, Plat: menus.P_Entree}, user.Id)
	tu.AssertNoErr(t, err)

	oldMenu := meal.Meal.Menu
	_, err = ct.setMenu(SetMenuIn{IdMeal: meal.Meal.Id, IdMenu: menu.Id}, user.Id)
	tu.AssertNoErr(t, err)
	// check the old menu is collected
	_, err = menus.SelectMenu(ct.db, oldMenu)
	tu.Assert(t, err != nil)
}
