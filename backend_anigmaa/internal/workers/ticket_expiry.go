// Package workers contains background jobs that run for the lifetime of the server.
package workers

import (
	"context"
	"log"
	"time"

	ticket_uc "github.com/anigmaa/backend/internal/usecase/ticket"
)

// TicketExpiryWorker periodically expires pending tickets whose Midtrans snap
// token has lapsed (> 1 hour old) and frees the capacity slots they occupied.
//
// Run it in a goroutine via Start(); stop it by cancelling the context.
type TicketExpiryWorker struct {
	ticketUsecase *ticket_uc.Usecase
	interval      time.Duration
}

// NewTicketExpiryWorker creates a worker that runs every interval.
// Recommended interval: 5 minutes.
func NewTicketExpiryWorker(uc *ticket_uc.Usecase, interval time.Duration) *TicketExpiryWorker {
	return &TicketExpiryWorker{
		ticketUsecase: uc,
		interval:      interval,
	}
}

// Start runs the expiry loop until ctx is cancelled. Call in a goroutine.
func (w *TicketExpiryWorker) Start(ctx context.Context) {
	log.Printf("[TicketExpiry] worker started (interval=%s, cutoff=1h)", w.interval)

	ticker := time.NewTicker(w.interval)
	defer ticker.Stop()

	// Run once immediately on startup so stale tickets from a previous server
	// session are cleaned up without waiting for the first tick.
	w.run(ctx)

	for {
		select {
		case <-ctx.Done():
			log.Println("[TicketExpiry] worker stopped")
			return
		case <-ticker.C:
			w.run(ctx)
		}
	}
}

func (w *TicketExpiryWorker) run(ctx context.Context) {
	if err := w.ticketUsecase.ExpireStaleTickets(ctx); err != nil {
		log.Printf("[TicketExpiry] error during expiry run: %v", err)
	}
}
