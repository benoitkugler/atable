package sejours

import (
	"testing"

	"github.com/benoitkugler/atable/pass"
	sej "github.com/benoitkugler/atable/sql/sejours"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestLoadClient(t *testing.T) {
	db, user, menu := setup(t)
	defer db.Remove()
	ct := NewController(db.DB, "", user, pass.Encrypter{})

	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)
	_, err = ct.createGroup(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)

	m, err := ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 0, Horaire: sej.PetitDejeuner}, user.Id)
	tu.AssertNoErr(t, err)

	m, err = ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 0, Horaire: sej.PetitDejeuner}, user.Id)
	tu.AssertNoErr(t, err)

	m, err = ct.createMeal(MealCreateIn{IdSejour: sejour.Sejour.Id, Day: 0, Horaire: sej.Diner}, user.Id)
	tu.AssertNoErr(t, err)

	_, err = ct.setMenu(SetMenuIn{IdMeal: m.Meal.Id, IdMenu: menu.Id}, user.Id)
	tu.AssertNoErr(t, err)

	out, err := ct.exportToClient(sejour.Sejour.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out.Meals) == 3)
}
