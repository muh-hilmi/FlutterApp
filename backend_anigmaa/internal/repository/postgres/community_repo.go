package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/anigmaa/backend/internal/domain/community"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type communityRepository struct {
	db *sqlx.DB
}

// NewCommunityRepository creates a new community repository
func NewCommunityRepository(db *sqlx.DB) community.Repository {
	return &communityRepository{db: db}
}

// Create creates a new community
func (r *communityRepository) Create(ctx context.Context, comm *community.Community) error {
	query := `
		INSERT INTO communities (id, name, slug, description, avatar_url, cover_url, creator_id, privacy, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`

	_, err := r.db.ExecContext(ctx, query,
		comm.ID,
		comm.Name,
		comm.Slug,
		comm.Description,
		comm.AvatarURL,
		comm.CoverURL,
		comm.CreatorID,
		comm.Privacy,
		comm.CreatedAt,
		comm.UpdatedAt,
	)

	return err
}

// GetByID gets a community by ID
func (r *communityRepository) GetByID(ctx context.Context, id uuid.UUID) (*community.Community, error) {
	var comm community.Community
	query := `SELECT * FROM communities WHERE id = $1`

	err := r.db.GetContext(ctx, &comm, query, id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &comm, err
}

// GetBySlug gets a community by slug
func (r *communityRepository) GetBySlug(ctx context.Context, slug string) (*community.Community, error) {
	var comm community.Community
	query := `SELECT * FROM communities WHERE slug = $1`

	err := r.db.GetContext(ctx, &comm, query, slug)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &comm, err
}

// Update updates a community
func (r *communityRepository) Update(ctx context.Context, comm *community.Community) error {
	query := `
		UPDATE communities
		SET name = $1, description = $2, avatar_url = $3, cover_url = $4, privacy = $5, updated_at = $6
		WHERE id = $7
	`

	_, err := r.db.ExecContext(ctx, query,
		comm.Name,
		comm.Description,
		comm.AvatarURL,
		comm.CoverURL,
		comm.Privacy,
		time.Now(),
		comm.ID,
	)

	return err
}

// Delete deletes a community
func (r *communityRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM communities WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

// GetAll gets all communities with optional filtering
func (r *communityRepository) GetAll(ctx context.Context, filter *community.CommunityFilter) ([]community.CommunityWithDetails, error) {
	var communities []community.CommunityWithDetails

	query := `
		SELECT
			c.id, c.name, c.slug, c.description, c.avatar_url, c.cover_url,
			c.creator_id, c.privacy, c.members_count, c.posts_count,
			c.created_at, c.updated_at,
			u.name as creator_name,
			u.avatar_url as creator_avatar_url,
			false as is_joined_by_user,
			NULL::text as user_role
		FROM communities c
		JOIN users u ON c.creator_id = u.id
		WHERE 1=1
	`

	args := []interface{}{}
	argIdx := 1

	// Apply filters
	if filter.Search != nil && *filter.Search != "" {
		query += fmt.Sprintf(" AND (c.name ILIKE $%d OR c.description ILIKE $%d)", argIdx, argIdx)
		searchTerm := "%" + *filter.Search + "%"
		args = append(args, searchTerm)
		argIdx++
	}

	if filter.Privacy != nil {
		query += fmt.Sprintf(" AND c.privacy = $%d", argIdx)
		args = append(args, *filter.Privacy)
		argIdx++
	}

	query += " ORDER BY c.created_at DESC"

	// Apply pagination
	query += fmt.Sprintf(" LIMIT $%d OFFSET $%d", argIdx, argIdx+1)
	args = append(args, filter.Limit, filter.Offset)

	err := r.db.SelectContext(ctx, &communities, query, args...)
	return communities, err
}

// GetByCreator gets communities created by a user
func (r *communityRepository) GetByCreator(ctx context.Context, creatorID uuid.UUID, limit, offset int) ([]community.Community, error) {
	var communities []community.Community
	query := `
		SELECT * FROM communities
		WHERE creator_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	err := r.db.SelectContext(ctx, &communities, query, creatorID, limit, offset)
	return communities, err
}

// Join adds a user to a community
func (r *communityRepository) Join(ctx context.Context, member *community.CommunityMember) error {
	query := `
		INSERT INTO community_members (id, community_id, user_id, role, joined_at)
		VALUES ($1, $2, $3, $4, $5)
	`

	_, err := r.db.ExecContext(ctx, query,
		member.ID,
		member.CommunityID,
		member.UserID,
		member.Role,
		member.JoinedAt,
	)

	return err
}

// Leave removes a user from a community
func (r *communityRepository) Leave(ctx context.Context, communityID, userID uuid.UUID) error {
	query := `DELETE FROM community_members WHERE community_id = $1 AND user_id = $2`
	_, err := r.db.ExecContext(ctx, query, communityID, userID)
	return err
}

// GetMembers gets members of a community
func (r *communityRepository) GetMembers(ctx context.Context, communityID uuid.UUID, limit, offset int) ([]community.CommunityMember, error) {
	var members []community.CommunityMember
	query := `
		SELECT * FROM community_members
		WHERE community_id = $1
		ORDER BY joined_at DESC
		LIMIT $2 OFFSET $3
	`

	err := r.db.SelectContext(ctx, &members, query, communityID, limit, offset)
	return members, err
}

// GetUserCommunities gets communities a user has joined
func (r *communityRepository) GetUserCommunities(ctx context.Context, userID uuid.UUID, limit, offset int) ([]community.CommunityWithDetails, error) {
	var communities []community.CommunityWithDetails
	query := `
		SELECT
			c.id, c.name, c.slug, c.description, c.avatar_url, c.cover_url,
			c.creator_id, c.privacy, c.members_count, c.posts_count,
			c.created_at, c.updated_at,
			u.name as creator_name,
			u.avatar_url as creator_avatar_url,
			true as is_joined_by_user,
			cm.role as user_role
		FROM communities c
		JOIN users u ON c.creator_id = u.id
		JOIN community_members cm ON c.id = cm.community_id
		WHERE cm.user_id = $1
		ORDER BY cm.joined_at DESC
		LIMIT $2 OFFSET $3
	`

	err := r.db.SelectContext(ctx, &communities, query, userID, limit, offset)
	return communities, err
}

// IsMember checks if a user is a member of a community
func (r *communityRepository) IsMember(ctx context.Context, communityID, userID uuid.UUID) (bool, error) {
	var count int
	query := `SELECT COUNT(*) FROM community_members WHERE community_id = $1 AND user_id = $2`

	err := r.db.GetContext(ctx, &count, query, communityID, userID)
	return count > 0, err
}

// GetMemberRole gets the role of a user in a community
func (r *communityRepository) GetMemberRole(ctx context.Context, communityID, userID uuid.UUID) (*community.Role, error) {
	var role community.Role
	query := `SELECT role FROM community_members WHERE community_id = $1 AND user_id = $2`

	err := r.db.GetContext(ctx, &role, query, communityID, userID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &role, err
}

// GetWithDetails gets a community with details
func (r *communityRepository) GetWithDetails(ctx context.Context, communityID, userID uuid.UUID) (*community.CommunityWithDetails, error) {
	var comm community.CommunityWithDetails
	query := `
		SELECT
			c.id, c.name, c.slug, c.description, c.avatar_url, c.cover_url,
			c.creator_id, c.privacy, c.members_count, c.posts_count,
			c.created_at, c.updated_at,
			u.name as creator_name,
			u.avatar_url as creator_avatar_url,
			EXISTS(SELECT 1 FROM community_members WHERE community_id = c.id AND user_id = $2) as is_joined_by_user,
			(SELECT role FROM community_members WHERE community_id = c.id AND user_id = $2) as user_role
		FROM communities c
		JOIN users u ON c.creator_id = u.id
		WHERE c.id = $1
	`

	err := r.db.GetContext(ctx, &comm, query, communityID, userID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &comm, err
}

// generateSlug generates a URL-friendly slug from a name
func generateSlug(name string) string {
	slug := strings.ToLower(name)
	slug = strings.ReplaceAll(slug, " ", "-")
	// Remove special characters except hyphens
	var result []rune
	for _, char := range slug {
		if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-' {
			result = append(result, char)
		}
	}
	return string(result)
}

// CountCommunities counts total communities matching filter
func (r *communityRepository) CountCommunities(ctx context.Context, filter *community.CommunityFilter) (int, error) {
	query := `SELECT COUNT(*) FROM communities c WHERE 1=1`
	args := []interface{}{}
	argIdx := 1

	// Apply filters
	if filter.Search != nil && *filter.Search != "" {
		query += fmt.Sprintf(" AND (c.name ILIKE $%d OR c.description ILIKE $%d)", argIdx, argIdx)
		searchTerm := "%" + *filter.Search + "%"
		args = append(args, searchTerm)
		argIdx++
	}

	if filter.Privacy != nil {
		query += fmt.Sprintf(" AND c.privacy = $%d", argIdx)
		args = append(args, *filter.Privacy)
		argIdx++
	}

	var count int
	err := r.db.QueryRowContext(ctx, query, args...).Scan(&count)
	return count, err
}

// CountCommunityMembers counts total members in a community
func (r *communityRepository) CountCommunityMembers(ctx context.Context, communityID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM community_members WHERE community_id = $1`
	var count int
	err := r.db.QueryRowContext(ctx, query, communityID).Scan(&count)
	return count, err
}

// CountUserCommunities counts total communities a user has joined
func (r *communityRepository) CountUserCommunities(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM community_members WHERE user_id = $1`
	var count int
	err := r.db.QueryRowContext(ctx, query, userID).Scan(&count)
	return count, err
}
