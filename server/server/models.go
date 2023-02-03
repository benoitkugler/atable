package server

type Session struct {
	id   string
	list ShopList
}

type ShopList []IngredientQuantite

type IngredientQuantite struct {
	Id        int                 `json:"id"`
	Nom       string              `json:"nom"`
	Categorie categorieIngredient `json:"categorie"`
	Quantite  string              `json:"quantite"`
	Checked   bool                `json:"checked"`
}

type categorieIngredient uint8
