package main

import (
	"github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/controllers/sejours"
	"github.com/benoitkugler/atable/controllers/users"

	"github.com/labstack/echo/v4"
)

func setupWebAPI(e *echo.Echo, tvc *users.Controller, sej *sejours.Controller, lib *library.Controller) {
	e.POST("/api/inscription", tvc.AskInscription)
	e.GET(users.ValidateInscriptionEndPoint, tvc.ValidateInscription)
	e.POST("/api/loggin", tvc.Loggin)
	e.GET("/api/reset", tvc.UserResetPassword)

	gr := e.Group("", tvc.JWTMiddleware())
	gr.GET("/api/sejours", sej.SejoursGet)
	gr.PUT("/api/sejours", sej.SejoursCreate)
	gr.POST("/api/sejours", sej.SejoursUpdate)
	gr.DELETE("/api/sejours", sej.SejoursDelete)

	gr.PUT("/api/sejours/groups", sej.SejoursCreateGroupe)
	gr.POST("/api/sejours/groups", sej.SejoursUpdateGroupe)
	gr.DELETE("/api/sejours/groups", sej.SejoursDeleteGroupe)

	gr.GET("/api/meals", sej.MealsGet)
	gr.PUT("/api/meals/wizzard", sej.MealsWizzard)
	gr.GET("/api/meals/search", sej.MealsSearch)
	gr.GET("/api/meals/group", sej.MealsLoadForGroup)
	gr.GET("/api/meals/details", sej.MealsLoad)
	gr.GET("/api/meals/details-one", sej.MealsPreview)
	gr.PUT("/api/meals/details", sej.MealsCreate)
	gr.POST("/api/meals/details", sej.MealsUpdate)
	gr.DELETE("/api/meals/details", sej.MealsDelete)
	gr.POST("/api/meals/groups", sej.MealsMoveGroup)
	gr.PUT("/api/meals/ingredients", sej.MealsAddIngredient)
	gr.POST("/api/meals/ingredients", sej.MealsUpdateMenuIngredient)
	gr.PUT("/api/meals/receipes", sej.MealsAddReceipe)
	gr.POST("/api/meals/remove", sej.MealsRemoveItem)
	gr.POST("/api/meals/menus", sej.MealsSetMenu)

	gr.GET("/api/library/all-ingredients", lib.LibraryLoadIngredients)
	gr.PUT("/api/library/all-ingredients", lib.LibraryCreateIngredient)
	gr.GET("/api/library/all-receipes", lib.LibraryLoadReceipes)

	gr.POST("/api/library/receipes/import", lib.LibraryImportReceipes1)
	gr.PUT("/api/library/receipes/import", lib.LibraryImportReceipes2)

	gr.GET("/api/library/menus", lib.LibraryLoadMenu)
	gr.PUT("/api/library/menus", lib.LibraryCreateMenu)
	gr.GET("/api/library/receipes", lib.LibraryLoadReceipe)
	gr.PUT("/api/library/receipes", lib.LibraryCreateReceipe)
	gr.POST("/api/library/receipes", lib.LibraryUpdateReceipe)
	gr.PUT("/api/library/receipes/ingredients", lib.LibraryAddReceipeIngredient)
	gr.POST("/api/library/receipes/ingredients", lib.LibraryUpdateReceipeIngredient)
	gr.DELETE("/api/library/receipes/ingredients", lib.LibraryDeleteReceipeIngredient)

	gr.PUT("/api/library/menus/ingredients", lib.LibraryAddMenuIngredient)
	gr.POST("/api/library/menus/ingredients", lib.LibraryUpdateMenuIngredient)
	gr.DELETE("/api/library/menus/ingredients", lib.LibraryDeleteMenuIngredient)
	gr.PUT("/api/library/menus/receipes", lib.LibraryAddMenuReceipe)
	gr.DELETE("/api/library/menus/receipes", lib.LibraryDeleteMenuReceipe)
}
