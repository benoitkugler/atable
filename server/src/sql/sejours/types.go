package sejours

import "time"

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
