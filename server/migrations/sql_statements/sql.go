// This script is a small helper to split an SQL file into
// 3 parts : tables, json functions and constraints
package main

import (
	"bytes"
	"os"
	"strings"
)

type statement struct {
	content string
	kind    int
}

const (
	table int = iota
	jsonFunc
	constraint
)

func newStatement(s string) statement {
	out := statement{content: s}
	switch {
	case strings.HasPrefix(s, "CREATE TABLE"):
		out.kind = table
	case strings.HasPrefix(s, "CREATE OR REPLACE FUNCTION"):
		out.kind = jsonFunc
	case strings.HasPrefix(s, "ALTER TABLE") || strings.HasPrefix(s, "CREATE UNIQUE INDEX"):
		out.kind = constraint
	default:
		panic(s)
	}
	return out
}

// remove comments
func removeComments(s string) string {
	var builder strings.Builder
	lines := strings.Split(s, "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "--") {
			continue
		}
		builder.WriteString(line + "\n")
	}
	return builder.String()
}

func splitStatements(s []byte) []statement {
	tmp := bytes.Split(s, []byte{'\n', '\n'})
	out := make([]statement, 0, len(tmp))
	for _, st := range tmp {
		str := removeComments(string(st))
		str = strings.TrimSpace(str)
		if str == "" {
			continue
		}
		out = append(out, newStatement(str))
	}
	return out
}

func main() {
	by, err := os.ReadFile("../create_all_gen.sql")
	if err != nil {
		panic(err)
	}
	statements := splitStatements(by)

	// outputs
	var files [3]*os.File
	files[0], err = os.Create("../create_all_1_tables_gen.sql")
	if err != nil {
		panic(err)
	}
	files[1], err = os.Create("../create_all_2_jsonFuncs_gen.sql")
	if err != nil {
		panic(err)
	}
	files[2], err = os.Create("../create_all_3_constraints_gen.sql")
	if err != nil {
		panic(err)
	}
	defer files[0].Close()
	defer files[1].Close()
	defer files[2].Close()

	for _, st := range statements {
		files[st.kind].WriteString(st.content)
		files[st.kind].WriteString("\n\n")
	}
}
