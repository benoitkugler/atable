package testutils

import (
	"fmt"
	"os"
	"strings"
	"testing"
)

func ShouldPanic(t *testing.T, f func()) {
	t.Helper()

	defer func() { recover() }()
	f()
	t.Errorf("should have panicked")
}

func Assert(t *testing.T, b bool) {
	t.Helper()
	if !b {
		t.Fatalf("assertion error")
	}
}

func AssertNoErr(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
}

// ReadEnv read [filename] and return its environnement variables.
func ReadEnv(filename string) map[string]string {
	content, err := os.ReadFile(filename)
	if err != nil {
		panic(err)
	}

	lines := strings.Split(string(content), "\n")
	out := make(map[string]string)
	for _, line := range lines {
		chunks := strings.Split(line, "=")
		if len(chunks) != 2 {
			continue
		}
		k, v := chunks[0], chunks[1]
		out[k] = v
		fmt.Printf("Env. var. %s=%s\n", k, v)
	}
	return out
}
