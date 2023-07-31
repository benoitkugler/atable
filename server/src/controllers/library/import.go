package library

import (
	"database/sql"
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/benoitkugler/atable/controllers/users"
	men "github.com/benoitkugler/atable/sql/menus"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

// This file implements import of receipes from a
// CSV file

type IngredientI struct {
	Name     string
	Quantity float64
	Unite    men.Unite
}

type ReceipeI struct {
	Name string
	For  int
	Plat men.PlatKind

	Ingredients []IngredientI
}

// return a default value on invalid input
func parsePlatKind(s string) men.PlatKind {
	switch s {
	case "entree":
		return men.P_Entree
	case "platPrincipal":
		return men.P_PlatPrincipal
	case "dessert":
		return men.P_Dessert
	default:
		return men.P_Empty
	}
}

func parseUnite(word string, quantite float64) (float64, men.Unite) {
	switch strings.ToLower(word) {
	case "kg":
		return quantite, men.U_Kg
	case "gr", "g":
		return quantite, men.U_G
	case "l":
		return quantite, men.U_L
	case "cl":
		return quantite, men.U_CL
	case "ml":
		return quantite / 10, men.U_CL
	default:
		return quantite, men.U_Piece
	}
}

type csvImporter []ReceipeI

// newCSVImporter parses a .CSV file following this format
//   - each receipe is a three-column list of
//     nom de l'ingrédient, quantité, unité
//   - one header row starts a receipe : nom, empty, nombre de personnes
//   - at least one empty row must divides two receipes
func newCSVImporter(content io.Reader) (csvImporter, error) {
	r := csv.NewReader(content)
	r.FieldsPerRecord = 3
	rows, err := r.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("Fichier CSV invalide: %s", err)
	}

	var (
		receipes       csvImporter
		inReceipe      = false
		currentReceipe ReceipeI
	)
	for _, row := range rows {
		// len(row) == 3
		c1 := strings.TrimSpace(row[0])
		c2 := strings.TrimSpace(row[1])
		c3 := strings.TrimSpace(row[2])
		isComment := c2 == "" && c3 == ""
		isEmpty := c1 == "" && isComment
		if isEmpty || isComment { // ignore empty lines
			inReceipe = false
			continue
		}

		if !inReceipe {
			// header : add the accumulated receipe...
			if len(currentReceipe.Ingredients) != 0 {
				receipes = append(receipes, currentReceipe)
			}

			// ... and start a new one
			plat := parsePlatKind(c2)
			nbPersonnes, err := strconv.Atoi(c3)
			if err != nil {
				return nil, fmt.Errorf("Nombre de personnes illisible: %s", err)
			}
			currentReceipe = ReceipeI{c1, nbPersonnes, plat, nil}
			inReceipe = true
		} else {
			// we have an ingredient
			name := utils.UpperFirst(c1)
			// accept numbers with comma
			quantiteRaw, err := strconv.ParseFloat(strings.ReplaceAll(c2, ",", "."), 64)
			if err != nil {
				return nil, fmt.Errorf("Quantité illisible: %s", err)
			}
			quantite, unite := parseUnite(c3, quantiteRaw)
			currentReceipe.Ingredients = append(currentReceipe.Ingredients, IngredientI{name, quantite, unite})
		}
	}

	// flush the last receipe
	if len(currentReceipe.Ingredients) != 0 {
		receipes = append(receipes, currentReceipe)
	}

	receipes.normalizeIngredients()

	return receipes, nil
}

// allNames returns the ingredient names used in the current receipes
func (l csvImporter) allNames() map[string]bool {
	out := map[string]bool{}
	for _, r := range l {
		for _, ing := range r.Ingredients {
			out[ing.Name] = true
		}
	}
	return out
}

// normalizeIngredients update ingredients name to enforce conventions
func (l csvImporter) normalizeIngredients() {
	allNames := l.allNames()

	for _, receipe := range l {
		for i, ing := range receipe.Ingredients {
			n := ing.Name
			if !strings.HasSuffix(n, "s") && allNames[n+"s"] {
				// enfore plural
				receipe.Ingredients[i].Name = n + "s"
			}
		}
	}
}

// bestMatchNames search for the best match among [candidates], for each input
// in [toMatch]
// it panics if [candidates] is empty
func bestMatchNames(candidates men.Ingredients, toMatch map[string]bool) map[string]men.Ingredient {
	out := make(map[string]men.Ingredient, len(toMatch))
	for key := range toMatch {
		bestIngredient := candidates[0]
		var bestScore []int // empty score is always worse than other non empty score

		for _, ingredient := range candidates {
			newScore := scores(key, ingredient.Name)
			if isScoreBetter(newScore, bestScore) {
				bestScore = newScore
				bestIngredient = ingredient
			}
		}

		out[key] = bestIngredient
	}
	return out
}

func words(name string) []string {
	chunks := strings.Split(name, " ")
	filteredLength := 0
	for _, s := range chunks {
		s = utils.Normalize(s)
		if len(s) >= 3 {
			chunks[filteredLength] = s
			filteredLength++
		}
	}
	return chunks[:filteredLength]
}

// return the a distance for each "common" word
func scores(n1, n2 string) []int {
	w1 := words(n1)
	w2 := words(n2)

	// find the best matching

	if len(w1) > len(w2) {
		w2, w1 = w1, w2 // reverse w1 and w2
	}

	out := make([]int, len(w1))
	for index, s1 := range w1 {
		// find the best score
		min := math.MaxInt
		for _, s2 := range w2 {
			if d := levenshtein(s1, s2); d < min {
				min = d
			}
		}
		out[index] = min
	}
	return out
}

// return true if ref < other (less is best)
func isScoreBetter(ref, other []int) bool {
	for i := 0; i < min(len(ref), len(other)); i++ {
		if ref[i] < other[i] {
			return true
		}
		if ref[i] > other[i] {
			return false
		}
	}
	return len(ref) > len(other)
}

// Levenshtein algorithm implementation based on:
// http://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
func levenshtein(s_, t_ string) int {
	if s_ == t_ {
		return 0
	}
	s, t := []rune(s_), []rune(t_)

	if s_ == "" {
		return len(t)
	}
	if t_ == "" {
		return len(s)
	}

	v0 := make([]int, len(t)+1)
	v1 := make([]int, len(t)+1)

	for i := range v0 {
		v0[i] = i
	}

	for i := range s {
		v1[0] = i + 1

		for j := range t {
			cost := 1
			if s[i] == t[j] {
				cost = 0
			}
			v1[j+1] = min(v1[j]+1, min(v0[j+1]+1, v0[j]+cost))
		}

		for j := range v0 {
			v0[j] = v1[j]
		}
	}

	return v1[len(t)]
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// ---------------------- API endpoint ---------------------------

type ImportReceipes1Out struct {
	Receipes []ReceipeI

	Map map[string]men.Ingredient
}

// LibraryImportReceipes1 performs the first step of importing a CSV files
// containing receipes.
func (ct *Controller) LibraryImportReceipes1(c echo.Context) error {
	// Source
	file, err := c.FormFile("file")
	if err != nil {
		return err
	}
	src, err := file.Open()
	if err != nil {
		return err
	}
	defer src.Close()

	out, err := ct.importCSV1(src)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) importCSV1(csvFile io.Reader) (ImportReceipes1Out, error) {
	importer, err := newCSVImporter(csvFile)
	if err != nil {
		return ImportReceipes1Out{}, err
	}

	// match against known ingredients
	ingredients, err := men.SelectAllIngredients(ct.db)
	if err != nil {
		return ImportReceipes1Out{}, utils.SQLError(err)
	}

	if len(ingredients) == 0 {
		return ImportReceipes1Out{}, errors.New("internal error: empty 'ingredients' table")
	}

	initialMap := bestMatchNames(ingredients, importer.allNames())

	return ImportReceipes1Out{Receipes: importer, Map: initialMap}, nil
}

// Ingredient with Id == -1 will be created
type ImportReceipes2In = ImportReceipes1Out

// LibraryImportReceipes2 validate the import, creating the required
// ingredients and adding the given receipes.
func (ct *Controller) LibraryImportReceipes2(c echo.Context) error {
	uID := users.JWTUser(c)

	var args ImportReceipes2In
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.importCSV2(args, uID)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) importCSV2(args ImportReceipes2In, uID us.IdUser) ([]ReceipeExt, error) {
	var (
		newReceipes []ReceipeExt
		err         error
	)
	err = ct.inTx(func(tx *sql.Tx) error {
		// Step 1 : add the new ingredients,
		// and uniquify ingredients with same name
		newIngredientsByName := map[string]men.Ingredient{}
		for key, ingredient := range args.Map {
			if ingredient.Id == -1 {
				ingredient.Name = utils.UpperFirst(ingredient.Name) // enfore common format
				if ing, has := newIngredientsByName[ingredient.Name]; has {
					ingredient = ing
				} else {
					ingredient, err = ingredient.Insert(tx)
					if err != nil {
						return utils.SQLError(err)
					}
					newIngredientsByName[ingredient.Name] = ingredient
				}
				args.Map[key] = ingredient
			}
		}

		// Step 2 : all ingredients are in the DB:
		// add the receipes and their links
		for _, receipe := range args.Receipes {
			rec, err := men.Receipe{
				Owner:       uID,
				Plat:        receipe.Plat,
				Name:        receipe.Name,
				Description: fmt.Sprintf("Importée le %s", time.Now().Format("02/01/06")),
			}.Insert(tx)
			if err != nil {
				return utils.SQLError(err)
			}

			out := ReceipeExt{
				Receipe:     rec,
				Ingredients: make([]ReceipeIngredientExt, len(receipe.Ingredients)),
			}

			links := make(men.ReceipeItems, len(receipe.Ingredients))
			for i, ing := range receipe.Ingredients {
				quantity := men.QuantityR{Val: ing.Quantity, Unite: ing.Unite, For: receipe.For}
				resolvedIngredient := args.Map[ing.Name]

				links[i] = men.ReceipeItem{
					IdReceipe:    rec.Id,
					IdIngredient: resolvedIngredient.Id,
					Quantity:     quantity,
				}

				out.Ingredients[i] = ReceipeIngredientExt{
					Ingredient: resolvedIngredient,
					Quantity:   quantity,
				}
			}
			err = men.InsertManyReceipeItems(tx, links...)
			if err != nil {
				return utils.SQLError(err)
			}

			newReceipes = append(newReceipes, out)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return newReceipes, err
}
