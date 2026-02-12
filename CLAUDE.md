# ANIGMAA - CLAUDE.md

**Production Blueprint Navigator**

---

## 📍 YOU ARE HERE

This file is your **navigation hub** for everything Anigmaa.

**Quick Start**:
1. New to project? → Read **Project Context** below
2. Working on feature? → Go to **BLUEPRINT/** folder
3. Writing code? → Check **Standards & Patterns**
4. Running QA? → Check **QA Strategy**

---

## 🗂️ BLUEPRINT FOLDER STRUCTURE

```
BLUEPRINT/
├── README.md                    # START HERE - Blueprint overview
├── 01_vision.md                 # Product vision, scope, success metrics
├── 02_user_flows/               # Complete user flows (6 flows)
│   ├── README.md                 # Flow index & navigation graph
│   ├── flow_01_new_user.md       # First time user journey
│   ├── flow_02_home.md           # Home & discover experience
│   ├── flow_03_event.md          # Event & ticket purchase
│   ├── flow_04_profile.md        # Profile & settings
│   ├── flow_05_social.md         # Social features
│   └── flow_06_edge_cases.md     # Error handling
├── 03_api_contracts.md           # All API endpoints with schemas
├── 04_data_models.md             # Entity & model definitions
├── 05_business_rules.md          # Business logic & constraints
├── 06_file_organization.md       # File structure & conventions
├── 07_qa_strategy.md            # Testing requirements & reports
├── 08_coding_standards.md       # BLoC, navigation, patterns
├── 09_architecture_decisions.md  # 🔒 Locked technology choices
├── 10_non_goals.md              # ❌ Out of scope features
└── 11_state_machines.md        # 📊 Entity states & transitions
```

---

## 🎯 QUICK REFERENCE

| I want to... | Go to... |
|--------------|----------|
| Understand product goals | [`01_vision.md`](BLUEPRINT/01_vision.md) |
| Implement a screen | [`02_user_flows/`](BLUEPRINT/02_user_flows/) |
| Integrate API | [`03_api_contracts.md`](BLUEPRINT/03_api_contracts.md) |
| Create data model | [`04_data_models.md`](BLUEPRINT/04_data_models.md) |
| Handle edge cases | [`05_business_rules.md`](BLUEPRINT/05_business_rules.md) |
| Create new file | [`06_file_organization.md`](BLUEPRINT/06_file_organization.md) |
| Write code | [`08_coding_standards.md`](BLUEPRINT/08_coding_standards.md) |
| Run tests | [`07_qa_strategy.md`](BLUEPRINT/07_qa_strategy.md) |
| Challenge decision | [`09_architecture_decisions.md`](BLUEPRINT/09_architecture_decisions.md) |
| Check if feature | [`10_non_goals.md`](BLUEPRINT/10_non_goals.md) |
| Check state rules | [`11_state_machines.md`](BLUEPRINT/11_state_machines.md) |

---

## 📋 PROJECT CONTEXT

### What is Anigmaa?

**Social media untuk orang gabut yang ingin tahu ada apa di sekitar sini.**

**Core Flow**: Open app → See nearby events → Buy ticket → Check-in

**V1 Scope**:
- ✅ Google Sign In only
- ✅ Event discovery by location
- ✅ Social feed
- ✅ Buy ticket (Midtrans)
- ✅ QR check-in
- ❌ Email/password (V2)
- ❌ Communities (V2)
- ❌ Host analytics (V2)

### Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter ^3.9.2, BLoC ^9.0.0, go_router ^14.2.0 |
| Backend | Go 1.21, Gin, PostgreSQL + PostGIS, Redis |
| Payment | Midtrans SDK |
| Auth | Google Sign-In |

### Architecture

```
Flutter App (Clean Architecture)
    ↓ HTTP
Go Backend (Microservices)
    ↓ SQL
PostgreSQL + PostGIS
```

---

## 🚀 NOW (V1) - Active Development

### Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Frontend | 🟡 In Progress | Core screens exist, needs keys |
| Backend | 🟡 In Progress | API defined, not running |
| Tests | 🔴 Not Started | Appium setup done, need tests |
| Docs | 🟢 Complete | BLUEPRINT folder complete |

### Immediate Tasks

| Priority | Task | Owner | Status |
|----------|------|-------|--------|
| P0 | Add test keys to all screens | Agent | 🔴 Todo |
| P0 | Implement Appium tests | Agent | 🔴 Todo |
| P0 | Fix profile completion bug | Agent | 🟡 Done |
| P1 | Start backend server | DevOps | 🔴 Todo |
| P1 | Implement photo upload | Agent | 🔴 Todo |

### This Week's Focus

1. **Complete Auth Flow** → Appium tests pass
2. **Complete Event Flow** → Appium tests pass
3. **Backend Running** → Can do E2E tests

---

## 🔮 FUTURE (V2) - Not Now

| Feature | Status | Target |
|---------|--------|--------|
| Email/password login | ❌ Not Started | V2 Q2 |
| Communities | ❌ Not Started | V2 Q3 |
| Real-time updates | ❌ Not Started | V2 Q3 |
| Host analytics | ❌ Not Started | V2 Q4 |
| Ticket transfer | ❌ Not Started | V2 Q2 |
| Refund system | ❌ Not Started | V2 Q2 |

**Note**: These are explicitly OUT of V1 scope. Do not work on them.

---

## 📚 AGENT ONBOARDING

### For New Agents

**Step 1**: Read this file (CLAUDE.md)
**Step 2**: Read [`BLUEPRINT/README.md`](BLUEPRINT/README.md)
**Step 3**: Skim [`01_vision.md`](BLUEPRINT/01_vision.md)
**Step 4**: Read relevant flow file in [`02_user_flows/`](BLUEPRINT/02_user_flows/)
**Step 5**: Check [`08_coding_standards.md`](BLUEPRINT/08_coding_standards.md)
**Step 6**: Start working

### For Returning Agents

**Context Lost?**
1. Re-read this file
2. Check [`BLUEPRINT/README.md`](BLUEPRINT/README.md) for structure
3. Check **Immediate Tasks** above
4. Resume work

---

## 🔧 DEVELOPMENT COMMANDS

### Frontend

```bash
cd anigmaa

# Run app
flutter run

# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .

# Build APK
flutter build apk
```

### Backend

```bash
cd backend_anigmaa

# Run server
go run cmd/server/main.go

# Run tests
go test ./...

# Generate Swagger
swag init
```

### Appium Tests

```bash
cd anigmaa

# Start Appium
appium

# Run tests
flutter drive --target=test_driver/tests/01_auth_flow_test.dart
```

---

## 📁 KEY FILES TO KNOW

| File | Purpose |
|------|---------|
| `CLAUDE.md` | This file - navigation hub |
| `BLUEPRINT/README.md` | Blueprint index |
| `BLUEPRINT/03_api_contracts.md` | All API endpoints |
| `anigmaa/lib/main.dart` | App entry point |
| `anigmaa/lib/injection_container.dart` | DI setup |
| `anigmaa/lib/core/config/` | App configuration |
| `backend_anigmaa/cmd/server/main.go` | Backend entry point |

---

## ⛔ HARD RULES FOR AGENTS

- DO NOT add new features outside V1 scope
- DO NOT refactor architecture without updating BLUEPRINT
- DO NOT change API contracts unilaterally
- DO NOT introduce new state management
- DO NOT “improve” UX flows outside spec

## 🎯 SUCCESS METRICS (V1)

### Product Goals

- User opens app → Sees nearby events within **5 seconds**
- User decides to attend → Buys ticket within **2 minutes**
- User arrives → Check-in success within **10 seconds**

### Technical Goals

- **90%+** Appium test coverage on critical flows
- **0** critical bugs in production
- **< 3s** 95th percentile API response time
- **< 100ms** Screen transition time

---

## 📝 CHANGE LOG

### 2025-01-28 - v3.0: Governance Controls

**Changes**:
- Added `BLUEPRINT/09_architecture_decisions.md` - Locked technology choices
- Added `BLUEPRINT/10_non_goals.md` - Out of scope features
- Added `BLUEPRINT/11_state_machines.md` - Entity states & legal transitions
- Updated BLUEPRINT/README.md with governance sections
- Authority changed from "CTO Mindset (Claude)" to "Project Owner (Human)"

**Reason**:
- Add governance controls to prevent scope creep
- Lock down architecture decisions
- Make state machines mandatory for frontend/backend alignment

### 2025-01-28 - v2.0: Modular Blueprint

**Changes**:
- Converted single CLAUDE.md to modular structure
- Created `BLUEPRINT/` folder with 8 detailed files
- Separated concerns: vision, flows, API, models, rules, files, QA, standards

**Reason**:
- Better maintainability
- Easier for agents to find specific info
- Production-ready documentation

### 2025-01-28 - v1.0: Initial Blueprint

**Created**:
- Single CLAUDE.md with all information
- User flow definitions
- Tech stack overview

---

## 🔗 QUICK LINKS

- **Blueprint**: [`BLUEPRINT/README.md`](BLUEPRINT/README.md)
- **Vision**: [`BLUEPRINT/01_vision.md`](BLUEPRINT/01_vision.md)
- **Flows**: [`BLUEPRINT/02_user_flows/README.md`](BLUEPRINT/02_user_flows/README.md)
- **API**: [`BLUEPRINT/03_api_contracts.md`](BLUEPRINT/03_api_contracts.md)
- **Models**: [`BLUEPRINT/04_data_models.md`](BLUEPRINT/04_data_models.md)
- **Rules**: [`BLUEPRINT/05_business_rules.md`](BLUEPRINT/05_business_rules.md)
- **Files**: [`BLUEPRINT/06_file_organization.md`](BLUEPRINT/06_file_organization.md)
- **QA**: [`BLUEPRINT/07_qa_strategy.md`](BLUEPRINT/07_qa_strategy.md)
- **Standards**: [`BLUEPRINT/08_coding_standards.md`](BLUEPRINT/08_coding_standards.md)
- **Architecture Decisions**: [`BLUEPRINT/09_architecture_decisions.md`](BLUEPRINT/09_architecture_decisions.md) 🔒
- **Non-Goals**: [`BLUEPRINT/10_non_goals.md`](BLUEPRINT/10_non_goals.md) ❌
- **State Machines**: [`BLUEPRINT/11_state_machines.md`](BLUEPRINT/11_state_machines.md) 📊

---

## 💬 GETTING HELP

### Stuck on something?

1. **Read relevant BLUEPRINT file** - Answer likely there
2. **Search codebase** - Check similar existing code
3. **Ask specific question** - Include context

### Found an issue?

1. **Check BLUEPRINT/05_business_rules.md** - Might be edge case
2. **Check BLUEPRINT/03_api_contracts.md** - API might return error
3. **Document in BLUEPRINT/** - Update if needed

---

## 🏁 NEXT ACTIONS

| For You | Action |
|---------|--------|
| **New Agent** | Read BLUEPRINT/README.md, then 01_vision.md |
| **Implementing Screen** | Read flow file in 02_user_flows/ |
| **Backend Integration** | Check 03_api_contracts.md |
| **Writing Code** | Follow 08_coding_standards.md |
| **Testing** | Check 07_qa_strategy.md |
| **Context Lost** | Read this file, then BLUEPRINT/README.md |

---

**LAST UPDATED**: 2025-01-28
**MAINTAINED BY**: Project Owner (Human)
**PURPOSE**: Navigation hub for Anigmaa development

**Remember**: When in doubt, check BLUEPRINT. When coding, follow standards. When stuck, ask questions.
