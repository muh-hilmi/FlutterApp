package database

import (
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jmoiron/sqlx"
)

// RunMigrations executes all pending SQL migrations in the migrations directory
func RunMigrations(db *sqlx.DB, migrationsPath string) error {
	log.Println("🔄 Starting database migrations...")

	// Create migrations tracking table if not exists
	if err := createMigrationsTable(db); err != nil {
		return fmt.Errorf("failed to create migrations table: %w", err)
	}

	// Get all migration files
	files, err := getMigrationFiles(migrationsPath)
	if err != nil {
		return fmt.Errorf("failed to get migration files: %w", err)
	}

	if len(files) == 0 {
		log.Println("ℹ️  No migration files found")
		return nil
	}

	// Execute each migration
	executedCount := 0
	for _, file := range files {
		executed, err := executeMigration(db, file)
		if err != nil {
			return fmt.Errorf("failed to execute migration %s: %w", filepath.Base(file), err)
		}
		if executed {
			executedCount++
			log.Printf("✓ Executed migration: %s", filepath.Base(file))
		}
	}

	if executedCount == 0 {
		log.Println("✓ All migrations already applied")
	} else {
		log.Printf("✓ Successfully executed %d migration(s)", executedCount)
	}

	return nil
}

// createMigrationsTable creates a table to track executed migrations
func createMigrationsTable(db *sqlx.DB) error {
	// First, create the table if it doesn't exist
	query := `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			id SERIAL PRIMARY KEY,
			filename VARCHAR(255) UNIQUE NOT NULL,
			executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`
	if _, err := db.Exec(query); err != nil {
		return err
	}

	// Check if filename column exists (for backwards compatibility)
	var columnExists bool
	checkColumnQuery := `
		SELECT EXISTS (
			SELECT 1
			FROM information_schema.columns
			WHERE table_name = 'schema_migrations'
			AND column_name = 'filename'
		)
	`
	if err := db.Get(&columnExists, checkColumnQuery); err != nil {
		return fmt.Errorf("failed to check if filename column exists: %w", err)
	}

	// If the column doesn't exist, add it
	if !columnExists {
		// Check if table has existing records
		var recordCount int
		if err := db.Get(&recordCount, "SELECT COUNT(*) FROM schema_migrations"); err != nil {
			return fmt.Errorf("failed to count existing migrations: %w", err)
		}

		if recordCount > 0 {
			// If there are existing records without filenames, we need to clear them
			// as we can't determine their original filenames
			log.Printf("⚠️  Found %d existing migration records without filename column. Clearing them...", recordCount)
			if _, err := db.Exec("TRUNCATE TABLE schema_migrations"); err != nil {
				return fmt.Errorf("failed to clear existing migrations: %w", err)
			}
		}

		// Now add the filename column
		alterQuery := `
			ALTER TABLE schema_migrations
			ADD COLUMN filename VARCHAR(255) UNIQUE NOT NULL
		`
		if _, err := db.Exec(alterQuery); err != nil {
			return fmt.Errorf("failed to add filename column: %w", err)
		}
		log.Println("✓ Added filename column to schema_migrations table")
	}

	return nil
}

// getMigrationFiles returns sorted list of migration files
func getMigrationFiles(migrationsPath string) ([]string, error) {
	pattern := filepath.Join(migrationsPath, "*.sql")
	files, err := filepath.Glob(pattern)
	if err != nil {
		return nil, err
	}

	// Filter out .down.sql files for now (we only run .up.sql and non-versioned .sql)
	var filteredFiles []string
	for _, file := range files {
		if !strings.HasSuffix(file, ".down.sql") {
			filteredFiles = append(filteredFiles, file)
		}
	}

	// Sort files alphabetically (001_xxx.up.sql, 002_xxx.up.sql, etc.)
	sort.Strings(filteredFiles)

	return filteredFiles, nil
}

// parseUpMigration extracts the Up migration SQL from sql-migrate format
// sql-migrate uses markers like:
// -- +migrate Up
// SQL statements here...
// -- +migrate Down
// SQL statements here...
func parseUpMigration(content string) string {
	// Split content by lines
	lines := strings.Split(content, "\n")

	var upLines []string
	inUpSection := false

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)

		// Check for migrate markers
		if trimmed == "-- +migrate Up" {
			inUpSection = true
			continue
		}
		if trimmed == "-- +migrate Down" {
			// End of Up section
			break
		}

		// Collect lines in the Up section
		if inUpSection {
			upLines = append(upLines, line)
		}
	}

	// If we found an Up section, return it
	if len(upLines) > 0 {
		return strings.Join(upLines, "\n")
	}

	// No migrate markers found - this is a legacy migration file
	// Return the entire content as-is
	return content
}

// isMigrationExecuted checks if a migration has already been executed
func isMigrationExecuted(db *sqlx.DB, filename string) (bool, error) {
	var count int
	query := "SELECT COUNT(*) FROM schema_migrations WHERE filename = $1"
	err := db.Get(&count, query, filename)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// recordMigration records that a migration has been executed
func recordMigration(db sqlx.Ext, filename string) error {
	query := "INSERT INTO schema_migrations (filename) VALUES ($1)"
	_, err := db.Exec(query, filename)
	return err
}

// executeMigration executes a single migration file
func executeMigration(db *sqlx.DB, filepath string) (bool, error) {
	filename := filepath[strings.LastIndex(filepath, "/")+1:]

	// Check if migration already executed
	executed, err := isMigrationExecuted(db, filename)
	if err != nil {
		return false, fmt.Errorf("failed to check migration status: %w", err)
	}

	if executed {
		// Already executed, skip
		return false, nil
	}

	// Read migration file
	content, err := ioutil.ReadFile(filepath)
	if err != nil {
		return false, fmt.Errorf("failed to read migration file: %w", err)
	}

	// Parse sql-migrate format to extract Up migration
	sqlToExecute := parseUpMigration(string(content))

	// Execute migration in a transaction
	tx, err := db.Beginx()
	if err != nil {
		return false, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Execute SQL
	if _, err := tx.Exec(sqlToExecute); err != nil {
		return false, fmt.Errorf("failed to execute SQL: %w", err)
	}

	// Record migration
	if err := recordMigration(tx, filename); err != nil {
		return false, fmt.Errorf("failed to record migration: %w", err)
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		return false, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return true, nil
}
