package order

import (
	"encoding/json"
	"os"
	"testing"

	"github.com/benoitkugler/atable/sql/users"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestCompileIngredients(t *testing.T) {
	db, err := tu.DB.ConnectPostgres()
	if err != nil {
		t.Skip(err)
	}
	ct := NewController(db)

	const uID users.IdUser = 2
	out, err := ct.compileIngredients(CompileIngredientsIn{IdSejour: 2, DayOffsets: []int{0, 1, 2, 3, 4, 5, 6, 7}}, uID)
	tu.AssertNoErr(t, err)

	f, err := os.Create("test/ings_test.json")
	tu.AssertNoErr(t, err)
	enc := json.NewEncoder(f)
	enc.SetIndent("", " ")
	err = enc.Encode(out)
	tu.AssertNoErr(t, err)
}
