package menus

import (
	"time"

	"github.com/benoitkugler/atable/sql/users"
)

type IngredientKind uint8

const (
	I_Empty       IngredientKind = iota // Autre
	I_Legumes                           // Fruits et légumes
	I_Feculents                         // Féculents
	I_Viandes                           // Viandes, poissons
	I_Epicerie                          // Épicerie
	I_Laitages                          // Laitages
	I_Boulangerie                       // Boulangerie
)

func (ik IngredientKind) String() string {
	switch ik {
	case I_Empty:
		return "Autre"
	case I_Legumes:
		return "Fruits et légumes"
	case I_Feculents:
		return "Féculents"
	case I_Viandes:
		return "Viandes, poissons"
	case I_Epicerie:
		return "Épicerie"
	case I_Laitages:
		return "Laitages"
	case I_Boulangerie:
		return "Boulangerie"
	default:
		return ""
	}
}

type PlatKind uint8

func (pk PlatKind) String() string {
	switch pk {
	case P_Empty:
		return "Autre"
	case P_Dessert:
		return "Dessert"
	case P_PlatPrincipal:
		return "Plat principal"
	case P_Entree:
		return "Entrée"
	default:
		return ""
	}
}

const (
	P_Empty         PlatKind = iota // Autre
	P_Dessert                       // Dessert
	P_PlatPrincipal                 // Plat principal
	P_Entree                        // Entrée
)

// Unite describes how an ingredient is measured.
//
// Some unites are trivially convertible from one to each other (like Kg and G),
// other don't.
//
// A same ingredient may be used with different quantity.
type Unite uint8

const (
	U_Piece Unite = iota // pièces
	U_Kg                 // kg
	U_G                  // gr
	U_L                  // L
	U_CL                 // cL
)

func (u Unite) String() string {
	switch u {
	case U_Piece:
		return "pièces"
	case U_Kg:
		return "kg"
	case U_G:
		return "gr"
	case U_L:
		return "L"
	case U_CL:
		return "cL"
	default:
		return ""
	}
}

// QuantityR is a relative quantity.
type QuantityR struct {
	Val   float64
	Unite Unite
	For   int `json:"For_"` // the number of person [Value] refers to.
}

// ResolveFor return the (absolute) quantity required for
// the given number of people.
func (qt QuantityR) ResolveFor(for_ int) float64 {
	if for_ == qt.For {
		return qt.Val // avoid spurious float errors
	}
	return qt.Val * float64(for_) / float64(qt.For)
}

func (rs IdReceipeSet) ToMenuLinks(idMenu IdMenu) MenuReceipes {
	links := make(MenuReceipes, 0, len(rs))
	for rec := range rs {
		links = append(links, MenuReceipe{IdMenu: idMenu, IdReceipe: rec})
	}
	return links
}

// RestrictVisibleBy narrows the map to the items
// accessible by the given user
func (rm Receipes) RestrictVisibleBy(user users.IdUser) {
	for id, rec := range rm {
		if rec.Owner == user || rec.IsPublished {
			continue
		}
		delete(rm, id)
	}
}

// RestrictVisibleBy narrows the map to the items
// accessible by the given user
func (rm Menus) RestrictVisibleBy(user users.IdUser) {
	for id, rec := range rm {
		if rec.Owner == user || rec.IsPublished {
			continue
		}
		delete(rm, id)
	}
}

type Time time.Time

func (d Time) T() time.Time { return time.Time(d) }

func (d Time) MarshalJSON() ([]byte, error)     { return time.Time(d).MarshalJSON() }
func (d *Time) UnmarshalJSON(data []byte) error { return (*time.Time)(d).UnmarshalJSON(data) }
