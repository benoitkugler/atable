package library

import (
	"testing"

	"github.com/benoitkugler/atable/sql/menus"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestFormatFloat(t *testing.T) {
	tu.Assert(t, Quantity{Unite: menus.U_L, Val: 4.166666666666667}.String() == "4.2 L")
	tu.Assert(t, Quantity{Unite: menus.U_L, Val: 750}.String() == "750 L")
	tu.Assert(t, Quantity{Unite: menus.U_L, Val: 2.5}.String() == "2.5 L")
}
