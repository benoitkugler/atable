package order

import (
	"encoding/json"
	"os"
	"testing"
	"time"

	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/orders"
	"github.com/benoitkugler/atable/sql/sejours"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestExcel(t *testing.T) {
	b, _ := os.ReadFile("test/ings_test.json")
	var data CompileIngredientsOut
	err := json.Unmarshal(b, &data)
	tu.AssertNoErr(t, err)

	ee := exportExcel{
		CompileIngredientsOut: data,
		sejour:                sejours.Sejour{Start: sejours.Date(time.Now())},

		suppliers: orders.Suppliers{
			1: orders.Supplier{Name: "Pomona"},
			2: orders.Supplier{Name: "Super U"},
		}, mapping: IngredientMapping{
			72: 1,
			73: 1,
			28: 2,
			29: 2,
		},
	}
	buf, err := ee.ToExcel()
	tu.AssertNoErr(t, err)

	err = os.WriteFile("test/export.xls", buf.Bytes(), os.ModePerm)
	tu.AssertNoErr(t, err)
}

func TestExcelDefaultMapping(t *testing.T) {
	_, mapping := ingredientKindMapping([]IngredientQuantities{
		{Ingredient: menus.Ingredient{Id: 1, Kind: menus.I_Boulangerie}},
		{Ingredient: menus.Ingredient{Id: 2, Kind: menus.I_Boulangerie}},
		{Ingredient: menus.Ingredient{Id: 2, Kind: menus.I_Boulangerie}},
		{Ingredient: menus.Ingredient{Id: 3, Kind: menus.I_Viandes}},
		{Ingredient: menus.Ingredient{Id: 4, Kind: menus.I_Legumes}},
		{Ingredient: menus.Ingredient{Id: 5, Kind: menus.I_Legumes}},
		{Ingredient: menus.Ingredient{Id: 5, Kind: menus.I_Empty}},
		{Ingredient: menus.Ingredient{Id: 5, Kind: menus.I_Empty}},
	})
	tu.Assert(t, mapping[1] == 6)
	tu.Assert(t, mapping[2] == 6)
	tu.Assert(t, mapping[3] == 3)
}
