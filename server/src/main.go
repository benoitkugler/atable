package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/benoitkugler/atable/controllers/library"
	"github.com/benoitkugler/atable/controllers/sejours"
	shopsession "github.com/benoitkugler/atable/controllers/shop-session"
	"github.com/benoitkugler/atable/controllers/users"
	"github.com/benoitkugler/atable/mailer"
	"github.com/benoitkugler/atable/pass"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

//go:generate /home/benoit/go/src/github.com/benoitkugler/gomacro/cmd/gomacro gomacro.json

func connectDB(dev bool) (*sql.DB, error) {
	var credentials pass.DB
	if dev {
		credentials = pass.DB{
			Host:     "localhost",
			User:     "benoit",
			Password: "dummy",
			Name:     "intendance_prod",
		}
	} else { // in production, read from env
		var err error
		credentials, err = pass.NewDB()
		if err != nil {
			return nil, err
		}
	}

	db, err := credentials.ConnectPostgres()
	if err != nil {
		return nil, err
	}

	err = db.Ping()
	if err != nil {
		return nil, err
	}

	fmt.Printf("DB configured with %v connected.\n", credentials)

	return db, err
}

func getEncrypter(dev bool) (out pass.Encrypter) {
	if dev {
		return pass.Encrypter{1, 2, 3, 4, 5, 6}
	} else {
		out, err := pass.NewEncrypter("ENC_KEY")
		if err != nil {
			log.Fatal(err)
		}
		return out
	}
}

func devSetup(e *echo.Echo, tc *users.Controller) {
	dev, err := tc.GetDevToken()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(dev)

	// also Cross origin requests
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowMethods:  append(middleware.DefaultCORSConfig.AllowMethods, http.MethodOptions),
		AllowHeaders:  []string{"Authorization", "Content-Type", "Access-Control-Allow-Origin"},
		ExposeHeaders: []string{"Content-Disposition"},
	}))
	fmt.Println("CORS activé.")

	devMail := os.Getenv("DEV_MAIL_TO")
	if devMail == "" {
		log.Fatal("Missing env. variable DEV_MAIL_TO")
	}
	mailer.SetDevMail(devMail)
	fmt.Println("Mail redirected to ", devMail)
}

func main() {
	devPtr := flag.Bool("dev", false, "run in dev mode (localhost)")
	dryPtr := flag.Bool("dry", false, "do not listen, but quit early")
	flag.Parse()

	adress := getAdress(*devPtr)
	host := getPublicHost(*devPtr)

	encKey := getEncrypter(*devPtr)
	fmt.Printf("Encrypter setup with key: %v\n", encKey)

	db, err := connectDB(*devPtr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	smtp, err := pass.NewSMTP()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("SMTP configured with %v.\n", smtp)

	uc := users.NewController(db, encKey, smtp, host)
	admin, err := uc.LoadAmin()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Admin teacher loaded.")

	sc := sejours.NewController(db, host, admin, encKey)
	lc := library.NewController(db, admin)
	shopC := shopsession.NewController()

	e := echo.New()
	e.HideBanner = true
	// this prints detailed error messages
	e.HTTPErrorHandler = func(err error, c echo.Context) {
		err = echo.NewHTTPError(400, err.Error())
		e.DefaultHTTPErrorHandler(err, c)
	}

	if *devPtr {
		devSetup(e, uc)
	}

	setupRoutes(e, uc, sc, lc, shopC)

	if *dryPtr {
		// sanityChecks(db, *skipValidation)
		fmt.Println("Setup done, leaving early.")
		return
	} else {
		// go sanityChecks(db, *skipValidation)
		fmt.Println("Setup done (pending sanityChecks)")
	}

	err = e.Start(adress) // start and block
	e.Logger.Fatal(err)   // report error and quit
}

func getPublicHost(dev bool) string {
	if dev {
		return "localhost:1323"
	}
	// use env variable
	host := os.Getenv("PUBLIC_HOST")
	if host == "" {
		log.Fatal("misssing PUBLIC_HOST env variable")
	}
	return host
}

func getAdress(dev bool) string {
	var adress string
	if dev {
		adress = "localhost:1323"
	} else {
		// alwaysdata use IP and PORT env var
		host := os.Getenv("IP")
		port, err := strconv.Atoi(os.Getenv("PORT"))
		if err != nil {
			log.Fatal("No PORT found ", err)
		}
		if strings.Count(host, ":") >= 2 { // ipV6 -> besoin de crochet
			host = "[" + host + "]"
		}
		adress = fmt.Sprintf("%s:%d", host, port)
	}
	return adress
}

// noCache prevent the browser to cache the file served,
// so that the build frontend app are always up to date.
func noCache(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		c.Response().Header().Set("Cache-Control", "no-store")
		c.Response().Header().Set("Expires", "0")
		return next(c)
	}
}

// cacheIframe set a short cache time
func cacheIframe(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		c.Response().Header().Set("Cache-Control", "max-age=public,21600")
		return next(c)
	}
}

// cacheStatic adopt a very aggressive caching policy, suitable
// for immutable content
func cacheStatic(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		c.Response().Header().Set("Cache-Control", "max-age=31536000")
		return next(c)
	}
}

func serveWebApp(c echo.Context) error {
	return c.File("static/atable-web/index.html")
}

func serveShopApp(c echo.Context) error {
	return c.File("static/shop-session/index.html")
}

func setupRoutes(e *echo.Echo, uc *users.Controller, sc *sejours.Controller, lc *library.Controller,
	shopC *shopsession.Controller,
) {
	setupWebAPI(e, uc, sc, lc)

	// global static files used by frontend app
	e.Group("/static", middleware.Gzip(), cacheStatic).Static("/*", "static")

	// web app
	for _, route := range []string{
		"/",
		"/*",
	} {
		e.GET(route, serveWebApp, noCache)
	}

	// client API
	e.GET(sejours.ClientEnpoint, sc.SejoursExportToClient)

	// guest shop static
	e.GET("/shop-session", serveShopApp, noCache)
	e.Group("/shop-session/*", middleware.Gzip(), cacheStatic).Static("/*", "static/shop-session")

	// shop API
	e.PUT("/api/shop-session", shopC.CreateSession)
	e.GET("/api/shop-session", shopC.GetSession)
	e.POST("/api/shop-session", shopC.UpdateSession)
}
