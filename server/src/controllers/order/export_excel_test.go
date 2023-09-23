package order

import (
	"encoding/json"
	"os"
	"testing"
	"time"

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
		Sejour:                sejours.Sejour{Start: sejours.Date(time.Now())},

		Suppliers: orders.Suppliers{
			1: orders.Supplier{Name: "Pomona"},
			2: orders.Supplier{Name: "Super U"},
		}, Mapping: IngredientMapping{
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
