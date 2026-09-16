# Keko (Flutter) Exploration Strategy — Example

> **Real-world example based on the Keko Flutter project.**
> Use it as a template for Flutter/Dart projects.

---

## Keko Project Exploration Strategy

**Project:** Keko Order Management (Flutter)
**Tech stack:** Flutter 3.12+, Dart, BLoC state management
**Key patterns:** Domain/Data/Presentation, Cubits, GoRouter navigation
**Status:** Active, mandatory for all agent work

---

## Key Concepts

### Architecture pattern
- **Clean Architecture** with feature-based organisation
- **Domain/Data/Presentation** layers per feature
- **BLoC/Cubit** for state management
- **GoRouter** with StatefulShellRoute for navigation

### Main features
```
lib/features/
├── auth/               # Authentication with Cubit
├── products/           # Product catalog with filtering
├── cart/               # Shopping cart (in-memory)
├── orders/             # Order management with status tracking
├── profile/            # User profile with order statistics
└── home/               # Dashboard with navigation
```

### Localization
- **Languages:** English, Spanish, Catalan (auto-selected by device)
- **System:** flutter_localizations + ARB files
- **Access:** `context.l10n.keyName` for all UI strings
- **Rule:** No untranslated text allowed in UI

---

## Common Searches & Examples

### Example 1: Understanding order status tracking

**Goal:** How are order states managed and how is history tracked?

**❌ Wrong way (wastes 300+ tokens):**
```bash
grep -r "status" lib/features/orders/
grep -r "OrderCubit" lib/
find lib/features/orders -name "*.dart" | xargs grep "state\|history"
```

**✅ Right way (uses ~80 tokens):**
```bash
# Step 1: locate the state manager and entity
rg -l "class OrderCubit" lib/features/orders/ -g '*.dart'
rg -n "statusHistory|class StatusChange" lib/features/orders/domain/ -m 5

# Step 2: find every consumer of OrderCubit before touching it
rg "OrderCubit" lib/ -l -g '*.dart'

# Step 3: verify the exact method (only if needed)
rg -n "updateOrderStatus" -A 20 lib/features/orders/presentation/cubits/order_cubit.dart
```

**Expected output:**
- `Order` entity with `List<OrderItem> items` and `List<StatusChange> history`
- `StatusChange` with `status`, `changedAt`, `note` fields
- `OrderCubit.updateOrderStatus(orderId, newStatus, {note})`
- `TimelineView` displaying history on `OrderDetailScreen`

---

### Example 2: Finding all translations (i18n keys)

**Goal:** Where are all user-facing strings defined, and how do I add a new translation?

**❌ Wrong way:**
```bash
grep -r "Text(" lib/features/*/presentation/
find lib -name "*.arb"
grep -r "context.l10n" lib/
```

**✅ Right way:**
```bash
# Step 1: find the localization files
rg -l "appLocalizationsDelegates|AppLocalizations" lib/ -g '*.dart'
ls lib/l10n/

# Step 2: find how strings are accessed
rg -n "extension.*BuildContext" lib/core/extensions/ -g '*.dart'

# Step 3: list a specific key across locales
rg -n "loginTitle" lib/l10n/ -g '*.arb'
```

**Expected output:**
- `lib/l10n/app_en.arb`, `app_es.arb`, `app_ca.arb` with all keys
- Extension `context.l10n` for easy access
- All screens use `context.l10n.keyName`
- `flutter gen-l10n` regenerates code after changes

**Pattern to remember:**
```dart
// Always use this in any UI:
Text(context.l10n.loginTitle)  // NOT Text('Welcome Back')

// Add new translations:
// 1. Add to lib/l10n/app_en.arb, app_es.arb, app_ca.arb
// 2. Run: flutter gen-l10n
// 3. Use: context.l10n.newKeyName in UI
```

---

### Example 3: Tracing a cart item through the system

**Goal:** What happens when a user adds a product to the cart? (from tap to screen update)

**❌ Wrong way:**
```bash
grep -r "addItem" lib/
grep -r "CartItem" lib/
grep -r "CartCubit" lib/
# Results: 50+ matches, no flow understanding
```

**✅ Right way:**
```bash
# Step 1: define the boundaries of the flow
rg -n "void addItem" -A 15 lib/features/cart/presentation/cubits/cart_cubit.dart
rg -l "class CartItem" lib/features/cart/domain/ -g '*.dart'

# Step 2: find all consumers of the cart state
rg "CartCubit" lib/ -l -g '*.dart'
rg -n "context.read<CartCubit>\(\)" lib/ -g '*.dart' -m 10
```

**Expected flow:**
1. User taps "Add to Cart" on a product → `_showAddToCartSheet()` bottom sheet
2. Selects quantity → confirms
3. `context.read<CartCubit>().addItem(product, quantity)` is called
4. `CartCubit` adds the `CartItem` to its state
5. `CartScreen` rebuilds with the new item
6. `ProductListScreen` badge updates (total items)

**Key files:**
- `lib/features/cart/domain/entities/cart_item.dart` — `CartItem` entity
- `lib/features/cart/presentation/cubits/cart_cubit.dart` — `addItem`, `updateQuantity`, `removeItem`
- `lib/main.dart` — `CartCubit` provided globally
- `lib/features/cart/presentation/screens/cart_screen.dart` — UI

---

### Example 4: Finding where order creation happens

**Goal:** How are orders created from cart items?

**❌ Wrong way:**
```bash
grep -r "createOrder" lib/
grep -r "Order(" lib/
find lib/features/orders -name "*datasource*"
```

**✅ Right way:**
```bash
# Step 1: find the creation entry point
rg -n "createOrderFromCart" lib/ -g '*.dart'

# Step 2: find what consumes orders
rg "OrderCubit" lib/ -l -g '*.dart'

# Step 3: locate the data source
rg -n "class OrderLocalDataSource" -A 10 lib/features/orders/data/datasources/
```

**Key methods:**
- `OrderCubit.createOrderFromCart(List<OrderItem> items)` — creates a new order
- `OrderCubit.updateOrderStatus(id, status, {note})` — changes order status
- `OrderCubit.cancelOrder(id)` — sets status to `Cancelled`
- `OrderLocalDataSource` — in-memory order storage with mock data

---

### Example 5: Checking localization coverage

**Goal:** Ensure all UI strings are translated (no hardcoded strings in screens)

**❌ Wrong way:**
```bash
grep -r "Text\(" lib/features/*/presentation/screens/
find lib -name "*.dart" -exec grep "Text('.*')" {} \;
```

**✅ Right way:**
```bash
# Step 1: find hardcoded strings (should return nothing if compliant)
rg "Text\('[^']" lib/features/*/presentation/screens/ -g '*.dart' -m 20

# Step 2: confirm localization usage per screen
rg -c "context\.l10n\." lib/features/*/presentation/screens/ -g '*.dart'
```

**Compliance rule:**
Every `Text()`, tooltip, hint, label and SnackBar message in the UI must use `context.l10n.key`.

```dart
// ✅ CORRECT
Text(context.l10n.loginTitle)
TextField(hintText: context.l10n.emailHint)
Tooltip(message: context.l10n.addToCartTooltip)

// ❌ WRONG (NOT ALLOWED)
Text('Login')
Text(AppConstants.title)
const Text('Button Label')
```

---

## Dart/Flutter-Specific Tips

### Cubit state changes
```bash
rg -n "emit\(" lib/features/<feature>/presentation/cubits/<cubit>_cubit.dart -m 20
```

### Widget consumers
```bash
rg "<CubitName>" lib/ -l -g '*.dart'
rg -n "BlocBuilder<|<CubitName>" lib/ -g '*.dart' -m 10
```

### Navigation routes
```bash
rg -n "GoRoute|StatefulShellRoute" lib/ -g '*.dart' -m 20
```

### Testing
```bash
rg -l "<feature>" test/ -g '*_test.dart'
rg -n "testWidgets|test\(" test/features/<feature>/ -m 20
```

---

## Token Budget Expectations

| Task | Expected tokens | Acceptable range |
|------|-----------------|------------------|
| Find feature implementation | 100 | 60–150 |
| Understand impact of a change | 100 | 80–150 |
| Trace data flow | 120 | 100–180 |
| Check test coverage | 90 | 70–130 |
| Add a new translation | 60 | 40–100 |

**If your search exceeds the range:** you probably searched too broadly. Narrow the path and add a `-g '*.dart'` filter.

---

## Keko-Specific Rules

### Rule 1: All UI text must be localized
- Use `context.l10n.keyName` for every visible string
- Add the key to `lib/l10n/app_en.arb`, `app_es.arb`, `app_ca.arb`
- Run `flutter gen-l10n` after changes
- **Violation:** fails `flutter analyze`, blocks the PR

### Rule 2: Exploration discipline
- Map the feature folder before searching inside it
- List consumers (`rg -l`) before refactoring a Cubit or entity
- Use `-g '*.dart'` on every search

### Rule 3: Clean Architecture maintained
- All UI strings in the Presentation layer use localization
- Data sources accept dependencies via constructor
- No dead code (YAGNI)

---

## Quick Reference for Keko

```bash
# Find order logic
rg -l "OrderCubit|createOrderFromCart" lib/ -g '*.dart'

# See what depends on OrderCubit
rg "OrderCubit" lib/ -l -g '*.dart'

# Check localization usage in a screen
rg -n "context.l10n" lib/features/profile/presentation/screens/profile_screen.dart

# Find tests for a cubit
rg -l "profile_cubit" test/ -g '*_test.dart'

# Find translation keys
rg "statTotal|statReceived" lib/l10n/ -g '*.arb'
```

---

## Links & References

- **Project README:** `docs/` in the main repo
- **Generic exploration guide:** [`EXPLORATION_STRATEGY.md`](../EXPLORATION_STRATEGY.md)
- **Localization files:** `lib/l10n/app_*.arb`
- **Architecture pattern:** Clean Architecture

---

**Version:** 2.0
**Last updated:** June 2026
**Status:** Example / template for Flutter projects
