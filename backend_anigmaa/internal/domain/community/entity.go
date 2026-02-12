package community

import (
	"time"

	"github.com/google/uuid"
)

// Privacy represents community privacy level
type Privacy string

const (
	PrivacyPublic  Privacy = "public"
	PrivacyPrivate Privacy = "private"
	PrivacySecret  Privacy = "secret"
)

// Role represents member role in a community
type Role string

const (
	RoleOwner     Role = "owner"
	RoleAdmin     Role = "admin"
	RoleModerator Role = "moderator"
	RoleMember    Role = "member"
)

// Category represents community category (aligned with event categories)
type Category string

const (
	CategoryMeetup     Category = "meetup"
	CategorySports     Category = "sports"
	CategoryWorkshop   Category = "workshop"
	CategoryNetworking Category = "networking"
	CategoryFood       Category = "food"
	CategoryCreative   Category = "creative"
	CategoryOutdoor    Category = "outdoor"
	CategoryFitness    Category = "fitness"
	CategoryLearning   Category = "learning"
	CategorySocial     Category = "social"
)

// Community represents a user community/group
type Community struct {
	ID           uuid.UUID `json:"id" db:"id"`
	Name         string    `json:"name" db:"name"`
	Slug         string    `json:"slug" db:"slug"`
	Description  *string   `json:"description,omitempty" db:"description"`
	Category     Category  `json:"category" db:"category"`
	AvatarURL    *string   `json:"avatar_url,omitempty" db:"avatar_url"`
	CoverURL     *string   `json:"cover_url,omitempty" db:"cover_url"`
	CreatorID    uuid.UUID `json:"creator_id" db:"creator_id"`
	Privacy      Privacy   `json:"privacy" db:"privacy"`
	MembersCount int       `json:"members_count" db:"members_count"`
	PostsCount   int       `json:"posts_count" db:"posts_count"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// CommunityMember represents a member of a community
type CommunityMember struct {
	ID          uuid.UUID `json:"id" db:"id"`
	CommunityID uuid.UUID `json:"community_id" db:"community_id"`
	UserID      uuid.UUID `json:"user_id" db:"user_id"`
	Role        Role      `json:"role" db:"role"`
	JoinedAt    time.Time `json:"joined_at" db:"joined_at"`
}

// CommunityWithDetails includes additional community information
type CommunityWithDetails struct {
	Community
	CreatorName      string  `json:"creator_name" db:"creator_name"`
	CreatorAvatarURL *string `json:"creator_avatar_url" db:"creator_avatar_url"`
	IsJoinedByUser   bool    `json:"is_joined_by_current_user" db:"is_joined_by_user"`
	UserRole         *Role   `json:"user_role,omitempty" db:"user_role"`
}

// CreateCommunityRequest represents community creation data
type CreateCommunityRequest struct {
	Name        string   `json:"name" binding:"required,min=3,max=100"`
	Description *string  `json:"description,omitempty" binding:"omitempty,max=500"`
	Category    Category `json:"category" binding:"required"`
	AvatarURL   *string  `json:"avatar_url,omitempty"`
	CoverURL    *string  `json:"cover_url,omitempty"`
	Privacy     Privacy  `json:"privacy" binding:"required"`
}

// UpdateCommunityRequest represents community update data
type UpdateCommunityRequest struct {
	Name        *string   `json:"name,omitempty" binding:"omitempty,min=3,max=100"`
	Description *string   `json:"description,omitempty" binding:"omitempty,max=500"`
	Category    *Category `json:"category,omitempty"`
	AvatarURL   *string   `json:"avatar_url,omitempty"`
	CoverURL    *string   `json:"cover_url,omitempty"`
	Privacy     *Privacy  `json:"privacy,omitempty"`
}

// CommunityFilter represents community filtering options
type CommunityFilter struct {
	Search   *string   `form:"search"`
	Category *Category `form:"category"`
	Privacy  *Privacy  `form:"privacy"`
	Limit    int       `form:"limit"`
	Offset   int       `form:"offset"`
}
