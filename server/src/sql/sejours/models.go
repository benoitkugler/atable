package sejours

import (
	"fmt"
	"time"

	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/users"
)

type (
	IdSejour int64
	IdGroup  int64
	IdMeal   int64
)

// Sejour describes one camp.
//
// [Sejour]s are private, owned by users.
//
// gomacro:SQL ADD UNIQUE(Id, Owner)
type Sejour struct {
	Id    IdSejour
	Owner users.IdUser `gomacro-sql-on-delete:"CASCADE"`

	// [Start] is the first day of the camp.
	// Following days are computed by an offset from this day.
	Start Date
	Name  string

	// The default associations to use for ingredients
	IdProfile OptionnalIdProfile `gomacro-sql-foreign:"Profile" gomacro-sql-on-delete:"SET NULL"`
}

const day = 24 * time.Hour

func (sej *Sejour) DayAt(offset int) time.Time {
	return sej.Start.T().Add(time.Duration(offset) * day)
}

func (sej *Sejour) Label() string {
	return fmt.Sprintf("%s %d", sej.Name, sej.Start.T().Year)
}

// Group is a group of people in a [Sejour].
//
// Some camps only have one group (whose name is ignored).
type Group struct {
	Id     IdGroup
	Sejour IdSejour `gomacro-sql-on-delete:"CASCADE"`

	Name  string
	Color string // HTML hex color, like #AF0853
	Size  int    // the number of people in this group, used in [Meal]s
}

// Meal defines one meal from a [menus.Menu], for some groups and a given time.
//
// The calendar for a [Sejour] is built from a list of [Meal]s.
//
// The number of people for one [Meal] is computed by adding
// the [Group]s suscribed to it, and the [AdditionalPeople] field.
type Meal struct {
	Id     IdMeal
	Sejour IdSejour `gomacro-sql-on-delete:"CASCADE"`
	Menu   menus.IdMenu

	Jour             int // offset from the [Sejour.Start]
	AdditionalPeople int // may be negative
	Horaire          Horaire
}

// MealGroup is a link item.
//
// gomacro:SQL ADD UNIQUE(IdMeal, IdGroup)
type MealGroup struct {
	IdMeal  IdMeal  `gomacro-sql-on-delete:"CASCADE"`
	IdGroup IdGroup `gomacro-sql-on-delete:"CASCADE"`
}
