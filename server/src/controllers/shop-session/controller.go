package shopsession

import (
	"errors"
	"fmt"
	"sync"

	"github.com/benoitkugler/atable/utils"
	"github.com/labstack/echo/v4"
)

const maxSessions = 10_000 // simple protection

type Controller struct {
	sessions map[string]Session
	lock     sync.Mutex
}

func NewController() *Controller {
	return &Controller{sessions: map[string]Session{}}
}

// CreateSession initie une nouvelle session de courses,
// avec la liste donnée.
func (ct *Controller) CreateSession(c echo.Context) error {
	var args ShopList
	if err := c.Bind(&args); err != nil {
		return err
	}
	out, err := ct.createSession(args)
	if err != nil {
		return err
	}
	return c.JSON(200, out)
}

// renvoie l'id créé
func (ct *Controller) createSession(list ShopList) (CreateSessionOut, error) {
	ct.lock.Lock()
	defer ct.lock.Unlock()

	if len(ct.sessions) >= maxSessions {
		return CreateSessionOut{}, errors.New("internal error: maximum number of session reached")
	}
	id := utils.RandomString(false, 10)
	for _, has := ct.sessions[id]; has; _, has = ct.sessions[id] {
		id = utils.RandomString(false, 10)
	}
	s := Session{Id: id, List: list}

	ct.sessions[id] = s

	fmt.Printf("Creating session %s with %d ingredients\n", id, len(list))

	return CreateSessionOut{SessionID: id}, nil
}

func (ct *Controller) GetSession(c echo.Context) error {
	id := c.QueryParam("sessionID")
	session, ok := ct.sessions[id]
	if !ok {
		return fmt.Errorf("La session <%s> est invalide ou terminée.", id)
	}
	return c.JSON(200, session)
}

func (ct *Controller) UpdateSession(c echo.Context) error {
	var args UpdateSessionIn
	if err := c.Bind(&args); err != nil {
		return err
	}

	id := c.QueryParam("sessionID")
	out, err := ct.updateSession(args, id)
	if err != nil {
		return err
	}

	return c.JSON(200, out)
}

func (ct *Controller) updateSession(args UpdateSessionIn, sessionID string) (Session, error) {
	ct.lock.Lock()
	defer ct.lock.Unlock()

	session, ok := ct.sessions[sessionID]
	if !ok {
		return session, fmt.Errorf("La session <%s> est invalide ou terminée.", sessionID)
	}

	for i, v := range session.List {
		if v.Ingredient.Id == args.Id {
			session.List[i].Checked = args.Checked
		}
	}

	return session, nil
}
