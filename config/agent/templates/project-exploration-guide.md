# Project Exploration Strategy Template

> **Copy this file into your project and customize it.**
> Suggested path: `docs/exploration-strategy.md`
> Based on: `EXPLORATION_STRATEGY.md`

---

## [PROJECT_NAME] Exploration Strategy

**Project:** [Your Project Name]
**Tech Stack:** [e.g. Flutter/Dart, TypeScript/React, Python/Django, Go/gRPC]
**Status:** Active / Mandatory
**Last Updated:** [Date]

---

## Overview

Everyone working on **[PROJECT_NAME]** (humans and agents) follows this strategy to explore the codebase cheaply and accurately.

### Key principle
**Map first, then search scoped, then read only what you need.**

1. ✅ **Map** — `ls`, `find -maxdepth`, read `AGENTS.md`
2. ✅ **Scope** — `rg -n "symbol" <directory> -t <type>`, `rg -l` for file lists
3. ✅ **Read/verify** — `rg -n ... -A 20` or the read tool with offset/limit

**Result:** fewer tokens, faster orientation, fewer missed call sites.

---

## The Three-Step Hierarchy

### Step 1: Map the structure

```bash
ls -la
find . -maxdepth 3 -type d -not -path "*/node_modules/*" -not -path "*/.git/*"
[ -f AGENTS.md ] && cat AGENTS.md
```

### Step 2: Scoped search

```bash
# Matches inside one directory, filtered by language, output capped
rg -n "SymbolName" lib/features/<feature>/ -m 10

# File lists only (usually what you want before a change)
rg -l "SymbolName" lib/ -g '*.dart'
```

### Step 3: Read and verify

```bash
rg -n "methodName" -A 20 lib/features/<feature>/<file>.dart
# or: read tool with offset/limit
```

---

## Project-Specific Examples

### Common search 1: [EXAMPLE_1]

**Goal:** [Describe what you want to find]

**❌ Wrong approach:**
```bash
grep -r "pattern" lib/
```

**✅ Right approach:**
```bash
rg -l "pattern" lib/ -g '*.dart'          # where is it?
rg -n "pattern" lib/<module>/ -m 10 -C 2  # how is it used?
rg -n "pattern" -A 20 lib/<module>/<file>.dart   # implementation
```

**Expected result:** [Describe what good results look like]

---

### Common search 2: [EXAMPLE_2]

**Goal:** [Describe]

**Commands:**
```bash
rg -l "<symbol>" <path> -g '<glob>'
rg -n "<symbol>\(" <path> -g '<glob>'
```

**Result:** [Expected output]

---

### Common search 3: [EXAMPLE_3]

**Goal:** [Describe]

**Commands:**
```bash
rg -l "<existing-test-name>" . -g '*test*'
```

**Result:** [Expected output]

---

## Tech Stack Specifics

### [Language/Framework]

**Where things live:**
- [Layer/dir 1] — [what it contains]
- [Layer/dir 2] — [what it contains]

**Naming conventions to exploit when searching:**
- [Convention 1, e.g. `*_cubit.dart` for state management]
- [Convention 2, e.g. `**.repository.ts` for data access]
- [Convention 3]

**Globs worth remembering:**
- `-g '*.dart'`, `-t ts`, `-t py`, `-g '*_test.go'`

**Example patterns:**
- `"class <Feature>Cubit"` — find state manager
- `"context.l10n\."` — find translated UI strings
- `"<feature>/data/datasources"` — find data access

---

## Repository Structure Quick Reference

```
[PROJECT_NAME]/
├── [Directory1]/
│   ├── [Pattern1]
│   └── [Pattern2]
├── [Directory2]/
│   ├── [Tests]
│   └── [Configs]
└── docs/
    └── exploration-strategy.md  # (this file)
```

**Key conventions:**
- [Convention 1]
- [Convention 2]
- [Convention 3]

---

## Team Standards

### Mandatory rules
1. Never search the whole repo with a bare `rg`/`grep -r`.
2. Scope every search to a directory and filter by file type.
3. Use `rg -l` to list files before a change; check all call sites.
4. Read files completely only when you are going to modify them.
5. Check tests before assuming behavior.

### Budget discipline
- Expected tokens per exploration task: **80–150**
- If an output exceeds ~150 lines, narrow the path or add a type filter.

### Durable learnings
When the team agrees on a reusable convention, record it as project documentation (or an ADR) so it is not re-discovered by every new agent session.

---

## Troubleshooting

### Q: My scoped search returns nothing

**A:** Try these:
1. Widen the directory one level (`lib/features/` instead of `lib/features/orders/`)
2. Search by a shorter concept word instead of an exact symbol
3. Drop the type filter to see whether the pattern exists in another language
4. Check spelling and casing — most codebases are camelCase for members, PascalCase for types

### Q: I need to find something but don't know where

**A:** Map first, then search by naming convention:
```bash
find lib -maxdepth 2 -type d                       # structure
rg -l "<short concept>" lib/ -g '*.dart'           # candidate files
rg -n "<short concept>" lib/<candidate>/ -m 10     # usage
```

### Q: Can I use a recursive grep?

**A:** Only with `-l` and after narrowing to a subtree. Never over the repository root.

---

## Related Resources

- **Generic Exploration Guide:** [`EXPLORATION_STRATEGY.md`](../EXPLORATION_STRATEGY.md)
- **Engineering standards:** [`BEST_PRACTICES.md`](../BEST_PRACTICES.md)
- **Project README:** [Link to main README]

---

## Contributing

Found a new pattern or optimization?

1. Test it and note the token impact
2. Document it here with a before/after example
3. Submit a PR or share it with the team

---

## Version History

| Date | Changes | Author |
|------|---------|--------|
| [DATE] | Initial version | [Your Name] |

---

**For questions:** [PROJECT_CONTACT] — or see the generic [`EXPLORATION_STRATEGY.md`](../EXPLORATION_STRATEGY.md)
