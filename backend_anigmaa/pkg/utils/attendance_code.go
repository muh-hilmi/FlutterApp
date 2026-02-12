package utils

import (
	"crypto/rand"
	"math/big"
)

const (
	// CodeChars are the characters used in attendance codes
	CodeChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluding similar looking characters
	// CodeLength is the length of attendance codes
	CodeLength = 4
)

// GenerateAttendanceCode generates a random 4-character attendance code
// Example: "A3F7", "K9P2"
func GenerateAttendanceCode() (string, error) {
	code := make([]byte, CodeLength)
	charsLen := big.NewInt(int64(len(CodeChars)))

	for i := 0; i < CodeLength; i++ {
		num, err := rand.Int(rand.Reader, charsLen)
		if err != nil {
			return "", err
		}
		code[i] = CodeChars[num.Int64()]
	}

	return string(code), nil
}

// ValidateAttendanceCode checks if an attendance code is valid
func ValidateAttendanceCode(code string) bool {
	if len(code) != CodeLength {
		return false
	}

	for _, char := range code {
		found := false
		for _, validChar := range CodeChars {
			if char == validChar {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	return true
}
