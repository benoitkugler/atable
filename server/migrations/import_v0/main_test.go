package main

import (
	"fmt"
	"testing"

	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestSQL(t *testing.T) {
	for k, v := range tu.ReadEnv("../../.env") {
		t.Setenv(k, v)
	}
	v0, v1, err := connectDB()
	tu.AssertNoErr(t, err)

	_, _, err = loadIngredients(v0, v1)
	tu.AssertNoErr(t, err)

	receipes, err := loadReceipes(v0)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(receipes) == 12)

	menus, err := loadMenus(v0)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(menus) == 5)
}

func TestIngredientMap(t *testing.T) {
	for k, v := range tu.ReadEnv("../../.env") {
		t.Setenv(k, v)
	}
	db0, db1, err := connectDB()
	tu.AssertNoErr(t, err)

	v0, v1, err := loadIngredients(db0, db1)
	tu.AssertNoErr(t, err)

	for i0, i1 := range ingredientsConvertion {
		fmt.Println(v0[i0].name, "->", v1[i1].Name)
	}
}

func TestMigrate(t *testing.T) {
	t.Skip() // comment to acutally run the migration
	for k, v := range tu.ReadEnv("../../.env") {
		t.Setenv(k, v)
	}
	v0, v1, err := connectDB()
	tu.AssertNoErr(t, err)

	err = migrate(v0, v1, 8)
	tu.AssertNoErr(t, err)
}
