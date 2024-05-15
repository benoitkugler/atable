package order

import (
	"bytes"
	"fmt"
	"sort"
	"strings"

	lib "github.com/benoitkugler/atable/controllers/library"
	men "github.com/benoitkugler/atable/sql/menus"
	ord "github.com/benoitkugler/atable/sql/orders"
	"github.com/benoitkugler/atable/sql/sejours"
	"github.com/benoitkugler/atable/utils"
	"github.com/xuri/excelize/v2"
)

type IngredientMapping map[men.IdIngredient]ord.IdSupplier

// use ingredient categories instead of real suppliers
func ingredientKindMapping(ings []IngredientQuantities) (ord.Suppliers, IngredientMapping) {
	suppliers := ord.Suppliers{}
	for c := men.I_Empty; c <= men.I_Boulangerie; c++ {
		id := ord.IdSupplier(c)
		suppliers[id] = ord.Supplier{Id: id, Name: c.String()}
	}

	mapping := make(IngredientMapping)
	for _, ing := range ings {
		idSupplier := ord.IdSupplier(ing.Ingredient.Kind)
		mapping[ing.Ingredient.Id] = idSupplier
	}

	return suppliers, mapping
}

type exportExcel struct {
	CompileIngredientsOut
	sejour    sejours.Sejour
	suppliers ord.Suppliers
	mapping   IngredientMapping
}

type sheet struct {
	name string
	list []IngredientQuantities
	key  int // used to sort
}

// including the ingredients without supplier
func (ee exportExcel) perSupplierSheets() []sheet {
	bySupplier := map[ord.IdSupplier][]IngredientQuantities{}
	for _, ing := range ee.Ingredients {
		idSupplier, ok := ee.mapping[ing.Ingredient.Id]
		if !ok {
			idSupplier = -1
		}
		bySupplier[idSupplier] = append(bySupplier[idSupplier], ing)
	}
	out := make([]sheet, 0, len(bySupplier))
	for idSupplier, list := range bySupplier {
		sort.Slice(list, func(i, j int) bool { return list[i].Ingredient.Name < list[j].Ingredient.Name })

		name := "Sans fournisseur"
		if idSupplier != -1 {
			sup := ee.suppliers[idSupplier]
			name = sup.Name
		}
		out = append(out, sheet{key: int(idSupplier), name: name, list: list})
	}

	sort.Slice(out, func(i, j int) bool { return out[i].key < out[j].key })

	return out
}

func (ee exportExcel) perDaySheets() []sheet {
	byDay := map[int]map[men.Ingredient][]QuantityMeal{} // per day offset
	for _, item := range ee.Ingredients {
		for _, use := range item.Quantities {
			day := ee.Meals[use.Origin].Jour
			if byDay[day] == nil { // initialize map
				byDay[day] = make(map[men.Ingredient][]QuantityMeal)
			}
			mapDay := byDay[day]
			mapDay[item.Ingredient] = append(mapDay[item.Ingredient], use)
		}
	}

	out := make([]sheet, 0, len(byDay))
	for day, m := range byDay {
		var list []IngredientQuantities
		for ing, qu := range m {
			list = append(list, IngredientQuantities{Ingredient: ing, Quantities: qu})
		}
		// sort by supplier then name
		sort.Slice(list, func(i, j int) bool { return list[i].Ingredient.Name < list[j].Ingredient.Name })
		sort.SliceStable(list, func(i, j int) bool { return ee.mapping[list[i].Ingredient.Id] < ee.mapping[list[j].Ingredient.Id] })

		out = append(out, sheet{key: day, name: utils.FormatDate(ee.sejour.DayAt(day)), list: list})
	}

	sort.Slice(out, func(i, j int) bool { return out[i].key < out[j].key })
	return out
}

func (exportExcel) formatQuantities(qus []lib.Quantity) string {
	chunks := make([]string, len(qus))
	for i, qu := range qus {
		chunks[i] = qu.String()
	}
	return strings.Join(chunks, " et ")
}

type styleSpec struct {
	greyBg       bool
	borderTop    bool
	borderBottom bool
	small        bool
}

type cursor struct {
	*excelize.File

	styles map[styleSpec]int
}

func newCursor() (cursor, error) {
	f := excelize.NewFile()

	styles := make(map[styleSpec]int)
	for _, grey := range [2]bool{true, false} {
		for _, borderTop := range [2]bool{true, false} {
			for _, borderBottom := range [2]bool{true, false} {
				for _, small := range [2]bool{true, false} {
					spec := styleSpec{grey, borderTop, borderBottom, small}

					excelStyle := &excelize.Style{}
					if small {
						excelStyle.Font = &excelize.Font{Italic: true, Size: 8}
					}
					if grey {
						excelStyle.Fill = excelize.Fill{Type: "pattern", Color: []string{"EFEFEF"}, Pattern: 1}
					}
					if borderTop {
						excelStyle.Border = append(excelStyle.Border, excelize.Border{Type: "top", Color: "000000", Style: 1})
					}
					if borderBottom {
						excelStyle.Border = append(excelStyle.Border, excelize.Border{Type: "bottom", Color: "000000", Style: 1})
					}

					style, err := f.NewStyle(excelStyle)
					if err != nil {
						return cursor{}, err
					}
					styles[spec] = style
				}
			}
		}
	}

	return cursor{f, styles}, nil
}

func (ee exportExcel) fillSheet(f cursor, sheetName string, ingredients []IngredientQuantities, showSupplierCol bool) {
	const colWith = 30
	f.SetCellStr(sheetName, "A1", "Ingrédient")
	f.SetCellStr(sheetName, "B1", "Quantité")
	if showSupplierCol {
		f.SetCellStr(sheetName, "C1", "Fournisseur")
	}

	f.SetColWidth(sheetName, "A", "C", colWith)

	row := 2
	for i, ing := range ingredients {
		greyBg := i%2 == 0

		// add the total
		f.SetCellStr(sheetName, fmt.Sprintf("A%d", row), ing.Ingredient.Name)
		f.SetCellStr(sheetName, fmt.Sprintf("B%d", row), ee.formatQuantities(ing.total()))
		f.SetCellStyle(sheetName, fmt.Sprintf("A%d", row), fmt.Sprintf("B%d", row), f.styles[styleSpec{greyBg: greyBg, borderTop: true, borderBottom: len(ing.Quantities) == 1}])
		// add the supplier
		if idSupplier, ok := ee.mapping[ing.Ingredient.Id]; showSupplierCol && ok {
			sup := ee.suppliers[idSupplier]
			f.SetCellStr(sheetName, fmt.Sprintf("C%d", row), sup.Name)
		}
		row++

		// and add the sub totals, when needed
		if len(ing.Quantities) >= 2 {
			for j, mealQu := range ing.Quantities {
				meal := ee.Meals[mealQu.Origin]
				f.SetCellStr(sheetName, fmt.Sprintf("A%d", row), fmt.Sprintf("%s - %s", utils.FormatDate(ee.sejour.DayAt(meal.Jour)), meal.Horaire.String()))
				f.SetCellStr(sheetName, fmt.Sprintf("B%d", row), ee.formatQuantities([]lib.Quantity{mealQu.Quantity}))
				f.SetCellStyle(sheetName, fmt.Sprintf("A%d", row), fmt.Sprintf("B%d", row), f.styles[styleSpec{greyBg: greyBg, small: true, borderBottom: j == len(ing.Quantities)-1}])
				row++
			}
		}
	}
}

func (ee exportExcel) ToExcel() (*bytes.Buffer, error) {
	const (
		summaryName = "Tous les fournisseurs"
	)
	f, err := newCursor()
	if err != nil {
		return nil, err
	}

	// create a summary ...
	total := ee.Ingredients
	sort.Slice(total, func(i, j int) bool { return total[i].Ingredient.Name < total[j].Ingredient.Name })
	sort.SliceStable(total, func(i, j int) bool { return ee.mapping[total[i].Ingredient.Id] < ee.mapping[total[j].Ingredient.Id] })
	err = f.SetSheetName("Sheet1", summaryName)
	if err != nil {
		return nil, err
	}
	ee.fillSheet(f, summaryName, total, true)

	// ... one sheet per supplier ...
	for _, sheet := range ee.perSupplierSheets() {
		_, err = f.NewSheet(sheet.name)
		if err != nil {
			return nil, err
		}
		ee.fillSheet(f, sheet.name, sheet.list, false)
	}

	// ... and one sheet per days ...
	for _, sheet := range ee.perDaySheets() {
		_, err = f.NewSheet(sheet.name)
		if err != nil {
			return nil, err
		}
		ee.fillSheet(f, sheet.name, sheet.list, true)
	}

	out, err := f.WriteToBuffer()
	if err != nil {
		return nil, fmt.Errorf("creating excel file: %s", err)
	}
	_ = f.Close()

	return out, nil
}
