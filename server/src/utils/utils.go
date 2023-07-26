package utils

import (
	"fmt"
	"math/rand"
	"net/url"
	"strconv"
	"strings"

	"github.com/labstack/echo"
	"github.com/lib/pq"
)

func RandomString(numberOnly bool, length int) string {
	choices := "abcdefghijklmnnopqrst0123456789"
	if numberOnly {
		choices = "0123456789"
	}
	out := make([]byte, length)
	for i := range out {
		out[i] = choices[rand.Intn(len(choices))]
	}
	return string(out[:])
}

func SQLError(err error) error {
	if err, ok := err.(*pq.Error); ok {
		return fmt.Errorf("La requête SQL a échoué : %s (table %s)", err, err.Table)
	}
	return fmt.Errorf("La requête SQL a échoué : %s %T", err, err)
}

// QueryParamInt64 parse the query param `name` to an int64
func QueryParamInt64(c echo.Context, name string) (int64, error) {
	idS := c.QueryParam(name)
	id, err := strconv.ParseInt(idS, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("invalid ID parameter %s : %s", idS, err)
	}
	return id, nil
}

// QueryParamBool parse the query param `name` to a boolean
func QueryParamBool(c echo.Context, name string) bool {
	idS := c.QueryParam(name)
	return idS != ""
}

// BuildUrl returns the url composed of <host><path>?<query>.
func BuildUrl(host, path string, query map[string]string) string {
	pm := url.Values{}
	for k, v := range query {
		pm.Add(k, v)
	}
	u := url.URL{
		Host:     host,
		Scheme:   "https",
		Path:     path,
		RawQuery: pm.Encode(),
	}
	if strings.HasPrefix(host, "localhost") {
		u.Scheme = "http"
	}
	return u.String()
}
