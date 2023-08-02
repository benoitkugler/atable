package shopsession

import (
	"testing"

	"github.com/benoitkugler/atable/sql/menus"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

var (
	ing1 = menus.Ingredient{Id: 1}
	ing2 = menus.Ingredient{Id: 2}
	ing3 = menus.Ingredient{Id: 3}
)

func TestShop(t *testing.T) {
	ct := NewController()

	out, err := ct.createSession(ShopList{{Ingredient: ing1}, {Ingredient: ing2}})
	tu.AssertNoErr(t, err)
	tu.Assert(t, out.SessionID != "")

	out2, err := ct.createSession(ShopList{{Ingredient: ing1}, {Ingredient: ing3}})
	tu.AssertNoErr(t, err)
	tu.Assert(t, out2.SessionID != out.SessionID)

	_, err = ct.updateSession(UpdateSessionIn{Id: ing1.Id, Checked: true}, out.SessionID)
	tu.AssertNoErr(t, err)

	_, err = ct.updateSession(UpdateSessionIn{Id: ing1.Id, Checked: true}, out2.SessionID)
	tu.AssertNoErr(t, err)

	_, err = ct.updateSession(UpdateSessionIn{}, "xxx")
	tu.Assert(t, err != nil)
}
