package community

import (
	"context"

	"github.com/google/uuid"
)

// Repository defines the interface for community data access
type Repository interface {
	// Community CRUD
	Create(ctx context.Context, community *Community) error
	GetByID(ctx context.Context, id uuid.UUID) (*Community, error)
	GetBySlug(ctx context.Context, slug string) (*Community, error)
	Update(ctx context.Context, community *Community) error
	Delete(ctx context.Context, id uuid.UUID) error

	// Community listing
	GetAll(ctx context.Context, filter *CommunityFilter) ([]CommunityWithDetails, error)
	GetByCreator(ctx context.Context, creatorID uuid.UUID, limit, offset int) ([]Community, error)

	// Membership
	Join(ctx context.Context, member *CommunityMember) error
	Leave(ctx context.Context, communityID, userID uuid.UUID) error
	GetMembers(ctx context.Context, communityID uuid.UUID, limit, offset int) ([]CommunityMember, error)
	GetUserCommunities(ctx context.Context, userID uuid.UUID, limit, offset int) ([]CommunityWithDetails, error)
	IsMember(ctx context.Context, communityID, userID uuid.UUID) (bool, error)
	GetMemberRole(ctx context.Context, communityID, userID uuid.UUID) (*Role, error)

	// Community details
	GetWithDetails(ctx context.Context, communityID, userID uuid.UUID) (*CommunityWithDetails, error)

	// Counting for pagination
	CountCommunities(ctx context.Context, filter *CommunityFilter) (int, error)
	CountCommunityMembers(ctx context.Context, communityID uuid.UUID) (int, error)
	CountUserCommunities(ctx context.Context, userID uuid.UUID) (int, error)
}
