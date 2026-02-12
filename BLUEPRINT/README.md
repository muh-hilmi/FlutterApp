# ANIGMAA BLUEPRINT

**Production Blueprint with Governance Controls**

---

## 🚨 IMPORTANT: READ THIS FIRST

### ⛔ This Blueprint is LOCKED

- Technology choices are **final** (see `09_architecture_decisions.md`)
- V1 scope is **fixed** (see `10_non_goals.md`)
- State machines are **mandatory** (see `11_state_machines.md`)
- DO NOT challenge decisions without ADR

### 📋 Document Purpose

This blueprint is **authoritative**. It defines:
- What we're building (and NOT building)
- How systems work (state machines)
- How to implement (standards)
- What to follow (rules)

**If something is not documented here, it doesn't exist.**

---

## QUICK START

| New Agent? | Read This First | Then |
|-------------|-----------------|------|
| Understanding project | [`01_vision.md`](./01_vision.md) | Continue |
| Implementing screen | [`02_user_flows/`](./02_user_flows/) | Continue |
| Backend integration | [`03_api_contracts.md`](./03_api_contracts.md) | Continue |
| Defining data | [`04_data_models.md`](./04_data_models.md) | Continue |
| Handling edge cases | [`05_business_rules.md`](./05_business_rules.md) | Continue |
| Creating files | [`06_file_organization.md`](./06_file_organization.md) | Continue |
| Testing | [`07_qa_strategy.md`](./07_qa_strategy.md) | Continue |
| Writing code | [`08_coding_standards.md`](./08_coding_standards.md) | Continue |
| **Questioning decisions** | [`09_architecture_decisions.md`](./09_architecture_decisions.md) | Read first |
| **Proposing feature** | [`10_non_goals.md`](./10_non_goals.md) | Check this first |
| **Entity states** | [`11_state_machines.md`](./11_state_machines.md) | Follow these |

---

## 📂 DOCUMENT STRUCTURE

### Core Blueprint

| File | Purpose | When to Use |
|------|---------|-------------|
| **01_vision.md** | Product vision, success metrics, tech stack | Understanding WHY |
| **02_user_flows/** | Complete user flows (6 flows) | Implementing screens |
| **03_api_contracts.md** | All API endpoints with schemas | Backend integration |
| **04_data_models.md** | Entity & model definitions | Creating entities |
| **05_business_rules.md** | Business logic & constraints | Handling edge cases |
| **06_file_organization.md** | File structure & naming | Creating new files |
| **07_qa_strategy.md** | Testing requirements & reports | QA & testing |
| **08_coding_standards.md** | BLoC, navigation, DI patterns | Writing code |

### Governance (NEW - LOCKED)

| File | Purpose | Authority |
|------|---------|-----------|
| **09_architecture_decisions.md** | Locked technology choices | Project Owner approval to change |
| **10_non_goals.md** | Out of scope features | Project Owner approval to add |
| **11_state_machines.md** | Entity states & transitions | MANDATORY - all code must follow |

---

## 🛡️ GOVERNANCE CONTROLS

### What You CAN Do

- Implement features defined in V1 scope
- Fix bugs in existing code
- Improve code quality (refactor within same pattern)
- Add tests for existing features
- Optimize performance
- Update documentation to reflect actual code

### What you CANNOT Do (Without Approval)

- Change technology stack (Flutter, BLoC, Go, etc.)
- Add features outside V1 scope
- Change state management patterns
- Modify API contracts unilaterally
- "Improve" UX flows without updating flow docs
- Make architectural decisions without ADR

### To Propose a Change

1. Check `10_non_goals.md` - is it V2?
2. If V1 → Prepare ADR (see `09_architecture_decisions.md`)
3. Get Project Owner approval
4. Update relevant blueprint file
5. Then implement

---

## 🎯 V1 SCOPE (LOCKED)

### IN V1 ✅

- Google Sign In (only)
- Event discovery by location
- Social feed (posts, likes, comments)
- Event detail & registration
- Simple profile (name, bio, location)
- Buy ticket via Midtrans
- QR ticket check-in

### OUT OF V1 ❌

- Email/password login
- Communities
- Advanced filters
- Host analytics
- Ticket transfer
- Refund system
- Profile photo upload
- Dark mode
- Stories, reels, video
- Any feature not explicitly listed above

**See `10_non_goals.md` for complete list.**

---

## 🔒 TECHNOLOGY LOCKS

### Frontend Stack (LOCKED)

| Component | Technology | Alternatives Rejected |
|-----------|-----------|---------------------|
| Framework | Flutter | React Native, Xamarin, Native |
| State | BLoC | Riverpod, Provider, GetX |
| Navigation | go_router | Navigator 2.0, Auto_route |

### Backend Stack (LOCKED)

| Component | Technology | Alternatives Rejected |
|-----------|-----------|---------------------|
| Language | Go | Node.js, Java, Python |
| Framework | Gin | Express, Spring, Django |
| Database | PostgreSQL + PostGIS | MongoDB, MySQL |
| Cache | Redis | Memcached |

### Infrastructure (LOCKED)

| Component | Technology | Alternatives Rejected |
|-----------|-----------|---------------------|
| Payment | Midtrans | Stripe, Xendit |
| Auth | Google Sign-In | Email/password, Apple |

**See `09_architecture_decisions.md` for rationale.**

---

## 📊 ENTITY STATE MACHINES

### Mandatory Compliance

All entities MUST follow state machines in `11_state_machines.md`:

| Entity | States | Key Transitions |
|--------|-------|----------------|
| **User** | NEW → UNAUTHENTICATED → AUTHENTICATED → DISABLED | Login, logout |
| **Event** | DRAFT → PUBLISHED → STARTED → ENDED → CANCELLED | Publish, start |
| **Ticket** | RESERVED → ACTIVE → USED → EXPIRED | Buy, check-in |
| **Order** | PENDING → PROCESSING → SUCCESS/FAILED | Payment flow |
| **Post** | DRAFT → PUBLISHED → HIDDEN → DELETED | Create, hide, delete |

### Why This Matters

**Frontend + Backend must agree on states.** If they disagree → Bugs.

Example: If frontend allows ticket purchase when event.state = ENDED, but backend rejects it → Inconsistent state → Bug.

**Rule**: Always check `11_state_machines.md` before implementing logic.

---

## 🚨 SCOPE CREEP PREVENTION

### Red Flags

If you find yourself saying:
- "Wouldn't it be cool if..."
- "This is just a small addition..."
- "Users might expect..."
- "It's easy to add..."

→ STOP. Check `10_non_goals.md`. If not there, it's V2.

### Feature Request Process

```
1. User/Agent proposes feature
2. Check 10_non_goals.md
3. If V1 → Reject with reference
4. If not listed → Check V1 scope
5. If V2 → Add to 10_non_goals.md
6. Get approval before implementing
```

---

## 📋 AGENT CHECKLIST

### Before Starting Work

- [ ] Read CLAUDE.md (navigator hub)
- [ ] Read relevant BLUEPRINT files
- [ ] Check if feature is in V1 scope
- [ ] Check state machine for entity
- [ ] Follow coding standards

### Before Proposing Changes

- [ ] Check 09_architecture_decisions.md (is choice locked?)
- [ ] Check 10_non_goals.md (is it V2?)
- [ ] Check 11_state_machines.md (state change allowed?)
- [ ] Prepare ADR if challenging locked decision
- [ ] Get Project Owner approval

### Before Coding

- [ ] Read relevant flow file
- [ ] Read state machine rules
- [ ] Follow coding standards
- [ ] Add test keys to widgets
- [ ] Write/update tests

---

## 🎯 SUCCESS METRICS

### Product Goals

- Open app → See events in **5 seconds**
- Decide to attend → Buy ticket in **2 minutes**
- Arrive at event → Check-in in **10 seconds**

### Quality Goals

- **90%+** Appium test coverage on critical flows
- **0** critical bugs in production
- **100%** state machine compliance
- **0** scope creep (no V1 feature additions)

---

## 📝 VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2025-01-28 | Initial blueprint |
| v2.0 | 2025-01-28 | Modular structure |
| **v3.0** | **2025-01-28** | **Governance controls added** |

---

## 🔗 QUICK REFERENCE

| I need to... | Go to... |
|---------------|----------|
| Understand WHY | [`01_vision.md`](./01_vision.md) |
| Implement screen | [`02_user_flows/`](./02_user_flows/) |
| Integrate API | [`03_api_contracts.md`](./03_api_contracts.md) |
| Create entity | [`04_data_models.md`](./04_data_models.md) |
| Handle edge case | [`05_business_rules.md`](./05_business_rules.md) |
| Create file | [`06_file_organization.md`](./06_file_organization.md) |
| Write code | [`08_coding_standards.md`](./08_coding_standards.md) |
| Run tests | [`07_qa_strategy.md`](./07_qa_strategy.md) |
| Challenge decision | [`09_architecture_decisions.md`](./09_architecture_decisions.md) |
| Check if feature | [`10_non_goals.md`](./10_non_goals.md) |
| Check state rules | [`11_state_machines.md`](./11_state_machines.md) |

---

## 💬 GETTING HELP

### Finding Information

1. **Search BLUEPRINT folder** - Answer is likely there
2. **Check CLAUDE.md** - Navigate to right section
3. **Check related files** - Linked in BLUEPRINT

### Reporting Issues

1. Check if it's covered in blueprint
2. Check if it violates state machine
3. Document in relevant file
4. Report with context

---

## 🏁 REMEMBER

> **"A good blueprint is clear about what it IS and what it IS NOT."**

This blueprint tells you:
- ✅ What we're building (V1 scope)
- ✅ How to build it (standards, patterns)
- ✅ What NOT to do (non-goals, locked decisions)
- ✅ What states are legal (state machines)

**Follow it. Don't fight it. Improve it through proper channels.**

---

**MAINTAINED BY**: Project Owner (Human)
**AUTHORITY**: Project Owner has final say on all decisions
**LAST UPDATED**: 2025-01-28
**PURPOSE**: Production blueprint with governance controls

**Remember**: This document is authoritative. If something is not here, it doesn't exist in V1.
