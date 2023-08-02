package mailer

import (
	"bytes"
	"fmt"
	"mime"
	"net/smtp"
	"path/filepath"
	"time"

	"github.com/benoitkugler/atable/pass"

	"github.com/jordan-wright/email"
)

var devMail string

// SetDevMail replaces the real mail adress by the given one,
// when using [SendMail]
func SetDevMail(mail string) {
	devMail = mail
}

// JoinedFile is a file attached to the mail.
type JoinedFile struct {
	Filename string
	Content  []byte
}

func (pj JoinedFile) attach(e *email.Email) error {
	ty := mime.TypeByExtension(filepath.Ext(pj.Filename))
	_, err := e.Attach(bytes.NewReader(pj.Content), pj.Filename, ty)
	return err
}

func newMail(to []string, subject, text string, creds pass.SMTP, pjs []JoinedFile) (*email.Email, error) {
	e := email.NewEmail()

	e.To = to
	// in dev mode, replace the real adress
	if devMail != "" {
		e.To = []string{devMail}
	}

	e.From = fmt.Sprintf("À table <%s>", creds.User)
	e.Subject = subject
	e.HTML = []byte(text)
	e.Text = []byte(text)

	e.Headers.Set("List-Unsubscribe", fmt.Sprintf("<mailto:%s>", creds.User))

	for _, pj := range pjs { // ajout des pièces jointes
		if err := pj.attach(e); err != nil {
			return nil, err
		}
	}
	return e, nil
}

func getFromAuth(creds pass.SMTP) (string, smtp.Auth) {
	from := fmt.Sprintf("%s:%s", creds.Host, creds.Port)
	auth := smtp.PlainAuth("", creds.User, creds.Password, creds.Host)
	return from, auth
}

// SendMail one simple mail.
func SendMail(smtp pass.SMTP, to []string, subject, text string) (err error) {
	e, err := newMail(to, subject, text, smtp, nil)
	if err != nil {
		return err
	}

	from, auth := getFromAuth(smtp)
	if err = e.Send(from, auth); err != nil {
		return fmt.Errorf("sending mail : %s", err)
	}
	return nil
}

// Pool provides a faster way to send one email to multiple adresses.
type Pool struct {
	pool  *email.Pool
	creds pass.SMTP
	pjs   []JoinedFile
}

// NewPool returns a new pool.
// `SendMail` should be called repeat repeatedly then `Close` once.
func NewPool(credences pass.SMTP, pjs []JoinedFile) (Pool, error) {
	from, auth := getFromAuth(credences)
	p, err := email.NewPool(from, 1, auth)
	if err != nil {
		return Pool{}, err
	}
	return Pool{pool: p, creds: credences, pjs: pjs}, err
}

func (p Pool) SendMail(to, subject, textBody string) error {
	mail, err := newMail([]string{to}, subject, textBody, p.creds, p.pjs)
	if err != nil {
		return err
	}
	if err := p.pool.Send(mail, 10*time.Second); err != nil {
		return fmt.Errorf("sending mail : %s", err)
	}
	return nil
}

func (p Pool) Close() {
	p.pool.Close()
}
