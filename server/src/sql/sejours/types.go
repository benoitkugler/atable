package sejours

import (
	"time"

	"github.com/benoitkugler/atable/sql/orders"
)

type Date time.Time

func (d Date) T() time.Time { return time.Time(d) }

func (d Date) MarshalJSON() ([]byte, error)     { return time.Time(d).MarshalJSON() }
func (d *Date) UnmarshalJSON(data []byte) error { return (*time.Time)(d).UnmarshalJSON(data) }

type Horaire uint8

const (
	PetitDejeuner Horaire = iota // Petit déjeuner
	Midi                         // Midi
	Gouter                       // Goûter
	Diner                        // Dîner
	Cinquieme                    // Cinquième
)

var hours = [...]int{
	8,
	12,
	16,
	19,
	22,
}

func (h Horaire) ApplyTo(date time.Time) time.Time {
	return time.Date(date.Year(), date.Month(), date.Day(), hours[h], 0, 0, 0, date.Location())
}

func (h Horaire) String() string {
	switch h {
	case PetitDejeuner:
		return "Petit déjeuner"
	case Midi:
		return "Midi"
	case Gouter:
		return "Goûter"
	case Diner:
		return "Dîner"
	case Cinquieme:
		return "Cinquième"
	default:
		return ""
	}
}

// RestrictByDay restrict the map to the meals
// registred for the given offset.
func (ml Meals) RestrictByDay(day int) {
	// select the day
	for id, meal := range ml {
		if meal.Jour != day {
			delete(ml, id)
		}
	}
}

// RestrictByDay restrict the map to the meals
// registred for the given offsets.
func (ml Meals) RestrictByDays(days []int) {
	crible := make(map[int]bool)
	for _, d := range days {
		crible[d] = true
	}
	// select the day
	for id, meal := range ml {
		if !crible[meal.Jour] {
			delete(ml, id)
		}
	}
}

// RestrictByHoraire restrict the map to the meals
// registred for the given horaire
func (ml Meals) RestrictByHoraire(horaire Horaire) {
	// select the day
	for id, meal := range ml {
		if meal.Horaire != horaire {
			delete(ml, id)
		}
	}
}

type OptionnalIdProfile struct {
	Valid     bool
	IdProfile orders.IdProfile
}

func NewOptionnalIdProfile(id orders.IdProfile) OptionnalIdProfile {
	return OptionnalIdProfile{Valid: true, IdProfile: id}
}
