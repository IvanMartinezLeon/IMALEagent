# IML: Index & Quick Navigation

> **Implementation & Learning Guidelines for IMALE Projects**

---

## 📊 Folder Structure

```
iml/
├── README.md                           ⭐ Start here - Overview & quick links
├── INDEX.md                            ← You are here
├── GENERIC_RULES.md                    📐 Working rules for any project (always applies)
├── MOBILE_GUIDELINES.md                📱 What a mobile spec must cover
├── EXPLORATION_STRATEGY.md             🔍 Generic exploration guide (all projects)
├── BEST_PRACTICES.md                   ✅ Engineering standards (all projects)
├── templates/
│   ├── SPEC_TEMPLATE.md                📋 Spec template (copy as SPEC.md)
│   ├── PLAN_TEMPLATE.md                📋 Technical plan template (copy as PLAN.md)
│   ├── project-exploration-guide.md    📋 Copy & customize for your project
│   └── project-standards.md            📋 (Coming soon) Project-specific rules
├── skills/
│   ├── flutter-guidelines/             🐦 Flutter application standards
│   └── dart-guidelines/                🎯 Dart code quality standards
├── prompts/
│   └── spec-mobile.md                  🚀 /spec-mobile — start a mobile specification
└── examples/
    ├── exploration-flutter-keko.md     💡 Real example: Flutter/Keko project
    └── exploration-generic.md          💡 (Coming soon) Generic template example
```

---

## 🎯 Choose Your Path

### 👤 I'm a Developer (First Time Here)

1. **Read:** [`README.md`](README.md) — Get oriented (5 min)
2. **Read:** [`GENERIC_RULES.md`](GENERIC_RULES.md) — How we work on any task (5 min)
3. **Read:** [`EXPLORATION_STRATEGY.md`](EXPLORATION_STRATEGY.md) — Learn how to search (10 min)
4. **Reference:** [`BEST_PRACTICES.md`](BEST_PRACTICES.md) — Keep as guide (skim)
5. **Look:** [`examples/`](#examples) — See real examples (5 min)

**Time Needed:** ~20 minutes

---

### 🧭 I'm Starting a New Feature (or a Mobile App)

1. **Read:** [`GENERIC_RULES.md`](GENERIC_RULES.md) — working rules
2. **Copy:** [`templates/SPEC_TEMPLATE.md`](templates/SPEC_TEMPLATE.md) as `SPEC.md` in the feature folder
3. **Complete it with:** [`MOBILE_GUIDELINES.md`](MOBILE_GUIDELINES.md) (mobile) plus the `flutter-guidelines`/`dart-guidelines` skills
4. **Then:** copy [`templates/PLAN_TEMPLATE.md`](templates/PLAN_TEMPLATE.md) as `PLAN.md` and derive `TASKS.md`
5. **Shortcut:** type `/spec-mobile` inside Pi to start the whole flow
6. **Do not implement** until the spec is explicitly approved

**Time Needed:** ~30 minutes

---

### 🏢 I'm Setting Up a New Project

1. **Read:** [`README.md`](README.md) — Get oriented
2. **Copy:** [`templates/project-exploration-guide.md`](templates/project-exploration-guide.md) to your project's `docs/exploration-strategy.md`
3. **Customize:** Replace `[EXAMPLE_X]` placeholders with your project specifics
4. **Share:** Link team members to the customized guide
5. **Reference:** [`BEST_PRACTICES.md`](BEST_PRACTICES.md) for standards

**Time Needed:** ~30 minutes

---

### 🔍 I Need to Search the Codebase

1. **Go:** [`EXPLORATION_STRATEGY.md`](EXPLORATION_STRATEGY.md)
2. **Choose:** Follow the 3-step hierarchy:
   - ✅ Step 1: map the structure (`ls`, `find -maxdepth`, `AGENTS.md`)
   - ✅ Step 2: scoped search (`rg -n "symbol" <dir> -t <type>`, `rg -l` for file lists)
   - ✅ Step 3: read/verify (`rg -n -A 20` or the read tool with offset/limit)
3. **Result:** Fewer tokens, faster orientation, fewer missed call sites

**Quick Reference:** See [Quick Reference Card](#quick-reference-card) below

---

### 📚 I'm Reviewing Code

1. **Check:** [`BEST_PRACTICES.md`](BEST_PRACTICES.md) — Does it follow standards?
2. **Use:** [`EXPLORATION_STRATEGY.md`](EXPLORATION_STRATEGY.md) — Did they search efficiently?
3. **Suggest:** Reference the appropriate section in your feedback

---

### 📝 I Found a Pattern Worth Documenting

1. **Add to:** the project's `docs/` folder or the IML templates
2. **Format:** rule + when it applies + prefer/avoid
3. **Share:** tell the team about it

---

## 📖 File Descriptions

| File | Purpose | Audience | Time |
|------|---------|----------|------|
| **README.md** | Overview, structure, getting started | Everyone | 5 min |
| **GENERIC_RULES.md** | Working rules: scope, code, data, validation, docs | Everyone | 10 min |
| **MOBILE_GUIDELINES.md** | What a mobile spec must cover | Mobile devs, analysts | 10 min |
| **EXPLORATION_STRATEGY.md** | How to search codebases efficiently | Developers, all projects | 15 min |
| **BEST_PRACTICES.md** | Engineering standards across languages | Leads, reviewers | 20 min |
| **templates/SPEC_TEMPLATE.md** | Copy as `SPEC.md` and complete with the user | Devs, analysts | 15 min |
| **templates/PLAN_TEMPLATE.md** | Copy as `PLAN.md` after the spec is approved | Devs, leads | 20 min |
| **templates/project-exploration-guide.md** | Copy this to your project, customize | Project leads | 10 min |
| **skills/flutter-guidelines** | Flutter application standards | Flutter devs | 15 min |
| **skills/dart-guidelines** | Dart code quality standards | Dart devs | 15 min |
| **examples/exploration-flutter-keko.md** | Real-world example with Keko/Flutter | Flutter devs, teams | 10 min |

---

## 🚀 Quick Reference Card

**Every codebase search follows this:**

```bash
# Step 1: Map the structure (cheap orientation)
ls -la && find . -maxdepth 3 -type d -not -path "*/node_modules/*"

# Step 2: Scoped search (know the directory and the symbol)
rg -n "symbol" path/to/module/ -t ts -m 10
rg "symbol\(" path/ -l -t ts        # file lists / call sites

# Step 3: Read and verify (only what you need)
rg -n "symbol" -A 20 path/to/file.ts
```

---

## 🔗 Quick Links

### Core Resources
- **IMALEagent Main:** `../README.md` (main repo)
- **Keko Project:** Example Flutter project following these standards

### External
- **Flutter i18n:** https://flutter.dev/docs/development/accessibility-and-localization/internationalization
- **Clean Architecture:** Uncle Bob's Architecture
- **Semantic Versioning:** https://semver.org/

---

## ❓ FAQ

**Q: Where do I start?**  
A: Read [`README.md`](README.md) (5 min), then [`EXPLORATION_STRATEGY.md`](EXPLORATION_STRATEGY.md) (10 min).

**Q: What if my project is different?**  
A: Copy [`templates/project-exploration-guide.md`](templates/project-exploration-guide.md) and customize with your specifics.

**Q: Who maintains IML?**  
A: IMALE Engineering Leadership. Submit PRs for improvements.

**Q: How do I propose changes?**  
A: Create an issue or PR referencing this folder.

---

## 📈 Stats & Benefits

### Time Savings
- **Per search:** 60–80% fewer tokens
- **Per project:** ~30% overall token savings
- **Per team:** Consistent approach, faster onboarding

### Quality Improvements
- Fewer missed dependencies
- Better code understanding
- Reduced bugs from incomplete refactors
- Durable knowledge capture

---

## 📅 Version & Status

- **Created:** June 2026
- **Status:** Active, IMALE-wide
- **Last Updated:** June 2026
- **Maintainer:** IMALE Engineering

---

## 🎓 Learning Paths

### For Beginners
1. IML/README.md
2. IML/GENERIC_RULES.md
3. IML/EXPLORATION_STRATEGY.md
4. IML/examples/exploration-flutter-keko.md (if Flutter)
5. Practice with a real project

### For Leads
1. IML/README.md
2. IML/GENERIC_RULES.md
3. IML/EXPLORATION_STRATEGY.md
4. IML/BEST_PRACTICES.md
5. IML/MOBILE_GUIDELINES.md + SPEC/PLAN templates
6. Train your team

### For Architects
1. IML/BEST_PRACTICES.md
2. Review IML/ for patterns
3. Contribute improvements to the guides and templates

---

**Ready? Start with [`README.md`](README.md) → [`EXPLORATION_STRATEGY.md`](EXPLORATION_STRATEGY.md) → Practice!** 🚀
