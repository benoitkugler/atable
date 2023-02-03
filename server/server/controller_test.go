package server

import "testing"

func Test(t *testing.T) {
	ct := NewController()

	id1, err := ct.createSession(ShopList{{Id: 1}, {Id: 2}, {Id: 3}})
	if err != nil {
		t.Fatal(err)
	}

	_, err = ct.updateSession(update{ID: 3, Checked: true}, id1)
	if err != nil {
		t.Fatal(err)
	}
	_, err = ct.updateSession(update{ID: 3, Checked: false}, id1)
	if err != nil {
		t.Fatal(err)
	}
	_, err = ct.updateSession(update{ID: 2, Checked: true}, id1)
	if err != nil {
		t.Fatal(err)
	}

	_, err = ct.updateSession(update{}, "XXX")
	if err == nil {
		t.Fatal("expected error on invalid session id")
	}
}
