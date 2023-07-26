package users

import (
	"testing"

	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestSQL(t *testing.T) {
	db := tu.NewTestDB(t, "gen_create.sql")
	defer db.Remove()

	_, err := User{IsAdmin: true, Mail: "test@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	users, err := SelectAllUsers(db)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(users) == 1)

	_, err = User{IsAdmin: false, Mail: "test2@free.fr", Password: "a"}.Insert(db)
	tu.AssertNoErr(t, err)

	users, err = SelectAllUsers(db)
	tu.AssertNoErr(t, err)
	tu.Assert(t, len(users) == 2)

	_, err = User{IsAdmin: false, Mail: "test2@free.fr", Password: "a"}.Insert(db)
	tu.Assert(t, err != nil) // mail are unique
}
