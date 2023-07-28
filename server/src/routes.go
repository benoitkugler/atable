package main

import (
	"github.com/benoitkugler/atable/controllers/sejours"
	"github.com/benoitkugler/atable/controllers/users"

	"github.com/labstack/echo/v4"
)

func setupWebAPI(e *echo.Echo, tvc *users.Controller, sej *sejours.Controller) {
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
}
