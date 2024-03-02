package sejours

import (
	"bytes"
	_ "embed"
	"fmt"
	"html/template"
	"sort"

	"github.com/benoitkugler/atable/controllers/library"
	men "github.com/benoitkugler/atable/sql/menus"
	sej "github.com/benoitkugler/atable/sql/sejours"
	"github.com/benoitkugler/atable/sql/users"
	ut "github.com/benoitkugler/atable/utils"
	goweasyprint "github.com/benoitkugler/go-weasyprint"
	"github.com/benoitkugler/webrender/text"
	"github.com/benoitkugler/webrender/utils"
)

// export a pdf document containing receipe for one (or many) meals

//go:embed cookbook.html
var src string

var cookbookTemplate *template.Template

func init() {
	cookbookTemplate = template.Must(template.New("").Parse(src))
}

type cookbookData struct {
	Sejour string
	Pages  []cookbookPage
}

// for one Meal, on one page
type cookbookPage struct {
	meal sej.Meal

	Date        string
	Horaire     string
	NbPersonnes int
	Receipes    []cookbookReceipe
}

type ingQuantite struct {
	Name     string
	Quantite string
}

func resolveFormat(qu men.QuantityR, forNb int) string {
	return library.Quantity{Unite: qu.Unite, Val: qu.ResolveFor(forNb)}.String()
}

type cookbookReceipe struct {
	plat        men.PlatKind
	Title       string
	Ingredients []ingQuantite
	Comments    string // optional
}

func newCookbookReceipe(rec library.ReceipeExt, forNb int) cookbookReceipe {
	ings := make([]ingQuantite, len(rec.Ingredients))
	for i, ing := range rec.Ingredients {
		ings[i] = ingQuantite{
			Name:     ing.Name,
			Quantite: resolveFormat(ing.Quantity, forNb),
		}
	}
	return cookbookReceipe{
		plat:        rec.Receipe.Plat,
		Title:       rec.Receipe.Name,
		Comments:    rec.Receipe.Description,
		Ingredients: ings,
	}
}

func newCookbookReceipeFromPlat(plat men.PlatKind, ingredients []library.MenuIngredientExt, forNb int) cookbookReceipe {
	ings := make([]ingQuantite, len(ingredients))
	for i, ing := range ingredients {
		ings[i] = ingQuantite{
			Name:     ing.Ingredient.Name,
			Quantite: resolveFormat(ing.Quantity, forNb),
		}
	}
	return cookbookReceipe{
		plat:        plat,
		Title:       plat.String(),
		Comments:    "",
		Ingredients: ings,
	}
}

func buildCookbook(pages cookbookData, fc text.FontConfiguration) ([]byte, error) {
	var buf bytes.Buffer
	err := cookbookTemplate.Execute(&buf, pages)
	if err != nil {
		return nil, fmt.Errorf("internal error creating cookbook HTML: %s", err)
	}

	input := utils.InputString(buf.Bytes())
	buf.Reset()
	err = goweasyprint.HtmlToPdf(&buf, input, fc)
	if err != nil {
		return nil, fmt.Errorf("internal error creating cookbook PDF: %s", err)
	}

	return buf.Bytes(), nil
}

type ExportCookbookIn struct {
	IdSejour sej.IdSejour
	Days     []int // offset of the days to include in the cookbook
}

func (ct *Controller) exportCookbook(args ExportCookbookIn, uID users.IdUser) ([]byte, string, error) {
	sejour, err := ct.checkSejourOwner(args.IdSejour, uID)
	if err != nil {
		return nil, "", err
	}

	meals, err := sej.SelectMealsBySejours(ct.db, sejour.Id)
	if err != nil {
		return nil, "", ut.SQLError(err)
	}
	meals.RestrictByDays(args.Days)

	groups, err := sej.SelectGroupsBySejours(ct.db, sejour.Id)
	if err != nil {
		return nil, "", ut.SQLError(err)
	}
	links, err := sej.SelectMealGroupsByIdMeals(ct.db, meals.IDs()...)
	if err != nil {
		return nil, "", ut.SQLError(err)
	}
	byMeal := links.ByIdMeal()

	// load the menus
	mt, err := library.LoadMenus(ct.db, meals.Menus())
	if err != nil {
		return nil, "", err
	}
	menus, receipes := mt.Compile()

	data := cookbookData{
		Sejour: sejour.Name,
		Pages:  make([]cookbookPage, 0, len(meals)),
	}
	for _, meal := range meals {
		menu := menus[meal.Menu]
		forNb := ResolveSize(byMeal[meal.Id], groups, meal.AdditionalPeople)

		var l []cookbookReceipe
		// format receipe ...
		for _, receipe := range menu.Receipes {
			l = append(l, newCookbookReceipe(receipes[receipe.Id], forNb))
		}
		// ... and group ingredient by plat
		byPlat := map[men.PlatKind][]library.MenuIngredientExt{}
		for _, ing := range menu.Ingredients {
			byPlat[ing.Plat] = append(byPlat[ing.Plat], ing)
		}
		for plat, ings := range byPlat {
			l = append(l, newCookbookReceipeFromPlat(plat, ings, forNb))
		}

		sort.Slice(l, func(i, j int) bool { return l[i].Title < l[j].Title })
		sort.SliceStable(l, func(i, j int) bool { return l[i].plat < l[j].plat })

		data.Pages = append(data.Pages, cookbookPage{
			meal:        meal,
			Date:        ut.FormatDate(sejour.DayAt(meal.Jour)),
			Horaire:     meal.Horaire.String(),
			NbPersonnes: forNb,
			Receipes:    l,
		})
	}

	sort.Slice(data.Pages, func(i, j int) bool {
		return data.Pages[i].meal.Horaire < data.Pages[j].meal.Horaire
	})
	sort.SliceStable(data.Pages, func(i, j int) bool {
		return data.Pages[i].meal.Jour < data.Pages[j].meal.Jour
	})

	bytes, err := buildCookbook(data, ct.fc)
	if err != nil {
		return nil, "", err
	}

	return bytes, fmt.Sprintf("%s Fiches cuisine.pdf", sejour.Name), nil
}
