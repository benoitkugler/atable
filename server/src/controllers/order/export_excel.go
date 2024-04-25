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

func (ee exportExcel) sheetName(id ord.IdSupplier) string {
	if id == -1 {
		return "Sans fournisseur"
	}
	sup := ee.suppliers[id]
	return fmt.Sprintf("%s (%d)", sup.Name, sup.Id)
}

type supplierSheet struct {
	ord.IdSupplier // -1 for not associated
	list           []IngredientQuantities
}

// including the ingredients without supplier
func (ee exportExcel) supplierSheets() []supplierSheet {
	bySupplier := map[ord.IdSupplier][]IngredientQuantities{}
	for _, ing := range ee.Ingredients {
		idSupplier, ok := ee.mapping[ing.Ingredient.Id]
		if !ok {
			idSupplier = -1
		}
		bySupplier[idSupplier] = append(bySupplier[idSupplier], ing)
	}
	out := make([]supplierSheet, 0, len(bySupplier))
	for idSupplier, list := range bySupplier {
		sort.Slice(list, func(i, j int) bool { return list[i].Ingredient.Name < list[j].Ingredient.Name })

		out = append(out, supplierSheet{IdSupplier: idSupplier, list: list})
	}

	sort.Slice(out, func(i, j int) bool { return out[i].IdSupplier < out[j].IdSupplier })

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
						excelStyle.Fill = excelize.Fill{Type: "pattern", Color: []string{"DDDDDD"}, Pattern: 1}
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

func (ee exportExcel) fillSheet(f cursor, sName string, sheet supplierSheet, showSupplierCol bool) {
	const colWith = 30
	f.SetCellStr(sName, "A1", "Ingrédient")
	f.SetCellStr(sName, "B1", "Quantité")
	if showSupplierCol {
		f.SetCellStr(sName, "C1", "Fournisseur")
	}

	f.SetColWidth(sName, "A", "C", colWith)

	row := 2
	for i, ing := range sheet.list {
		greyBg := i%2 == 0

		// add the total
		f.SetCellStr(sName, fmt.Sprintf("A%d", row), ing.Ingredient.Name)
		f.SetCellStr(sName, fmt.Sprintf("B%d", row), ee.formatQuantities(ing.total()))
		f.SetCellStyle(sName, fmt.Sprintf("A%d", row), fmt.Sprintf("B%d", row), f.styles[styleSpec{greyBg: greyBg, borderTop: true, borderBottom: len(ing.Quantities) == 1}])
		// add the supplier
		if idSupplier, ok := ee.mapping[ing.Ingredient.Id]; showSupplierCol && ok {
			sup := ee.suppliers[idSupplier]
			f.SetCellStr(sName, fmt.Sprintf("C%d", row), sup.Name)
		}
		row++

		// and add the sub totals, when needed
		if len(ing.Quantities) >= 2 {
			for j, mealQu := range ing.Quantities {
				meal := ee.Meals[mealQu.Origin]
				f.SetCellStr(sName, fmt.Sprintf("A%d", row), fmt.Sprintf("%s - %s", utils.FormatDate(ee.sejour.DayAt(meal.Jour)), meal.Horaire.String()))
				f.SetCellStr(sName, fmt.Sprintf("B%d", row), ee.formatQuantities([]lib.Quantity{mealQu.Quantity}))
				f.SetCellStyle(sName, fmt.Sprintf("A%d", row), fmt.Sprintf("B%d", row), f.styles[styleSpec{greyBg: greyBg, small: true, borderBottom: j == len(ing.Quantities)-1}])
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

	supplierSheets := ee.supplierSheets()

	// create a summary ...
	f.SetSheetName("Sheet1", summaryName)

	sort.Slice(ee.Ingredients, func(i, j int) bool { return ee.Ingredients[i].Ingredient.Name < ee.Ingredients[j].Ingredient.Name })
	ee.fillSheet(f, summaryName, supplierSheet{IdSupplier: -1, list: ee.Ingredients}, true)

	// ... and one sheet per supplier
	for _, supplier := range supplierSheets {
		sName := ee.sheetName(supplier.IdSupplier)
		f.NewSheet(sName)

		ee.fillSheet(f, sName, supplier, false)
	}

	out, err := f.WriteToBuffer()
	if err != nil {
		return nil, fmt.Errorf("creating excel file: %s", err)
	}
	_ = f.Close()

	return out, nil
}
