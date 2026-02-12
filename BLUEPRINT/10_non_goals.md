# 10. NON-GOALS & OUT OF SCOPE

**What we're NOT doing. Clear boundaries to prevent scope creep.**

---

## 🔒 OUT OF SCOPE (V1)

These features are **explicitly NOT** part of V1:

### Authentication

| Feature | Status | Why V2? |
|---------|--------|---------|
| Email/password login | ❌ NOT V1 | Google only for speed |
| Phone number auth | ❌ NOT V1 | Not enough value |
| Apple Sign-In | ❌ NOT V1 | iOS only, V2 |
| 2FA (Two-Factor Auth) | ❌ NOT V1 | Overkill for V1 |
| Remember me checkbox | ❌ NOT V1 | Always remember (token) |
| Forgot password flow | ❌ NOT V1 | No password to reset |

**Rule**: If user asks "Where's email login?", answer: "V2 feature."

---

### Social Features

| Feature | Status | Why V2? |
|---------|--------|---------|
| Communities | ❌ NOT V1 | Complexity, unclear value |
| Groups | ❌ NOT V1 | Complexity |
| Private messaging | ❌ NOT V1 | Scope explosion |
| Stories | ❌ NOT V1 | Copycat, not core |
| Reels/Video | ❌ NOT V1 | Not needed for V1 |
| Live streaming | ❌ NOT V1 | Overkill |
| Dark mode | ❌ NOT V1 | Nice to have, not need |
| Multiple languages | ❌ NOT V1 | Indonesia only V1 |

**Rule**: If agent proposes "Add stories feature", redirect to this document.

---

### Event Features

| Feature | Status | Why V2? |
|---------|--------|---------|
| Recurring events | ❌ NOT V1 | Edge case |
| Event series | ❌ NOT V1 | Complexity |
| Waitlist | ❌ NOT V1 | Sold out is enough |
| Calendar export | ❌ NOT V1 | Edge case |
| Event reminders | ❌ NOT V1 | V2 feature |
| Event hosting dashboard (Advanced) | ❌ NOT V1 | V2 (revenue charts, analytics) |
| Event promotion | ❌ NOT V1 | V2 feature |
| Event categories > 10 | ❌ NOT V1 | Keep simple |

**Note**: BASIC host tools ARE in V1:
- ✅ My Events screen (view events you created)
- ✅ Edit Event (before attendees join)
- ✅ Delete Event (before attendees join)
- ✅ Basic check-in (QR scan)

**Rule**: Keep events simple: List, detail, buy, attend.

---

### Ticket Features

| Feature | Status | Why V2? |
|---------|--------|---------|
| Transfer tickets | ❌ NOT V1 | Complexity, fraud risk |
| Refund system | ❌ NOT V1 | Complex, manual V1 |
| Resale tickets | ❌ NOT V1 | Legal complexity |
| Split payment | ❌ NOT V1 | Edge case |
| Ticket tiers (VIP access) | ❌ NOT V1 | Complexity |
| Season passes | ❌ NOT V1 | Complexity |
| Group discounts | ❌ NOT V1 | Edge case |

**Rule**: Tickets are simple: Buy, get QR, check-in.

---

### Post Features

| Feature | Status | Why V2? |
|---------|--------|---------|
| Video posts | ❌ NOT V1 | Bandwidth, complexity |
| Polls | ❌ NOT V1 | Complexity |
| Articles/Blog posts | ❌ NOT V1 | Wrong format |
| Scheduled posts | ❌ NOT V1 | Nice to have |
| Edit posts | ❌ NOT V1 | Delete & repost V1 |
| Share to external apps | ❌ NOT V1 | Copy link only V1 |
| Save/bookmark posts | ❌ NOT V1 | Edge case |

**Rule**: Posts are simple: Text/photo, like, comment, share.

---

### Profile Features

| Feature | Status | Why V2? |
|---------|--------|---------|
| Profile photo upload | ❌ NOT V1 | Nice to have, not need |
| Cover photo | ❌ NOT V1 | Not needed |
| Achievements/badges | ❌ NOT V1 | Gamification creep |
| Verified badge | ❌ NOT V1 | Nice to have |
| Social links | ❌ NOT V1 | Edge case |
| Website link | ❌ NOT V1 | Edge case |
| Birthday notification | ❌ NOT V1 | Nice to have |

**Rule**: Profile is minimal: Name, photo, bio, location, interests.

---

### Search & Discovery

| Feature | Status | Why V2? |
|---------|--------|---------|
| Advanced filters | ❌ NOT V1 | Keep simple |
| Search by date range | ❌ NOT V1 | Edge case |
| Search by price | ❌ NOT V1 | Edge case |
| Map view with pins | ❌ NOT V1 | Nice to have V2 |
| AR view | ❌ NOT V1 | Overkill |
| Voice search | ❌ NOT V1 | Edge case |
| Saved searches | ❌ NOT V1 | Edge case |

**Rule**: Search is simple: Text + basic filters.

---

### Admin/Moderation

| Feature | Status | Why V2? |
|---------|--------|---------|
| Admin dashboard | ❌ NOT V1 | Manual V1 |
| Content moderation | ❌ NOT V1 | Report → manual review V1 |
| User banning | ❌ NOT V1 | Report → manual review V1 |
| Analytics dashboard | ❌ NOT V1 | Nice to have V2 |
| Export data | ❌ NOT V1 | Edge case |

**Rule**: No admin tools V1. Use direct database access if needed.

---

## 🚫 THINGS WE WILL NEVER DO

These are **permanent** "no" decisions (unless major pivot):

| Feature | Why Never? |
|---------|-----------|
| Blockchain/NFT tickets | Overhyped, unnecessary complexity |
| AI-powered recommendations | V1: Simple location-based is enough |
| Voice/Video calls | Wrong product category |
| Dating features | Wrong product category |
| Job board | Wrong product category |
| Marketplace for tickets | We're not a ticket marketplace |
| Social graph analysis | Nice to have, not core |

**Rule**: Stay focused on core value: "Find events nearby."

---

## 🎯 HOW TO HANDLE FEATURE REQUESTS

### When Someone Asks "Can We Add...?"

#### Step 1: Check This Document

If it's listed above:
- Response: "That's V2 feature. We're focused on V1 core."
- Reference: `BLUEPRINT/10_non_goals.md`

If it's NOT listed:
- Check V1 scope in `BLUEPRINT/01_vision.md`
- Check business rules in `BLUEPRINT/05_business_rules.md`

#### Step 2: Evaluate

Ask these questions:

1. **Is it essential for V1 launch?**
   - If NO → V2
   - If YES → Continue

2. **Does it duplicate existing functionality?**
   - If YES → Reuse existing
   - If NO → Continue

3. **Does it add complexity disproportionate to value?**
   - If YES → V2
   - If NO → Consider

#### Step 3: Document

If approved for V1:
- Update `BLUEPRINT/01_vision.md` (scope)
- Update relevant flow file
- Update `BLUEPRINT/05_business_rules.md` (rules)

If deferred to V2:
- Add to `BLUEPRINT/10_non_goals.md` (this file)
- Add ticket/issue for V2

---

## 🚧 PROPOSAL PROCESS

### To Propose a New Feature

1. **Write Proposal**:
   - Problem statement
   - Proposed solution
   - Value to user
   - Implementation estimate
   - Impact on V1 timeline

2. **Review Against V1 Goals**:
   - Does it help "Find events nearby"?
   - Does it add complexity?
   - Is it doable in V1 timeline?

3. **Get Approval**:
   - From Project Owner
   - Update BLUEPRINT if approved

### To Propose a Technology Change

1. **Write ADR** (see `BLUEPRINT/09_architecture_decisions.md`)
2. Get approval
3. Update documentation

---

## 📊 SCOPE CREEP DETECTION

### Warning Signs of Scope Creep

- "Wouldn't it be cool if..."
- "This is small addition" (small additions add up)
- "Users might expect..." (if not in spec, V2)
- "Just one more feature" (classic scope creep)
- "It's easy to add" (still adds complexity)

### Counter-Arguments

| Request | Response |
|---------|----------|
| "Email login is standard" | "Google only V1 for speed" |
| "Dark mode is expected" | "Nice to have V2, not need" |
| "Stories are popular" | "Copycat, not core value" |
| "Just add X real quick" | "All additions add complexity" |
| "Users might want Y" | "What do users NEED?" |

---

## 🎯 FOCUS CHECK

### When Prioritizing Work, Ask:

1. **Does this help V1 launch?**
2. **Is this in BLUEPRINT/01_vision.md scope?**
3. **Is this blocking a critical flow?**
4. **Can this be V2 without breaking V1?**

If NO to #1 or #2 → V2.

If YES to #3 → Do it now.

If #4 → Maybe consider.

---

## 📝 ADDING TO THIS DOCUMENT

When making a "not V1" decision:

1. Add feature to this document
2. Categorize (Auth, Social, Event, etc.)
3. Reason (why V2)
4. Date of decision

**Template**:

```markdown
### [Feature Name]

| Aspect | Detail |
|--------|--------|
| Proposed by | [Name] |
| Date | [YYYY-MM-DD] |
| Category | [Auth/Social/Event/etc.] |
| Decision | ❌ NOT V1 |
| Reason | [Why V2? |
| V2 Trigger | [What needs to happen first?] |
```

---

## 🚫 REMEMBER

> **"The fastest way to build a product is to NOT build 80% of features."**

> **"Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away."** - Antoine de Saint-Exupéry

V1 is about doing 5 things well, not 20 things poorly.

---

**LAST UPDATED**: 2025-01-28
**APPROVED BY**: Project Owner
**PURPOSE**: Lock scope, prevent scope creep, maintain focus
