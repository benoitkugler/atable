package utils

import (
	"fmt"
	"math/rand"
	"net/url"
	"strconv"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/labstack/echo/v4"
	"github.com/lib/pq"
	"golang.org/x/text/runes"
	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"
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

var noAccent = transform.Chain(norm.NFD, runes.Remove(runes.In(unicode.Mn)), norm.NFC)

// Normalize remove trailing spaces, accents, only keep alpha numeric chars
// and convert to lower case
func Normalize(s string) string {
	output, _, e := transform.String(noAccent, s)
	if e != nil {
		output = s
	}

	return strings.ToLower(strings.Map(func(r rune) rune {
		if 'a' <= r && r <= 'z' ||
			'A' <= r && r <= 'Z' ||
			'0' <= r && r <= '9' {
			return r
		}
		return -1
	}, strings.TrimSpace(output)))
}

func UpperFirst(s string) string {
	if s == "" {
		return ""
	}
	r, L := utf8.DecodeRuneInString(s)
	return string(unicode.ToUpper(r)) + s[L:]
}
