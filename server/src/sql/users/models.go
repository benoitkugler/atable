package users

type IdUser int64

// User is one account.
//
// There is one admin account, used to
// publish common receipes.
//
// gomacro:SQL ADD UNIQUE(Mail)
type User struct {
	Id IdUser

	IsAdmin bool

	Mail     string // login
	Password string // to simplify, password are not encrypted
	Pseudo   string
}
