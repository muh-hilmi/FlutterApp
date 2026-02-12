package community

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/anigmaa/backend/internal/domain/community"
	"github.com/google/uuid"
)

var (
	ErrCommunityNotFound = errors.New("community not found")
	ErrAlreadyMember     = errors.New("already a member")
	ErrNotMember         = errors.New("not a member")
	ErrUnauthorized      = errors.New("unauthorized")
	ErrInvalidSlug       = errors.New("invalid slug")
	ErrSlugAlreadyExists = errors.New("slug already exists")
)

// Usecase handles community business logic
type Usecase struct {
	communityRepo community.Repository
}

// NewUsecase creates a new community usecase
func NewUsecase(communityRepo community.Repository) *Usecase {
	return &Usecase{
		communityRepo: communityRepo,
	}
}

// CreateCommunity creates a new community
func (uc *Usecase) CreateCommunity(ctx context.Context, creatorID uuid.UUID, req *community.CreateCommunityRequest) (*community.Community, error) {
	// Generate slug from name
	slug := generateSlug(req.Name)

	// Check if slug already exists
	existingCommunity, err := uc.communityRepo.GetBySlug(ctx, slug)
	if err != nil {
		return nil, err
	}
	if existingCommunity != nil {
		// Append random string to make it unique
		slug = fmt.Sprintf("%s-%s", slug, uuid.New().String()[:8])
	}

	comm := &community.Community{
		ID:          uuid.New(),
		Name:        req.Name,
		Slug:        slug,
		Description: req.Description,
		AvatarURL:   req.AvatarURL,
		CoverURL:    req.CoverURL,
		CreatorID:   creatorID,
		Privacy:     req.Privacy,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := uc.communityRepo.Create(ctx, comm); err != nil {
		return nil, err
	}

	// Add creator as owner member
	member := &community.CommunityMember{
		ID:          uuid.New(),
		CommunityID: comm.ID,
		UserID:      creatorID,
		Role:        community.RoleOwner,
		JoinedAt:    time.Now(),
	}

	if err := uc.communityRepo.Join(ctx, member); err != nil {
		return nil, err
	}

	return comm, nil
}

// GetCommunityByID gets a community by ID
func (uc *Usecase) GetCommunityByID(ctx context.Context, communityID, userID uuid.UUID) (*community.CommunityWithDetails, error) {
	comm, err := uc.communityRepo.GetWithDetails(ctx, communityID, userID)
	if err != nil {
		return nil, err
	}
	if comm == nil {
		return nil, ErrCommunityNotFound
	}
	return comm, nil
}

// GetAllCommunities gets all communities with filtering
func (uc *Usecase) GetAllCommunities(ctx context.Context, filter *community.CommunityFilter) ([]community.CommunityWithDetails, error) {
	return uc.communityRepo.GetAll(ctx, filter)
}

// UpdateCommunity updates a community
func (uc *Usecase) UpdateCommunity(ctx context.Context, communityID, userID uuid.UUID, req *community.UpdateCommunityRequest) (*community.Community, error) {
	// Get existing community
	comm, err := uc.communityRepo.GetByID(ctx, communityID)
	if err != nil {
		return nil, err
	}
	if comm == nil {
		return nil, ErrCommunityNotFound
	}

	// Check permission (only owner can update)
	role, err := uc.communityRepo.GetMemberRole(ctx, communityID, userID)
	if err != nil {
		return nil, err
	}
	if role == nil || *role != community.RoleOwner {
		return nil, ErrUnauthorized
	}

	// Update fields
	if req.Name != nil {
		comm.Name = *req.Name
	}
	if req.Description != nil {
		comm.Description = req.Description
	}
	if req.AvatarURL != nil {
		comm.AvatarURL = req.AvatarURL
	}
	if req.CoverURL != nil {
		comm.CoverURL = req.CoverURL
	}
	if req.Privacy != nil {
		comm.Privacy = *req.Privacy
	}

	if err := uc.communityRepo.Update(ctx, comm); err != nil {
		return nil, err
	}

	return comm, nil
}

// DeleteCommunity deletes a community
func (uc *Usecase) DeleteCommunity(ctx context.Context, communityID, userID uuid.UUID) error {
	// Get existing community
	comm, err := uc.communityRepo.GetByID(ctx, communityID)
	if err != nil {
		return err
	}
	if comm == nil {
		return ErrCommunityNotFound
	}

	// Check permission (only owner can delete)
	if comm.CreatorID != userID {
		return ErrUnauthorized
	}

	return uc.communityRepo.Delete(ctx, communityID)
}

// JoinCommunity adds a user to a community
func (uc *Usecase) JoinCommunity(ctx context.Context, communityID, userID uuid.UUID) error {
	// Check if community exists
	comm, err := uc.communityRepo.GetByID(ctx, communityID)
	if err != nil {
		return err
	}
	if comm == nil {
		return ErrCommunityNotFound
	}

	// Check if already a member
	isMember, err := uc.communityRepo.IsMember(ctx, communityID, userID)
	if err != nil {
		return err
	}
	if isMember {
		return ErrAlreadyMember
	}

	member := &community.CommunityMember{
		ID:          uuid.New(),
		CommunityID: communityID,
		UserID:      userID,
		Role:        community.RoleMember,
		JoinedAt:    time.Now(),
	}

	return uc.communityRepo.Join(ctx, member)
}

// LeaveCommunity removes a user from a community
func (uc *Usecase) LeaveCommunity(ctx context.Context, communityID, userID uuid.UUID) error {
	// Check if community exists
	comm, err := uc.communityRepo.GetByID(ctx, communityID)
	if err != nil {
		return err
	}
	if comm == nil {
		return ErrCommunityNotFound
	}

	// Prevent owner from leaving
	if comm.CreatorID == userID {
		return errors.New("owner cannot leave community")
	}

	// Check if member
	isMember, err := uc.communityRepo.IsMember(ctx, communityID, userID)
	if err != nil {
		return err
	}
	if !isMember {
		return ErrNotMember
	}

	return uc.communityRepo.Leave(ctx, communityID, userID)
}

// GetCommunityMembers gets members of a community
func (uc *Usecase) GetCommunityMembers(ctx context.Context, communityID uuid.UUID, limit, offset int) ([]community.CommunityMember, error) {
	return uc.communityRepo.GetMembers(ctx, communityID, limit, offset)
}

// GetUserCommunities gets communities a user has joined
func (uc *Usecase) GetUserCommunities(ctx context.Context, userID uuid.UUID, limit, offset int) ([]community.CommunityWithDetails, error) {
	return uc.communityRepo.GetUserCommunities(ctx, userID, limit, offset)
}

// CountCommunities counts total communities matching filter
func (uc *Usecase) CountCommunities(ctx context.Context, filter *community.CommunityFilter) (int, error) {
	return uc.communityRepo.CountCommunities(ctx, filter)
}

// CountCommunityMembers counts total members in a community
func (uc *Usecase) CountCommunityMembers(ctx context.Context, communityID uuid.UUID) (int, error) {
	return uc.communityRepo.CountCommunityMembers(ctx, communityID)
}

// CountUserCommunities counts total communities a user has joined
func (uc *Usecase) CountUserCommunities(ctx context.Context, userID uuid.UUID) (int, error) {
	return uc.communityRepo.CountUserCommunities(ctx, userID)
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
