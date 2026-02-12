# 01. PRODUCT VISION

---

## THE PROBLEM

```
"I'm bored, where should I hang out?"
"I'm going to Jogja, but don't know what's happening there"
"This week is so quiet, nothing going on"
```

## THE SOLUTION

**Anigmaa** - Social media that answers "what's happening around here" in 5 seconds.

---

## CORE USER JOURNEY

```
1. Open App (3 sec)    → See events near current location
2. Scroll (10 sec)     → See posts about events, photos, reviews
3. Interested? (1 tap) → View event details: location, price, time
4. Going? (2 tap)      → Buy ticket, get QR code
5. Arrive              → Scan QR for check-in
```

---

## SUCCESS METRIC (V1)

- User opens app → Sees nearby events within 5 seconds
- User decides to attend → Buys ticket within 2 minutes
- User arrives → Check-in success within 10 seconds

---

## TECH STACK

| Layer | Tech | Purpose |
|-------|------|---------|
| Frontend | Flutter ^3.9.2 | Mobile app |
| State | BLoC ^9.0.0 | State management |
| Navigation | go_router ^14.2.0 | Routing |
| Backend | Go 1.21 | API server |
| DB | PostgreSQL + PostGIS | Data + spatial queries |
| Cache | Redis | Session caching |
| Payment | Midtrans SDK | Payment gateway |
| Auth | Google Sign-In | Fast auth (V1 only) |

---

## ARCHITECTURE

```
Flutter App (Frontend)
    │
    │ HTTP/JSON
    ↓
Go Backend (Clean Architecture)
    │
    ├─ User Service    (auth, profiles, follow)
    ├─ Event Service   (events, reviews, Q&A)
    ├─ Post Service    (feed, posts, comments, likes)
    └─ Ticket Service  (tickets, payments, check-in)
    │
    ↓
PostgreSQL + PostGIS
Redis (cache)
```

---

## WHAT MAKES V1 SUCCESSFUL

1. **Speed** - Find events in 5 seconds
2. **Simplicity** - Google auth only, no signup form
3. **Location-first** - Default shows events nearby
4. **Social proof** - See posts from people about events
5. **Frictionless purchase** - Buy in 2 taps via Midtrans

---

## V1 NON-GOALS

- ❌ Perfect event matching (use location + interests)
- ❌ Real-time updates (V2)
- ❌ Advanced social features (communities, V2)
- ❌ Host tools (analytics, V2)
- ❌ Ticket resale/transfer (V2)

---

**Focus**: Do 5 things well, not 20 things poorly.
