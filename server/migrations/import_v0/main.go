// Migration tool from prototype intendance2 project to this one.
// Assumes only one old user and transfers it to a new user
package main

import (
	"database/sql"
	"fmt"
	"math/rand"
	"time"

	"github.com/benoitkugler/atable/pass"
	"github.com/benoitkugler/atable/sql/menus"
	"github.com/benoitkugler/atable/sql/users"
)

var ingredientsConvertion = map[int64]menus.IdIngredient{
	67: 21,  // Melon
	2:  213, // Pâtes
	5:  74,  // Concombre
	6:  195, // Fêta
	7:  51,  // Olive noire
	8:  244, // Sauté de veau
	9:  5,   // Riz
	10: 93,  // Courgette
	11: 79,  // Aubergine
	12: 73,  // Poivron
	13: 63,  // Oignon
	14: 229, // Compote de pomme
	15: 232, // Madeleine
	16: 246, // Vinaigrette
	17: 75,  // Carotte
	18: 1,   // Pomme de terre
	19: 99,  // Poisson blanc
	20: 200, // Crème fraîche
	21: 162, // Huile d'olive
	22: 177, // Ail
	23: 150, // Farine
	24: 151, // Sucre
	25: 206, // Beurre
	28: 92,  // Levure chimique
	29: 167, // Chocolat noir
	30: 121, // Oeuf
	31: 96,  // Salade verte
	32: 6,   // Maïs
	33: 107, // Dés de jambon
	34: 64,  // Echalotte
	35: 183, // Basilic
	36: 11,  // Banane
	37: 25,  // Pêche
	38: 9,   // Abricôt
	39: 8,   // Pomme
	40: 256, // Fromage
	41: 221, // Pain
	42: 247, // Chocolat au lait
	43: 248, // Sirop
	44: 94,  // Semoule moyenne
	45: 72,  // Tomate
	46: 146, // Persil
	47: 176, // Menthe
	48: 160, // Jus de citron
	49: 249, // Herbes de provence
	50: 224, // Fromage blanc
	51: 225, // Crème de marron
	53: 250, // Beurre salé
	54: 42,  // Vanille
	55: 252, // Sucre glace
	56: 29,  // Prune
	57: 161, // Huile de tournesol
	58: 69,  // Moutarde
	59: 255, // Pâte feuilletée
	60: 251, // Maïzena
	61: 201, // Lait
	62: 253, // Muscade
	63: 245, // Chair à saucisse
	64: 110, // Egréné de boeuf
	65: 254, // Sauce tomate
	66: 170, // Thym
}

var recettes = map[int64]menus.PlatKind{
	// 1:  false, // Pâtes carbonara,
	4: menus.P_Entree,        // Salade concombre fêta olive noire,
	5: menus.P_PlatPrincipal, // Ratatouille,
	6: menus.P_Entree,        // Carottes rapées,
	7: menus.P_PlatPrincipal, // Hachis parmentier de poisson,
	// 8:  false, // Gâteau au chocolat,
	9:  menus.P_Entree,        // Salade, maïs, jambon,
	10: menus.P_PlatPrincipal, // Crumble courgette,
	11: menus.P_Dessert,       // Salade de fruit d'été,
	12: menus.P_Empty,         // Pain, chocolat, sirop,
	// 13: false, // Taboulé,
	14: menus.P_PlatPrincipal, // Ratatouille sauté de veau et riz,
}

func connectDB() (*sql.DB, *sql.DB, error) {
	// old DB
	v0, err := pass.DB{
		Host:     "localhost",
		User:     "benoit",
		Password: "dummy",
		Name:     "intendance_yvan",
	}.ConnectPostgres()
	if err != nil {
		return nil, nil, err
	}

	if err = v0.Ping(); err != nil {
		return nil, nil, err
	}

	prod, err := pass.NewDB()
	if err != nil {
		return nil, nil, err
	}
	// prod := pass.DB{
	// 	Host:     "localhost",
	// 	User:     "benoit",
	// 	Password: "dummy",
	// 	Name:     "intendance_prod",
	// }
	v1, err := prod.ConnectPostgres()
	if err != nil {
		return nil, nil, err
	}
	if err = v1.Ping(); err != nil {
		return nil, nil, err
	}

	return v0, v1, nil
}

type ingredient0 struct {
	id    int64
	name  string
	unite menus.Unite
}

type Ingredients0 = map[int64]ingredient0

func loadIngredients(v0, v1 *sql.DB) (Ingredients0, menus.Ingredients, error) {
	ingredients1, err := menus.SelectAllIngredients(v1)
	if err != nil {
		return nil, nil, err
	}

	ingredients0 := Ingredients0{}
	rows, err := v0.Query("SELECT id, nom, unite FROM ingredients")
	if err != nil {
		return nil, nil, err
	}
	for rows.Next() {
		var (
			ing   ingredient0
			unite string
		)
		err = rows.Scan(&ing.id, &ing.name, &unite)
		if err != nil {
			return nil, nil, err
		}
		switch unite {
		case "P":
			ing.unite = menus.U_Piece
		case "Kg":
			ing.unite = menus.U_Kg
		case "L":
			ing.unite = menus.U_L
		default:
			return nil, nil, fmt.Errorf("unknown unit %s", unite)
		}
		ingredients0[ing.id] = ing
	}
	if err = rows.Err(); err != nil {
		return nil, nil, err
	}

	return ingredients0, ingredients1, nil
}

type ingredientReceipe0 struct {
	idIngredient int64
	quantite     float64
}

type receipe0 struct {
	id          int64
	name        string
	description string

	ingredients []ingredientReceipe0
}

type Receipes0 = map[int64]receipe0

func loadReceipes(v0 *sql.DB) (Receipes0, error) {
	receipes := Receipes0{}
	rows, err := v0.Query("SELECT id, nom, mode_emploi FROM recettes")
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var r receipe0
		err = rows.Scan(&r.id, &r.name, &r.description)
		if err != nil {
			return nil, err
		}
		receipes[r.id] = r
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}

	rows, err = v0.Query("SELECT id_recette, id_ingredient, quantite FROM recette_ingredients")
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var (
			idReceipe int64
			r         ingredientReceipe0
		)
		err = rows.Scan(&idReceipe, &r.idIngredient, &r.quantite)
		if err != nil {
			return nil, err
		}
		rec := receipes[idReceipe]
		rec.ingredients = append(rec.ingredients, r)
		receipes[idReceipe] = rec
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return receipes, nil
}

func convertReceipe(r0 receipe0, newId menus.IdReceipe, newUser users.IdUser, ingredients Ingredients0) (menus.Receipe, menus.ReceipeIngredients) {
	out := menus.Receipe{
		Id:          newId,
		Owner:       newUser,
		Plat:        recettes[r0.id],
		Name:        r0.name,
		Description: r0.description,
		Updated:     menus.Time(time.Now()),
	}
	var links menus.ReceipeIngredients
	for _, ing := range r0.ingredients {
		links = append(links, menus.ReceipeIngredient{
			IdReceipe:    newId,
			IdIngredient: ingredientsConvertion[ing.idIngredient],
			Quantity: menus.QuantityR{
				Val:   ing.quantite * 10,
				For:   10,
				Unite: ingredients[ing.idIngredient].unite,
			},
		})
	}
	return out, links
}

type menu0 struct {
	id          int64
	receipes    []int64 // id only
	ingredients []ingredientMenu0
}

type ingredientMenu0 ingredientReceipe0

type Menus0 = map[int64]menu0

func loadMenus(v0 *sql.DB) (Menus0, error) {
	menus := Menus0{}
	rows, err := v0.Query("SELECT id FROM menus")
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id int64
		err = rows.Scan(&id)
		if err != nil {
			return nil, err
		}
		menus[id] = menu0{}
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}

	rows, err = v0.Query("SELECT id_menu, id_recette FROM menu_recettes")
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var idMenu, idReceipe int64
		err = rows.Scan(&idMenu, &idReceipe)
		if err != nil {
			return nil, err
		}
		rec := menus[idMenu]
		rec.receipes = append(rec.receipes, idReceipe)
		menus[idMenu] = rec
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}

	rows, err = v0.Query("SELECT id_menu, id_ingredient, quantite FROM menu_ingredients")
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var (
			idMenu int64
			r      ingredientMenu0
		)
		err = rows.Scan(&idMenu, &r.idIngredient, &r.quantite)
		if err != nil {
			return nil, err
		}
		rec := menus[idMenu]
		rec.ingredients = append(rec.ingredients, r)
		menus[idMenu] = rec
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return menus, nil
}

func convertMenu(m0 menu0, newId menus.IdMenu, newUser users.IdUser, ingredients Ingredients0,
	receipeConversion map[int64]menus.IdReceipe,
) (menus.Menu, menus.MenuReceipes, menus.MenuIngredients) {
	out := menus.Menu{
		Id:          newId,
		Owner:       newUser,
		IsFavorite:  true,
		IsPublished: false,
		Updated:     menus.Time(time.Now()),
	}
	var (
		links1 menus.MenuReceipes
		links2 menus.MenuIngredients
	)
	for _, rec := range m0.receipes {
		links1 = append(links1, menus.MenuReceipe{
			IdMenu:    newId,
			IdReceipe: receipeConversion[rec],
		})
	}
	for _, ing := range m0.ingredients {
		links2 = append(links2, menus.MenuIngredient{
			IdMenu:       newId,
			IdIngredient: ingredientsConvertion[ing.idIngredient],
			Quantity: menus.QuantityR{
				Val:   ing.quantite * 10,
				For:   10,
				Unite: ingredients[ing.idIngredient].unite,
			},
			Plat: 0, // unknown
		})
	}
	return out, links1, links2
}

func migrate(v0, v1 *sql.DB, user users.IdUser) error {
	i0, _, err := loadIngredients(v0, v1)
	if err != nil {
		return err
	}

	receipes0, err := loadReceipes(v0)
	if err != nil {
		return err
	}

	menus0, err := loadMenus(v0)
	if err != nil {
		return err
	}

	tx1, err := v1.Begin()
	if err != nil {
		return err
	}

	// import the receipes :
	//	1) create new items and stores the IDs
	// 	2) update them with the content
	idMapR := map[int64]menus.IdReceipe{}
	for id0 := range receipes0 {
		r, err := menus.Receipe{Owner: user, Name: fmt.Sprintf("%d", rand.Int())}.Insert(tx1)
		if err != nil {
			return err
		}
		idMapR[id0] = r.Id
	}

	for oldId, newId := range idMapR {
		r1, ri1 := convertReceipe(receipes0[oldId], newId, user, i0)
		_, err := r1.Update(tx1)
		if err != nil {
			return err
		}
		err = menus.InsertManyReceipeIngredients(tx1, ri1...)
		if err != nil {
			return err
		}
	}

	// import the menus :
	//	1) create new items and stores the IDs
	// 	2) update them with the content
	idMapM := map[int64]menus.IdMenu{}
	for id0 := range menus0 {
		r, err := menus.Menu{
			IsFavorite: true, Owner: user,
			Updated: menus.Time(time.Now()),
		}.Insert(tx1)
		if err != nil {
			return err
		}
		idMapM[id0] = r.Id
	}
	for oldId, newId := range idMapM {
		m1, mr1, mi2 := convertMenu(menus0[oldId], newId, user, i0, idMapR)
		_, err := m1.Update(tx1)
		if err != nil {
			return err
		}
		err = menus.InsertManyMenuReceipes(tx1, mr1...)
		if err != nil {
			return err
		}
		err = menus.InsertManyMenuIngredients(tx1, mi2...)
		if err != nil {
			return err
		}
	}

	err = tx1.Commit()

	return err
}
