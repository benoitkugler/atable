package menus

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

type PlatKind uint8

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

// QuantityR is a relative quantity.
type QuantityR struct {
	Val   float64
	Unite Unite
	For   int `json:"For_"` // the number of person [Value] refers to.
}

func (rs IdReceipeSet) ToMenuLinks(idMenu IdMenu) MenuReceipes {
	links := make(MenuReceipes, 0, len(rs))
	for rec := range rs {
		links = append(links, MenuReceipe{IdMenu: idMenu, IdReceipe: rec})
	}
	return links
}
