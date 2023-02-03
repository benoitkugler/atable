package main

import (
	"github.com/benoitkugler/atable/server/server"
	"github.com/labstack/echo/v4"
)

func main() {
	e := echo.New()
	// this prints detailed error messages
	e.HTTPErrorHandler = func(err error, c echo.Context) {
		err = echo.NewHTTPError(400, err.Error())
		e.DefaultHTTPErrorHandler(err, c)
	}

	ct := server.NewController()

	e.PUT("/api/session", ct.CreateSession)
	e.GET("/api/session", ct.GetSession)
	e.POST("/api/session", ct.UpdateSession)

	adress := "localhost:1323"
	e.Logger.Fatal(e.Start(adress))
}
