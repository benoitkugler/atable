package pass

import "testing"

func TestEncryption(t *testing.T) {
	enc := NewEncrypterFromKey("5s64qsd897e4q87mùlds54")
	for i := range [200]int{} {
		v1 := 456 + 100*int64(i)
		s, err := newEncryptedID(v1, enc)
		if err != nil {
			t.Fatal(err)
		}
		v2, err := enc.DecryptID(s)
		if err != nil {
			t.Fatal(err)
		}
		if v1 != v2 {
			t.Fatal(v1, v2)
		}
	}
}

func TestJSON(t *testing.T) {
	type T struct {
		B string
		A int
	}
	v := T{
		A: 456, B: "sld",
	}
	var k Encrypter
	s, err := k.EncryptJSON(v)
	if err != nil {
		t.Fatal(err)
	}
	var v2 T
	err = k.DecryptJSON(s, &v2)
	if err != nil {
		t.Fatal(err)
	}
	if v != v2 {
		t.Fatal()
	}
}
