package orders

import (
	"database/sql"
	"testing"

	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestRemove(t *testing.T) {
	db := tu.NewTestDB(t, "../users/gen_create.sql", "../menus/gen_create.sql", "../orders/gen_create.sql", "../sejours/gen_create.sql")
	defer db.Remove()

	user, err := users.User{}.Insert(db)
	tu.AssertNoErr(t, err)

	p1, err := Profile{IdOwner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)
	p2, err := Profile{IdOwner: user.Id}.Insert(db)
	tu.AssertNoErr(t, err)

	sup1, err := Supplier{IdProfile: p1.Id, Name: "1"}.Insert(db)
	tu.AssertNoErr(t, err)
	sup2, err := Supplier{IdProfile: p1.Id, Name: "2"}.Insert(db)
	tu.AssertNoErr(t, err)
	sup3, err := Supplier{IdProfile: p2.Id, Name: "3"}.Insert(db)
	tu.AssertNoErr(t, err)

	err = utils.InTx(db.DB, func(tx *sql.Tx) error {
		return InsertManyIngredientkindSuppliers(tx,
			IngredientkindSupplier{Kind: menus.I_Empty, IdProfile: p1.Id, IdSupplier: sup1.Id},
			IngredientkindSupplier{Kind: menus.I_Empty, IdProfile: p2.Id, IdSupplier: sup3.Id},
			IngredientkindSupplier{Kind: menus.I_Boulangerie, IdProfile: p1.Id, IdSupplier: sup1.Id},
			IngredientkindSupplier{Kind: menus.I_Feculents, IdProfile: p1.Id, IdSupplier: sup2.Id},
		)
	})
	tu.AssertNoErr(t, err)

	err = RemoveSupplierForKinds(db, []menus.IngredientKind{menus.I_Boulangerie, menus.I_Feculents}, p1.Id)
	tu.AssertNoErr(t, err)

	l, err := SelectAllIngredientkindSuppliers(db)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(l) == 2)
}
