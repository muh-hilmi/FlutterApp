# 09. ARCHITECTURE DECISIONS

**Lock down technology choices. No changes without documented decision log.**

---

## FRAMWORK: Flutter

### Decision Made: 2024-01

**Why Flutter**:
- Cross-platform (iOS + Android from one codebase)
- Performance: Native compilation, no bridge
- UI: Pixel-perfect control
- Google ecosystem integration
- Growing market, strong community

### Trade-offs Accepted:
- ❌ Larger app size (~50MB vs ~20MB native)
- ❌ Learning curve for Dart language
- ❌ Smaller ecosystem than React Native

### Alternatives Considered & Rejected:

| Framework | Why Rejected |
|-----------|---------------|
| React Native | Bridge performance issues, more runtime bugs |
| Native iOS/Android | 2x development cost, 2x maintenance |
| Xamarin | Microsoft ecosystem lock-in |

**Decision**: **Flutter is locked for V1.** No re-evaluation without documented ADR (Architecture Decision Record).

---

## STATE MANAGEMENT: BLoC

### Decision Made: 2024-01

**Why BLoC**:
- Standard pattern recommended by Flutter team
- Clear separation of business logic
- Easy to test
- Strong community support

### Trade-offs Accepted:
- More boilerplate than setState
- Steeper learning curve than Provider

### Alternatives Considered & Rejected:

| Library | Why Rejected |
|---------|---------------|
| Riverpod | Too new, less battle-tested |
| Provider | Too simple for complex app state |
| GetX | Magic anti-pattern, hard to test |

**Decision**: **BLoC is locked.** All state management MUST use BLoC pattern.

---

## NAVIGATION: go_router

### Decision Made: 2024-01

**Why go_router**:
- Type-safe routing
- Deep linking support
- URL-based navigation
- Official Flutter recommendation

### Trade-offs Accepted:
- More setup than Navigator.push()
- Learning curve for declarative routes

### Alternatives Considered & Rejected:

| Library | Why Rejected |
|---------|---------------|
| Navigator 2.0 | Imperative, hard to deep link |
| Auto_route | Code generation overhead |

**Decision**: **go_router is locked.** All navigation MUST use go_router.

---

## BACKEND: Go + Gin

### Decision Made: 2024-01

**Why Go**:
- Performance: Fast compilation, fast execution
- Concurrency: Goroutines for high throughput
- Type safety: Strong typing
- Simple deployment: Single binary

**Why Gin**:
- Lightweight and fast
- Good middleware support
- Strong community

### Trade-offs Accepted:
- Manual dependency injection (no framework DI)
- Less magic than frameworks like NestJS

### Alternatives Considered & Rejected:

| Framework | Why Rejected |
|-----------|---------------|
| Node.js + Express | Slower, weak typing |
| Java + Spring | Verbose, slower startup |
| Python + Django | Slower, GIL limitation |
| C# + .NET | Windows bias, slower |

**Decision**: **Go + Gin is locked.** Backend MUST use Go.

---

## DATABASE: PostgreSQL + PostGIS

### Decision Made: 2024-01

**Why PostgreSQL**:
- Mature, battle-tested
- ACID compliance
- JSON support
- Strong community

**Why PostGIS**:
- Spatial queries for location-based events
- "Events near me" queries are core feature

### Trade-offs Accepted:
- More complex than MongoDB
- Schema migrations required
- Harder to scale horizontally than NoSQL

### Alternatives Considered & Rejected:

| Database | Why Rejected |
|----------|---------------|
| MongoDB | No spatial support, no joins |
| MySQL | Spatial support is add-on, less mature |
| Firebase | Vendor lock-in, limited queries |

**Decision**: **PostgreSQL + PostGIS is locked.** All data MUST be relational.

---

## API: REST

### Decision Made: 2024-01

**Why REST**:
- Simple, well-understood
- Easy to debug
- Universal support
- Cacheable (HTTP cache)

### Trade-offs Accepted:
- Over-fetching (fetch too much data)
- Multiple round trips for nested data

### Alternatives Considered & Rejected:

| Protocol | Why Rejected |
|----------|---------------|
| GraphQL | Overkill for V1, adds complexity |
| gRPC | Not browser-friendly, harder to debug |

**Decision**: **REST is locked for V1.** GraphQL may be V2.

---

## AUTH: Google Sign-In Only (V1)

### Decision Made: 2024-01

**Why Google Only (V1)**:
- Fastest onboarding
- No password management
- No email verification flow
- Reduces fraud

### Trade-offs Accepted:
- Users without Google account cannot sign up
- Dependent on Google policies

### Alternatives Considered & Rejected for V1:

| Method | When to Consider |
|--------|-----------------|
| Email/password | V2 - Give users option |
| Apple Sign-In | V2 - iOS users |
| Phone number | V2 - Users without Google |

**Decision**: **Google Sign-In is locked for V1.** Email/password is V2 ONLY.

---

## CACHING: Redis

### Decision Made: 2024-01

**Why Redis**:
- Fast in-memory caching
- Good for session storage
- Pub/sub for future real-time features

**Use Cases**:
- Session storage
- API response caching (TTL: 5 minutes)
- Rate limiting

### Alternatives Considered & Rejected:

| Cache | Why Rejected |
|-------|---------------|
| Memcached | No persistence, simpler |
| In-memory | Not scalable |

**Decision**: **Redis is locked.**

---

## PAYMENT: Midtrans

### Decision Made: 2024-01

**Why Midtrans**:
- Market leader in Indonesia
- Wide payment method support
- Good documentation
- SDK available

**Trade-offs Accepted**:
- Vendor lock-in (hard to switch later)
- Fees apply

### Alternatives Considered & Rejected:

| Provider | Why Rejected |
|----------|---------------|
| Stripe | Not available in Indonesia |
| Xendit | Less mature than Midtrans |

**Decision**: **Midtrans is locked.**

---

## SUMMARY OF LOCKED DECISIONS

| Component | Technology | Status |
|-----------|------------|--------|
| **Frontend Framework** | Flutter | 🔒 LOCKED |
| **State Management** | BLoC | 🔒 LOCKED |
| **Navigation** | go_router | 🔒 LOCKED |
| **Backend Framework** | Go + Gin | 🔒 LOCKED |
| **Database** | PostgreSQL + PostGIS | 🔒 LOCKED |
| **Cache** | Redis | 🔒 LOCKED |
| **API Style** | REST | 🔒 LOCKED V1 |
| **Payment** | Midtrans | 🔒 LOCKED |
| **Auth (V1)** | Google Sign-In only | 🔒 LOCKED |

---

## CHANGING THESE DECISIONS

### To challenge a decision:

1. Write ADR (Architecture Decision Record) explaining:
   - What you want to change
   - Why current choice is insufficient
   - What you propose instead
   - Trade-off analysis
   - Impact on timeline & budget

2. Get approval from Project Owner

3. Update THIS document

### Process:

```
Proposal → Discussion → Decision → Document Update
```

### Quick Wins (Allowed):

- Add utility libraries (not frameworks)
- Add linters/formatters
- Add monitoring tools
- Add deployment scripts

### NOT Allowed Without ADR:

- Change framework
- Change state management
- Change database
- Change API protocol
- Change payment provider

---

## REMEMBER

> **"Premature optimization is the root of all evil."**
>
> **"A technology choice made in ignorance is not a decision."**

These decisions were made with intent. Challenge them with data, not hype.

---

**LAST UPDATED**: 2025-01-28
**APPROVED BY**: Project Owner
**STATUS**: All decisions active for V1
