package library

import (
	"bytes"
	"fmt"
	"os"
	"reflect"
	"testing"

	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/users"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestImportCSV(t *testing.T) {
	f, err := os.Open("test/receipes_samples.csv")
	tu.AssertNoErr(t, err)

	l, err := newCSVImporter(f)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(l) == 31)
}

func TestImportCSVApi(t *testing.T) {
	f, err := os.Open("test/receipes_samples.csv")
	tu.AssertNoErr(t, err)

	db := tu.NewTestDB(t, "../../sql/users/gen_create.sql", "../../sql/menus/gen_create.sql", "../../../migrations/create_manual.sql")
	defer db.Remove()

	ct := NewController(db.DB, users.User{})

	out, err := ct.importCSV1(f)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(out.Receipes) == 31)

	// simlated re-mapping by user
	out.Map["Aubergines"] = menus.Ingredient{Id: -1, Name: "Mes aubergines"}
	out.Map["Echalottes"] = menus.Ingredient{Id: -1, Name: "Mes aubergines"} // same name

	receipes, err := ct.importCSV2(out, 1)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(receipes) == len(out.Receipes))

	fmt.Println(receipes[0].Receipe.Description)

	csvBytes, err := ct.exportReceipes(1)
	tu.AssertNoErr(t, err)
	err = os.WriteFile("test/receipes_samples_out.csv", csvBytes, os.ModePerm)
	tu.AssertNoErr(t, err)

	_, err = newCSVImporter(bytes.NewReader(csvBytes)) // make sure the output format is compatible
	tu.AssertNoErr(t, err)
}

func Test_words(t *testing.T) {
	tests := []struct {
		name string
		want []string
	}{
		{"Jambon (dés)", []string{"jambon", "des"}},
		{"Dés de jambon", []string{"des", "jambon"}},
	}
	for _, tt := range tests {
		if got := words(tt.name); !reflect.DeepEqual(got, tt.want) {
			t.Errorf("words() = %v, want %v", got, tt.want)
		}
	}
}
