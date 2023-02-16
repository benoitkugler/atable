package server

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"sync"

	"github.com/labstack/echo/v4"
)

const maxSessions = 10_000 // simple protection

type Controller struct {
	sessions map[string]*Session
	lock     sync.Mutex
}

func NewController() *Controller {
	return &Controller{sessions: make(map[string]*Session)}
}

// CreateSession initie une nouvelle session de courses,
// avec la liste donnée.
func (ct *Controller) CreateSession(c echo.Context) error {
	var list ShopList
	if err := c.Bind(&list); err != nil {
		return err
	}
	id, err := ct.createSession(list)
	if err != nil {
		return err
	}
	out := struct {
		SessionID string `json:"sessionID"`
	}{SessionID: id}
	return c.JSON(200, out)
}

// renvoie l'id créé
func (ct *Controller) createSession(list ShopList) (string, error) {
	ct.lock.Lock()
	defer ct.lock.Unlock()

	if len(ct.sessions) >= maxSessions {
		return "", errors.New("internal error: maximum number of session reached")
	}
	id := randString()
	_, has := ct.sessions[id]
	for has {
		id = randString()
		_, has = ct.sessions[id]
	}
	s := Session{id: id, list: list}

	ct.sessions[id] = &s

	return id, nil
}

func (ct *Controller) GetSession(c echo.Context) error {
	id := c.QueryParam("sessionID")

	ct.lock.Lock()
	defer ct.lock.Unlock()
	l, has := ct.sessions[id]
	if !has {
		return fmt.Errorf("La session %s est invalide ou terminée.", id)
	}

	return c.JSON(200, l.list)
}

type update struct {
	Checked bool `json:"checked"`
	ID      int  `json:"id"`
}

func (ct *Controller) UpdateSession(c echo.Context) error {
	var args update
	if err := c.Bind(&args); err != nil {
		return err
	}

	id := c.QueryParam("sessionID")
	l, err := ct.updateSession(args, id)
	if err != nil {
		return err
	}

	return c.JSON(200, l.list)
}

func (ct *Controller) updateSession(in update, sessionID string) (*Session, error) {
	ct.lock.Lock()
	defer ct.lock.Unlock()

	l, has := ct.sessions[sessionID]
	if !has {
		return nil, fmt.Errorf("La session %s est invalide ou terminée.", sessionID)
	}

	for i, v := range l.list {
		if v.Id == in.ID {
			l.list[i].Checked = in.Checked
		}
	}
	return l, nil
}

func randString() string {
	var buffer [20]byte
	rand.Read(buffer[:])
	return hex.EncodeToString(buffer[:])
}
