package sejours

import (
	"bytes"
	"os"
	"testing"

	"github.com/benoitkugler/atable/sql/sejours"
	tu "github.com/benoitkugler/atable/utils/testutils"
)

func TestCookbook(t *testing.T) {
	data := cookbookData{
		Sejour: "C2",
		Pages: []cookbookPage{
			{
				Date:        "ven. 2 avril",
				Horaire:     sejours.Gouter.String(),
				NbPersonnes: 50,
				Receipes: []cookbookReceipe{
					{
						Title: "Entrée", Comments: "", Ingredients: []ingQuantite{
							{Name: "Comcome", Quantite: "3kg"},
							{Name: "Sel", Quantite: "3kg"},
							{Name: "Tomates", Quantite: "3kg"},
							{Name: "Avec accent : é à ", Quantite: "3kg"},
						},
					},
					{
						Title: "Poulet curry", Comments: "Une super recette!", Ingredients: []ingQuantite{
							{Name: "Tomates", Quantite: "3kg"},
							{Name: "Tomates", Quantite: "3kg"},
							{Name: "Tomates", Quantite: "3kg"},
						},
					},
					{
						Title: "Autre", Comments: "", Ingredients: []ingQuantite{
							{Name: "Jus d'orange", Quantite: "3L"},
						},
					},
				},
			},
			{},
		},
	}
	var b bytes.Buffer
	err := cookbookTemplate.Execute(&b, data)
	tu.AssertNoErr(t, err)

	err = os.WriteFile("test/cookbook.html", b.Bytes(), os.ModePerm)
	tu.AssertNoErr(t, err)

	var ct Controller
	err = ct.LoadFontconfig()
	tu.AssertNoErr(t, err)
	pdf, err := buildCookbook(data, ct.fc)
	tu.AssertNoErr(t, err)

	err = os.WriteFile("test/cookbook.pdf", pdf, os.ModePerm)
	tu.AssertNoErr(t, err)
}
