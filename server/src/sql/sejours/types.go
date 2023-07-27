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
