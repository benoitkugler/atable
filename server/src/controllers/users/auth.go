package users

import (
	"encoding/json"
	"time"

	"github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"

	"github.com/golang-jwt/jwt"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

const (
	deltaTokenDays = 3
	deltaToken     = deltaTokenDays * 24 * time.Hour
)

// UserMeta are custom claims extending default ones.
type UserMeta struct {
	IdUser users.IdUser
	jwt.StandardClaims
}

func (ct *Controller) JWTMiddleware() echo.MiddlewareFunc {
	config := middleware.JWTConfig{SigningKey: ct.key[:], Claims: &UserMeta{}}
	return middleware.JWTWithConfig(config)
}

// expects the token to be in the `token` query parameters
func (ct *Controller) JWTMiddlewareForQuery() echo.MiddlewareFunc {
	config := middleware.JWTConfig{SigningKey: ct.key[:], Claims: &UserMeta{}, TokenLookup: "query:token"}
	return middleware.JWTWithConfig(config)
}

func (ct *Controller) newToken(teacher users.User) (string, error) {
	// Set custom claims
	claims := &UserMeta{
		IdUser: teacher.Id,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: time.Now().Add(deltaToken).Unix(),
		},
	}

	// Create token with claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Generate encoded token and send it as response.
	return token.SignedString(ct.key[:])
}

// JWTUser expects a JWT authentified request, and must
// only be used in routes protected by `JWTMiddleware`
func JWTUser(c echo.Context) users.IdUser {
	meta := c.Get("user").(*jwt.Token).Claims.(*UserMeta) // the token is valid here
	return meta.IdUser
}

// GetDevToken creates a new user and returns a valid token,
// so that client frontend doesn't have to use password when developping.
func (ct *Controller) GetDevToken() (string, error) {
	mail := utils.RandomString(false, 8) + "@dummy.com"
	t, err := users.User{
		Mail:     mail,
		Password: "1234",
		Pseudo:   "Dev account",
	}.Insert(ct.db)
	if err != nil {
		return "", err
	}
	token, err := ct.newToken(t)
	if err != nil {
		return "", err
	}
	type meta struct {
		Token  string
		IdUser users.IdUser
	}
	out, err := json.Marshal(meta{IdUser: t.Id, Token: token})
	return string(out), err
}
