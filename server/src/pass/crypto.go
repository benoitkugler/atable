package pass

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/md5"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
)

// Encrypter is used to encrypt exposed data.
type Encrypter [16]byte

// NewEncrypter read the given ENV variable to build an encrypter.
func NewEncrypter(env string) (Encrypter, error) {
	key := os.Getenv(env)
	if key == "" {
		return Encrypter{}, fmt.Errorf("missing env %s", env)
	}
	return NewEncrypterFromKey(key), nil
}

func NewEncrypterFromKey(key string) Encrypter { return md5.Sum([]byte(key)) }

func (pass Encrypter) encrypt(data []byte) ([]byte, error) {
	block, _ := aes.NewCipher(pass[:])
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, err
	}
	ciphertext := gcm.Seal(nonce, nonce, data, nil)
	return ciphertext, nil
}

func (pass Encrypter) decrypt(data []byte) ([]byte, error) {
	block, err := aes.NewCipher(pass[:])
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	nonceSize := gcm.NonceSize()
	if len(data) <= nonceSize {
		return nil, errors.New("data too short")
	}
	nonce, ciphertext := data[:nonceSize], data[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	return plaintext, err
}

type wrappedID struct {
	ID   int64
	Salt [4]byte
}

// EncryptedID is the public version of the DB id of record.
// In particular, it is suitable to be included in URLs
type EncryptedID string

func (key Encrypter) EncryptID(ID int64) EncryptedID {
	out, _ := newEncryptedID(ID, key) // errors should never happen on safe data
	return out
}

func newEncryptedID(ID int64, key Encrypter) (EncryptedID, error) {
	var buf [4]byte
	_, _ = rand.Read(buf[:])
	text, err := json.Marshal(wrappedID{ID: ID, Salt: buf})
	if err != nil {
		return "", fmt.Errorf("internal error: %s", err)
	}
	text, err = key.encrypt(text)
	if err != nil {
		return "", fmt.Errorf("internal error: %s", err)
	}
	out := EncryptedID(base64.RawURLEncoding.EncodeToString(text))
	return out, nil
}

func (key Encrypter) DecryptID(enc EncryptedID) (int64, error) {
	text, err := base64.RawURLEncoding.DecodeString(string(enc))
	if err != nil {
		return 0, fmt.Errorf("invalid ID format: %s", err)
	}
	text, err = key.decrypt(text)
	if err != nil {
		return 0, fmt.Errorf("invalid ID encryption: %s", err)
	}
	var wr wrappedID
	err = json.Unmarshal(text, &wr)
	if err != nil {
		return 0, fmt.Errorf("invalid ID format: %s", err)
	}
	return wr.ID, nil
}

// EncryptJSON marshals `data`, encrypts and espace
// using `base64.RawURLEncoding`
func (pass Encrypter) EncryptJSON(data interface{}) (string, error) {
	b, err := json.Marshal(data)
	if err != nil {
		return "", err
	}
	b, err = pass.encrypt(b)
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

// DecryptJSON performs the reverse operation of EncryptJSON,
// storing the data into `dst`
func (pass Encrypter) DecryptJSON(data string, dst interface{}) error {
	b, err := base64.RawURLEncoding.DecodeString(data)
	if err != nil {
		return err
	}
	b, err = pass.decrypt(b)
	if err != nil {
		return err
	}
	err = json.Unmarshal(b, dst)
	return err
}
