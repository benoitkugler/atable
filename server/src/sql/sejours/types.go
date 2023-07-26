package sejours

import "time"

type Date time.Time

func (d Date) T() time.Time { return time.Time(d) }

type Horaire uint8

const (
	PetitDejeuner Horaire = iota // Petit déjeuner
	Midi                         // Midi
	Gouter                       // Goûter
	Diner                        // Dîner
	Cinquieme                    // Cinquième
)
