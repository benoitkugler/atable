package menus

import (
	"math/rand"
	"time"

	"github.com/benoitkugler/atable/sql/users"
)

// Code generated by gomacro/generator/go/randdata. DO NOT EDIT.

func randIdIngredient() IdIngredient {
	return IdIngredient(randint64())
}

func randIdMenu() IdMenu {
	return IdMenu(randint64())
}

func randIdReceipe() IdReceipe {
	return IdReceipe(randint64())
}

func randIngredient() Ingredient {
	var s Ingredient
	s.Id = randIdIngredient()
	s.Name = randstring()
	s.Kind = randIngredientKind()
	s.Owner = randuse_IdUser()

	return s
}

func randIngredientKind() IngredientKind {
	choix := [...]IngredientKind{I_Empty, I_Legumes, I_Feculents, I_Viandes, I_Epicerie, I_Laitages, I_Boulangerie}
	i := rand.Intn(len(choix))
	return choix[i]
}

func randMenu() Menu {
	var s Menu
	s.Id = randIdMenu()
	s.Owner = randuse_IdUser()
	s.IsFavorite = randbool()
	s.IsPublished = randbool()
	s.Updated = randTime()

	return s
}

func randMenuIngredient() MenuIngredient {
	var s MenuIngredient
	s.IdMenu = randIdMenu()
	s.IdIngredient = randIdIngredient()
	s.Quantity = randQuantityR()
	s.Plat = randPlatKind()

	return s
}

func randMenuReceipe() MenuReceipe {
	var s MenuReceipe
	s.IdMenu = randIdMenu()
	s.IdReceipe = randIdReceipe()

	return s
}

func randPlatKind() PlatKind {
	choix := [...]PlatKind{P_Empty, P_Dessert, P_PlatPrincipal, P_Entree}
	i := rand.Intn(len(choix))
	return choix[i]
}

func randQuantityR() QuantityR {
	var s QuantityR
	s.Val = randfloat64()
	s.Unite = randUnite()
	s.For = randint()

	return s
}

func randReceipe() Receipe {
	var s Receipe
	s.Id = randIdReceipe()
	s.Owner = randuse_IdUser()
	s.Plat = randPlatKind()
	s.Name = randstring()
	s.Description = randstring()
	s.IsPublished = randbool()
	s.Updated = randTime()

	return s
}

func randReceipeIngredient() ReceipeIngredient {
	var s ReceipeIngredient
	s.IdReceipe = randIdReceipe()
	s.IdIngredient = randIdIngredient()
	s.Quantity = randQuantityR()

	return s
}

func randTime() Time {
	return Time(randtTime())
}

func randUnite() Unite {
	choix := [...]Unite{U_Piece, U_Kg, U_G, U_L, U_CL}
	i := rand.Intn(len(choix))
	return choix[i]
}

func randbool() bool {
	i := rand.Int31n(2)
	return i == 1
}

func randfloat64() float64 {
	return rand.Float64() * float64(rand.Int31())
}

func randint() int {
	return int(rand.Intn(1000000))
}

func randint64() int64 {
	return int64(rand.Intn(1000000))
}

var letterRunes2 = []rune("azertyuiopqsdfghjklmwxcvbn123456789é@!?&èïab ")

func randstring() string {
	b := make([]rune, 10)
	maxLength := len(letterRunes2)
	for i := range b {
		b[i] = letterRunes2[rand.Intn(maxLength)]
	}
	return string(b)
}

func randtTime() time.Time {
	return time.Unix(int64(rand.Int31()), 5)
}

func randuse_IdUser() users.IdUser {
	return users.IdUser(randint64())
}
