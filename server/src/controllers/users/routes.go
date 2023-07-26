package users

import (
	"database/sql"
	"errors"
	"fmt"
	"net/mail"
	"strings"

	"github.com/benoitkugler/atable/mailer"
	"github.com/benoitkugler/atable/pass"
	us "github.com/benoitkugler/atable/sql/users"
	"github.com/benoitkugler/atable/utils"

	"github.com/labstack/echo/v4"
)

type Controller struct {
	db   *sql.DB
	key  pass.Encrypter
	smtp pass.SMTP
	host string
}

func NewController(db *sql.DB, key pass.Encrypter, smtp pass.SMTP, host string) *Controller {
	return &Controller{db: db, key: key, smtp: smtp, host: host}
}

func (ct *Controller) LoadAmin() (us.User, error) {
	rows, err := ct.db.Query("SELECT * FROM users WHERE IsAdmin = true")
	if err != nil {
		return us.User{}, utils.SQLError(err)
	}
	users, err := us.ScanUsers(rows)
	if err != nil {
		return us.User{}, utils.SQLError(err)
	}
	if len(users) != 1 {
		return us.User{}, errors.New("internal error: exactly one user must be admin")
	}
	admin := users[users.IDs()[0]]
	return admin, nil
}

const ValidateInscriptionEndPoint = "inscription"

type AskInscriptionIn struct {
	Mail     string
	Password string
	Pseudo   string
}

type AskInscriptionOut struct {
	Error           string // empty for no error
	IsPasswordError bool
}

type LogginIn struct {
	Mail     string
	Password string
}

type LogginOut struct {
	Error           string // empty means success
	Token           string // token to use in the next requests
	Pseudo          string
	IsPasswordError bool // else : unused mail
}

func (ct *Controller) emailInscription(args AskInscriptionIn) (string, error) {
	_, err := mail.ParseAddress(args.Mail)
	if err != nil {
		return "", errors.New("L'adresse mail est invalide.")
	}

	payload, err := ct.key.EncryptJSON(args)
	if err != nil {
		return "", err
	}

	url := utils.BuildUrl(ct.host, ValidateInscriptionEndPoint, map[string]string{
		"data": payload,
	})

	return fmt.Sprintf(`
	Bonjour et bienvenue sur À table ! <br/><br/>

	Nous avons pu vérifier la validité de votre adresse mail. Merci de terminer votre inscription
	en suivant le lien : <br/>
	<a href="%s">%s</a> <br/><br/>

	Culinairement vôtre, <br/>
	L'équipe À table
	`, url, url), nil
}

// AskInscription send a link to register a new user account.
func (ct *Controller) AskInscription(c echo.Context) error {
	var args AskInscriptionIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.askInscription(args)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) askInscription(args AskInscriptionIn) (AskInscriptionOut, error) {
	args.Mail = strings.TrimSpace(args.Mail)

	users, err := us.SelectAllUsers(ct.db)
	if err != nil {
		return AskInscriptionOut{}, utils.SQLError(err)
	}
	for _, tc := range users {
		if tc.Mail == args.Mail {
			return AskInscriptionOut{Error: "Cette adresse mail est déjà utilisée."}, nil
		}
	}

	if len(args.Password) < 2 {
		return AskInscriptionOut{Error: "Merci de choisir un mot de passe plus solide.", IsPasswordError: true}, nil
	}

	mailText, err := ct.emailInscription(args)
	if err != nil {
		return AskInscriptionOut{Error: err.Error()}, nil
	}

	err = mailer.SendMail(ct.smtp, []string{args.Mail}, "Bienvenue sur À table", mailText)
	if err != nil {
		return AskInscriptionOut{}, fmt.Errorf("Erreur interne (%s)", err)
	}

	return AskInscriptionOut{}, nil
}

func (ct *Controller) ValidateInscription(c echo.Context) error {
	payload := c.QueryParam("data")

	var args AskInscriptionIn
	err := ct.key.DecryptJSON(payload, &args)
	if err != nil {
		return err
	}

	t := us.User{
		Mail:     args.Mail,
		Password: args.Password,
		Pseudo:   args.Pseudo,
	}
	t, err = t.Insert(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}

	url := utils.BuildUrl(ct.host, "", map[string]string{
		"show-success-inscription": "OK",
	})
	return c.Redirect(302, url)
}

func (ct *Controller) loggin(args LogginIn) (LogginOut, error) {
	user, found, err := us.SelectUserByMail(ct.db, strings.TrimSpace(args.Mail))
	if err != nil {
		return LogginOut{}, utils.SQLError(err)
	}
	if !found {
		return LogginOut{Error: "Cette adresse mail n'est pas utilisée."}, nil
	}

	if args.Password != user.Password {
		return LogginOut{Error: "Le mot de passe est incorrect.", IsPasswordError: true}, nil
	}

	token, err := ct.newToken(user)
	if err != nil {
		return LogginOut{}, err
	}

	return LogginOut{Token: token, Pseudo: user.Pseudo}, nil
}

func (ct *Controller) Loggin(c echo.Context) error {
	var args LogginIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	out, err := ct.loggin(args)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

// UserResetPassword generates a new password for the given account
// and sends it by email.
func (ct *Controller) UserResetPassword(c echo.Context) error {
	mail := c.QueryParam("mail")
	err := ct.resetPassword(mail)
	if err != nil {
		return err
	}
	return c.NoContent(200)
}

func (ct *Controller) emailResetPassword(newPassword string) string {
	url := utils.BuildUrl(ct.host, "", nil)
	return fmt.Sprintf(`
	Bonjour, <br/><br/>

	Vous avez demandé la ré-initialisation de votre mot de passe À table. Votre nouveau mot de passe est : <br/>
	<b>%s</b> <br/><br/>

	Après vous être <a href="%s">connecté</a>, vous pourrez le modifier dans vos réglages.<br/><br/>

	Culinairement vôtre, <br/>
	L'équipe À table`, newPassword, url)
}

func (ct *Controller) resetPassword(mail string) error {
	user, found, err := us.SelectUserByMail(ct.db, strings.TrimSpace(mail))
	if err != nil {
		return utils.SQLError(err)
	}
	if !found {
		return errors.New("Cette adresse mail n'est pas utilisée.")
	}

	// generate a new password
	newPassword := utils.RandomString(true, 8)
	user.Password = newPassword
	_, err = user.Update(ct.db)
	if err != nil {
		return utils.SQLError(err)
	}

	// send it by email
	mailText := ct.emailResetPassword(newPassword)
	err = mailer.SendMail(ct.smtp, []string{mail}, "Changement de mot de passe", mailText)
	if err != nil {
		return fmt.Errorf("Erreur interne (%s)", err)
	}

	return nil
}
