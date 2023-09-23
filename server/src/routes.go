package main

import (
	"github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/controllers/order"
	"github.com/benoitkugler/atable/controllers/sejours"
	"github.com/benoitkugler/atable/controllers/users"

	"github.com/labstack/echo/v4"
)

func setupWebAPI(e *echo.Echo, tvc *users.Controller, sej *sejours.Controller, lib *library.Controller,
	ord *order.Controller,
) {
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

	gr.GET("/api/meals", sej.MealsLoadDay)
	gr.GET("/api/meals-all", sej.MealsLoadAll)
	gr.PUT("/api/meals/wizzard", sej.MealsWizzard)
	gr.GET("/api/meals/search", sej.MealsSearch)
	gr.GET("/api/meals/quantities", sej.MealsPreviewQuantities)
	gr.PUT("/api/meals/details", sej.MealsCreate)
	gr.POST("/api/meals/details", sej.MealsUpdate)
	gr.DELETE("/api/meals/details", sej.MealsDelete)
	gr.POST("/api/meals/groups", sej.MealsMoveGroup)
	gr.PUT("/api/meals/ingredients", sej.MealsAddIngredient)
	gr.POST("/api/meals/ingredients", sej.MealsUpdateMenuIngredient)
	gr.PUT("/api/meals/receipes", sej.MealsAddReceipe)
	gr.POST("/api/meals/remove", sej.MealsRemoveItem)
	gr.POST("/api/meals/menus", sej.MealsSetMenu)
	gr.POST("/api/meals/swap", sej.MealsSwapMenus)

	gr.GET("/api/library/all-ingredients", lib.LibraryLoadIngredients)
	gr.PUT("/api/library/all-ingredients", lib.LibraryCreateIngredient)
	gr.GET("/api/library/all-receipes", lib.LibraryLoadReceipes)

	gr.POST("/api/library/all-ingredients", lib.LibraryUpdateIngredient)
	gr.DELETE("/api/library/all-ingredients", lib.LibraryDeleteIngredient)

	gr.POST("/api/library/receipes/import", lib.LibraryImportReceipes1)
	gr.PUT("/api/library/receipes/import", lib.LibraryImportReceipes2)

	gr.GET("/api/library/menus", lib.LibraryLoadMenu)
	gr.PUT("/api/library/menus", lib.LibraryCreateMenu)
	gr.POST("/api/library/menus", lib.LibraryUpdateMenu)
	gr.DELETE("/api/library/menus", lib.LibraryDeleteMenu)
	gr.GET("/api/library/receipes", lib.LibraryLoadReceipe)
	gr.PUT("/api/library/receipes", lib.LibraryCreateReceipe)
	gr.POST("/api/library/receipes", lib.LibraryUpdateReceipe)
	gr.DELETE("/api/library/receipes", lib.LibraryDeleteReceipe)
	gr.PUT("/api/library/receipes/ingredients", lib.LibraryAddReceipeIngredient)
	gr.POST("/api/library/receipes/ingredients", lib.LibraryUpdateReceipeIngredient)
	gr.DELETE("/api/library/receipes/ingredients", lib.LibraryDeleteReceipeIngredient)

	gr.PUT("/api/library/menus/ingredients", lib.LibraryAddMenuIngredient)
	gr.POST("/api/library/menus/ingredients", lib.LibraryUpdateMenuIngredient)
	gr.DELETE("/api/library/menus/ingredients", lib.LibraryDeleteMenuIngredient)
	gr.PUT("/api/library/menus/receipes", lib.LibraryAddMenuReceipe)
	gr.DELETE("/api/library/menus/receipes", lib.LibraryDeleteMenuReceipe)

	gr.GET("/api/order/days", ord.OrderGetDays)
	gr.POST("/api/order/ingredients", ord.OrderCompileIngredients)

	gr.GET("/api/order/profiles", ord.OrderGetProfiles)
	gr.PUT("/api/order/profiles", ord.OrderCreateProfile)
	gr.POST("/api/order/profiles", ord.OrderUpdateProfile)
	gr.DELETE("/api/order/profiles", ord.OrderDeleteProfile)

	gr.GET("/api/order/profile/suppliers", ord.OrderLoadProfile)
	gr.PUT("/api/order/profile/suppliers", ord.OrderAddSupplier)
	gr.POST("/api/order/profile/suppliers", ord.OrderUpdateSupplier)
	gr.DELETE("/api/order/profile/suppliers", ord.OrderDeleteSupplier)

	gr.POST("/api/order/profile/map", ord.OrderUpdateProfileMap)
	gr.POST("/api/order/profile/default-map", ord.OrderGetDefaultMapping)
	gr.POST("/api/order/profile/default", ord.OrderSetDefaultProfile)
	gr.POST("/api/order/export", ord.OrderExportExcel)
}
