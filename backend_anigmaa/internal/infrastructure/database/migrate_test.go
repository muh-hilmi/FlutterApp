package database

import (
	"testing"
)

func TestParseUpMigration(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name: "sql-migrate format with Up and Down markers",
			input: `-- +migrate Up
CREATE TABLE test (
	id SERIAL PRIMARY KEY
);

-- +migrate Down
DROP TABLE test;`,
			expected: `CREATE TABLE test (
	id SERIAL PRIMARY KEY
);`,
		},
		{
			name: "sql-migrate format with only Up marker",
			input: `-- +migrate Up
CREATE TABLE test (
	id SERIAL PRIMARY KEY
);`,
			expected: `CREATE TABLE test (
	id SERIAL PRIMARY KEY
);`,
		},
		{
			name: "legacy format without markers",
			input: `CREATE TABLE test (
	id SERIAL PRIMARY KEY
);`,
			expected: `CREATE TABLE test (
	id SERIAL PRIMARY KEY
);`,
		},
		{
			name: "sql-migrate format with comments",
			input: `-- +migrate Up
-- Create test table
CREATE TABLE test (
	id SERIAL PRIMARY KEY
);
-- Add some data
INSERT INTO test DEFAULT VALUES;

-- +migrate Down
DROP TABLE test;`,
			expected: `-- Create test table
CREATE TABLE test (
	id SERIAL PRIMARY KEY
);
-- Add some data
INSERT INTO test DEFAULT VALUES;`,
		},
		{
			name: "complex migration with multiple statements",
			input: `-- +migrate Up
ALTER TABLE event_qna
ADD COLUMN IF NOT EXISTS upvotes INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS qna_upvotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qna_id UUID NOT NULL REFERENCES event_qna(id) ON DELETE CASCADE
);

-- +migrate Down
ALTER TABLE event_qna DROP COLUMN IF EXISTS upvotes;
DROP TABLE IF EXISTS qna_upvotes;`,
			expected: `ALTER TABLE event_qna
ADD COLUMN IF NOT EXISTS upvotes INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS qna_upvotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qna_id UUID NOT NULL REFERENCES event_qna(id) ON DELETE CASCADE
);`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := parseUpMigration(tt.input)
			if result != tt.expected {
				t.Errorf("parseUpMigration() = %q, want %q", result, tt.expected)
			}
		})
	}
}
