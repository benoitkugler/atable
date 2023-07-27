package sejours

import (
	"fmt"
	"testing"

	sej "github.com/benoitkugler/atable/sql/sejours"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestMeals(t *testing.T) {
	db, user := setup(t)
	defer db.Remove()

	ct := NewController(db.DB, user)
	sejour, err := ct.createSejour(user.Id)
	tu.AssertNoErr(t, err)

	out, err := ct.getMeals(sejour.Sejour.Id, user.Id)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out) == 0)
}

func TestAssitantMeals(t *testing.T) {
	db, user := setup(t)
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
