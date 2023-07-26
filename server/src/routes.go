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
}
