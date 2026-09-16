# Codebase Exploration Strategy (Generic)

> **Universal guide for all projects.**
> Reference this from your project's `docs/EXPLORATION_STRATEGY.md` or similar.

---

## Core Rule: Narrow Before You Search

**Status:** Best practice / recommended
**Scope:** All codebase exploration, analysis and refactoring tasks

Never start with a recursive search over the whole repo. Narrow the scope first (structure, entry points, naming conventions), then search inside that scope, then read only the files that matter.

---

## The Three-Step Hierarchy

### Step 1: Map the Structure (Cheap, Always First)

Start from the shape of the project, not from a broad regex.

```bash
# Top-level layout
ls -la

# Source tree without noise
find . -type d -not -path "*/node_modules/*" -not -path "*/.git/*" -maxdepth 3

# Check the project's own guide first
[ -f AGENTS.md ] && cat AGENTS.md
```

**When to use:**
- First contact with a repository or an unknown area
- Before any `rg` you cannot scope to a directory
- Deciding where the relevant layer lives (domain, api, ui, infra)

**Advantages:**
- ✅ Cheap: a few hundred tokens, full-repo orientation
- ✅ Reveals naming and layer conventions you can exploit later
- ✅ Avoids searching code that is generated, vendored or legacy

---

### Step 2: Scoped Search (Default Workhorse)

Once you know the directory or the symbol name, search with a bounded scope and a bounded output.

```bash
# ✅ CORRECT: known directory + file type filter
rg "createOrder" src/orders/ -t ts

# ✅ CORRECT: locate a definition, files only
rg -l "class AuthService" src/ --type-add 'src:*.{ts,tsx}'

# ✅ CORRECT: cap the output
rg "updateStatus" src/orders/ -m 5 -C 2

# ✅ CORRECT: find the call sites of a symbol
rg "authenticate\(" src/ -n --no-heading
```

**When to use:**
- You know the concept name (class, function, config key, route, i18n key)
- You need the call sites of a known symbol before changing it
- You need file lists (use `-l`) instead of matching lines

**Practical rules:**
- Always pass a path: `rg pattern src/module/` — never `rg pattern .`
- Filter by type (`-t ts`, `-t py`, `-t dart`, `-g '*.go'`) to cut generated output
- Cap matches (`-m`) when the pattern is common
- Prefer `-l` when you only need to know *where* something is

---

### Step 3: Read and Verify (Only What You Need)

```bash
# Read a symbol with context instead of the whole file
rg -n "updateOrderStatus" -A 20 src/orders/cubit.dart

# Then read the file region you care about
# (use the read tool with offset/limit)
```

**When to use:**
- Confirming the exact signature, default value or error message
- Reviewing the implementation before editing it
- Building the change list for a refactor

Read files completely **only** when you are about to modify them or when the file is short. Otherwise read targeted regions with offset/limit.

---

## Anti-Patterns ❌

```bash
# ❌ Unbounded recursive search across the repo
rg "status"

# ❌ Whole-repo grep piped into another grep
grep -r "import" src/ | grep "auth"

# ❌ Listing everything and hoping to spot the right file
ls -R . | grep auth

# ❌ Reading five full files "just in case"
# (burns 5–20k tokens for a 200-token answer)
```

**Why these are bad:**
- 📊 Hundreds of unrelated matches drown the signal
- 💰 Large outputs are re-sent with every following turn
- 🎯 No clear goal means no way to stop searching

---

## Tool Comparison Matrix

| Goal | Tool | Scope discipline | Typical tokens |
|------|------|------------------|----------------|
| Orient in a new repo | `ls`, `find -maxdepth`, read `AGENTS.md` | Whole repo, shallow | 200–500 |
| Find a known symbol | `rg -l` / `rg -n` in one directory | One directory | 30–100 |
| Find call sites before a change | `rg "name\(" src/ -n` | One subtree | 50–150 |
| Read a symbol with context | `rg -n "name" -A 20 file` | One file | 50–150 |
| Read a file to edit it | read tool (offset/limit) | One file | 200–2000 |
| Whole-repo grep | — | ❌ AVOID | 1000+ |

---

## Real-World Examples

### Example 1: TypeScript/Node.js Backend

**❌ The wrong way**
```bash
grep -r "authenticate" src/
grep -r "userId" src/
find src/ -name "*auth*" -type f
```
Result: 300+ lines, no context, tokens wasted.

**✅ The right way**
```bash
ls src/services/                       # map the layer
rg -n "authenticate" src/services/ -t ts   # scoped
rg "authenticate\(" src/ -l -t ts      # all call sites, files only
# then read src/services/auth.ts (offset/limit) before editing
```

---

### Example 2: Python Data Pipeline

**❌ The wrong way**
```bash
grep -r "def process" src/
find . -name "*pipeline*" -type f
```

**✅ The right way**
```bash
find src -maxdepth 2 -type d           # structure
rg -n "def process_data" src/processors/ -t py
rg "Transformer|process_data" src/ -l -t py
```

---

### Example 3: Go Microservice

**❌ The wrong way**
```bash
grep -r "Handler" .
find . -name "*.go" | xargs grep error
```

**✅ The right way**
```bash
rg -n "func.*Handler" handler/ -t go
rg "authHandler\(" . -t go -l
rg -n "HandleFunc|middleware" cmd/ -t go -m 10
```

---

### Example 4: Navigating With Tests

Tests are the cheapest specification available.

```bash
rg -l "createOrder" . -g '*_test.go'      # Go
rg -l "createOrder" . -g '*.test.ts'      # TS/JS
rg -l "createOrder" . -g '*_test.py'      # Python
rg -l "createOrder" . -g '*_test.dart'    # Dart
```

Then read the test that covers the behavior you are about to change.

---

## Budget Discipline

| Scenario | Anti-pattern | Disciplined approach |
|----------|--------------|----------------------|
| Locate a feature | `rg` over the repo (1000+ tokens) | `rg -l` in one layer (30–80) |
| Understand impact | read every importer | `rg "symbol\(" -l` then read 1–2 call sites |
| Debug an integration | many broad searches | read the failing test + the narrow path |
| Refactor a module | grep everything | map the layer → `rg -l` call sites → edit |

**Practical threshold:** if your output exceeds ~150 lines, you are searching too broadly. Narrow the path or add a type filter and try again.

---

## When to Delegate

For genuinely wide exploration (a new large repo, an unfamiliar subsystem), delegate to a subagent with `defaultContext: fork`:

- Keep the noisy exploration out of the main session context.
- Ask the subagent for a short structural summary plus file paths, not file dumps.
- Use the result to run the scoped searches above yourself.

---

## Implementation Checklist

For **any** codebase exploration task:

- [ ] Did I map the structure before searching (`ls`, `find -maxdepth`, `AGENTS.md`)?
- [ ] Is every `rg` scoped to a directory and filtered by type?
- [ ] Did I cap the output (`-m`) or use `-l` when I only need locations?
- [ ] Did I read only the files/regions needed for the next action?
- [ ] Did I check tests to confirm expected behavior?
- [ ] Did I avoid whole-repo recursive greps?

---

## Decision Tree

```
Need to find something in the codebase?
  ↓
Do you know the layer/directory?  ── No ──▶ Step 1: map structure (ls / find -maxdepth)
  │ Yes
  ▼
Do you know the symbol/string?    ── No ──▶ list candidate files (rg -l with a broader pattern + type filter)
  │ Yes
  ▼
Step 2: rg -n in that directory, type filter, output capped
  ↓
Need the implementation details?  ──▶ Step 3: rg -n with -A/-B context, or read offset/limit
  ↓
About to change it?               ──▶ rg "symbol\(" -l to list all call sites first
  ↓
Done ✓
```

---

## FAQ

**Q: I already know the exact file. Why not just read it whole?**
A: Read it whole if you are going to edit it. If you only need one function, `rg -n "name" -A 20` is 5–10x cheaper.

**Q: `rg` is not installed. What do I use?**
A: `grep -rn` works; keep the same discipline: scoped path, `--include='*.ts'`, and a limited output.

**Q: What if the search returns too much?**
A: Add a type filter, move to a narrower directory, or switch to `-l` and open one file.

**Q: Is a broad search ever acceptable?**
A: Only when it is genuinely the first step and the string is unique (a rare config key, an error code, a Spanish/English message). Even then, use `-l`.

**Q: Why is this better for teams?**
A: Consistency. Everyone narrows first, so reviews are predictable and token usage does not explode.

---

## Quick Reference Card

```bash
# 1. MAP
ls -la && find . -maxdepth 3 -type d -not -path "*/node_modules/*"
[ -f AGENTS.md ] && cat AGENTS.md

# 2. SCOPE
rg -n "symbol" src/module/ -t ts -m 10      # find matches
rg "symbol\(" src/ -l -t ts                 # find files (call sites)

# 3. VERIFY / READ
rg -n "symbol" -A 20 src/module/file.ts
# or: read tool with offset/limit
```

---

## For Project Maintainers

1. **Reference in your README:**
   ```markdown
   ## Exploration Guidelines
   See [Exploration Strategy](docs/exploration-strategy.md) before searching the codebase.
   ```

2. **Reference in the contributing guide:**
   ```markdown
   Contributors: map the structure first, then run scoped searches (see Exploration Strategy).
   ```

3. **Train your team:**
   - Share this guide
   - Review search patterns in PRs
   - Point out whole-repo greps when they appear

---

**Last updated:** June 2026
**Status:** Generic best practice (recommended for all projects)
