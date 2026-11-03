# SpendWise – Personal Expense Manager

<div align="center">
  <img src="assets/icon/app_icon.png" width="120" alt="SpendWise launcher icon" />
  <p><b>An offline-first expense tracker for Android, built with Flutter.</b></p>
</div>

SpendWise is a personal expense manager that lets you record income and expense
transactions, browse them with search and filters, see calendar-month summaries,
analyse spending trends in a chart, and export everything to CSV. All data is
stored **locally on the device** with SQLite — no accounts, no network, no
cloud services.

Built as part of the **IITM Pravartak & BodhBridge Flutter Development
Programme** (approved topic: Expense Tracker).

---

## 1. Features

| Area | Details |
| --- | --- |
| Add / edit transactions | Amount (₹, decimal, max-length guarded), category chips, payment-method dropdown, date picker, optional description |
| Validation | Required amount, numeric-only input formatters, `> 0` amount bound, max amount cap, description length cap, selection checks with clear per-field error messages |
| Dashboard | Greeting header, "This Month's Spending" hero card, Today / Net Balance chips, Income & Expenses totals, last-seven-days spending chart, searchable + category-filterable + month-filterable transaction list |
| Four UI states | Loading, Error (with Retry), Empty (with CTA) and Data — implemented on the dashboard list |
| Statistics | Month-by-month bar chart (last 3 months), category breakdown with highest-category highlight, average daily spend, totals for the filtered scope |
| Settings | Light / Dark / System theme selection (persisted), "Clear all data" with confirmation, CSV export, About section |
| Persistence | SQLite via `sqflite`; survives app restarts |
| Export | CSV export of all transactions to app documents (shareable via the system share flow) |
| Theming | Material 3, generated from the single seed colour `#2563EB`. **No screen-level hardcoded colours** — every widget uses `Theme.of(context)` / `ColorScheme` |
| Formatting | `en_IN` Indian digit grouping for rupees (e.g. `₹1,23,456.50`), `DD MMM YYYY` dates |
| Charts | Custom `CustomPainter` bar chart (no third-party chart library) — consistent with Material colour scheme |

## 2. Technology stack

| Layer | Choice |
| --- | --- |
| Framework | Flutter (stable ≥ 3.35), Dart 3, null safety |
| State management | `provider` (6.x) — `ChangeNotifier` + `MultiProvider`, screens never call the DB directly |
| Local database | `sqflite` (single-table `expenses` with indexed `date` column) |
| Theming | Material 3 (`ColorScheme.fromSeed(seedColor: Color(0xFF2563EB))`) |
| Dates & numbers | `intl` (`en_IN` currency, `DateFormat`) |
| Persistence of theme | `shared_preferences` |
| Launcher icons | `flutter_launcher_icons` (1024×1024 master + adaptive icon, brand `#2563EB`) |
| Tests | `flutter_test`, provider unit tests + widget tests with a deterministic in-memory store fake |

## 3. Architecture

```
lib/
├── main.dart                     # App bootstrap: DB open, theme load, MultiProvider, routes
├── models/
│   └── expense.dart              # Expense model, TransactionType, map round-trip + safe parsing
├── services/
│   ├── database_service.dart     # sqflite implementation of the TransactionStore interface
│   └── storage_service.dart      # CSV export helper
├── providers/
│   ├── expense_provider.dart     # Central ChangeNotifier: load/CRUD/search/filter/sort + derived summaries
│   └── theme_provider.dart       # ThemeMode state (persisted)
├── utils/
│   ├── app_theme.dart            # Light + dark themes from the single seed colour
│   ├── app_constants.dart        # Categories, icons, payment methods, limits
│   ├── currency_formatter.dart   # ₹ en_IN formatting + input parsing
│   └── date_formatter.dart       # DD MMM YYYY formatting, month keys, greeting
├── navigation/
│   └── app_navigation.dart       # Route names, onGenerateRoute, bottom-nav shell + FAB
├── screens/
│   ├── dashboard_screen.dart     # Screen 1 — dashboard (all four list states)
│   ├── add_expense_screen.dart   # Screen 3 — add / edit form with validation
│   ├── expense_detail_screen.dart# Screen 4 — full record detail with edit/delete
│   ├── statistics_screen.dart    # Custom chart + analytics
│   └── settings_screen.dart      # Theme, export, clear data, about
└── widgets/
    ├── expense_card.dart         # Transaction row
    ├── summary_card.dart         # Income / expense stat tiles
    ├── spending_chart.dart       # CustomPainter bar chart
    ├── month_filter_sheet.dart   # Month filter bottom sheet
    ├── category_icon.dart        # Category → icon + tinted circle
    ├── empty_state.dart          # Friendly empty illustration + CTA
    ├── error_widget.dart         # Recoverable error + Retry
    └── loading_widget.dart       # Loading spinner wrapper
test/                             # Model, provider and widget tests (+ test_support fake)
```

**Key design decision:** persistence is abstracted behind a small
`TransactionStore` interface (`lib/services/database_service.dart`). The
production app binds `sqflite`; the test-suite binds an in-memory fake
(`test/test_support/in_memory_store.dart`). This keeps widget- and
provider-level tests hermetic — they never touch real device storage and can
simulate storage failures deterministically.

## 4. Screenshots

> Real device screenshots pending the first run on an emulator/physical device.
> Placeholder slots are listed below.

| Screen | Screenshot |
| --- | --- |
| Dashboard | `docs/screens/dashboard.png` — TODO |
| Add / Edit expense | `docs/screens/add_expense.png` — TODO |
| Expense detail | `docs/screens/expense_detail.png` — TODO |
| Statistics | `docs/screens/statistics.png` — TODO |
| Settings | `docs/screens/settings.png` — TODO |

## 5. Getting started

### Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Flutter SDK | stable ≥ 3.35 (developed on 3.47.x) | `flutter doctor` must be clean for Android |
| JDK | 17 | `JAVA_HOME` must point to JDK 17 |
| Android SDK | API 34/36 + build-tools | Platform + build-tools installed, licences accepted |

### Run it

```bash
flutter pub get
flutter run
```

The app stores its database in the app-private documents directory of the
target device/emulator — nothing else is required.

### Tests

```bash
flutter analyze   # static analysis — currently 0 issues
flutter test      # 33 tests: model, provider and widget-level suites
```

What the suites cover:

* `test/expense_model_test.dart` — map round-trip, safe parsing of malformed data, signed amounts, ₹ formatting.
* `test/expense_provider_test.dart` — load/error/retry, idempotent `ensureLoaded`, CRUD, clearing, month/today summaries, category breakdown, search/filters/sort, listener discipline.
* `test/add_expense_screen_test.dart` — form rendering, all validation branches, a full save flow, and the edit flow.
* `test/dashboard_screen_test.dart` — dashboards rendering summary + cards from real data, empty state, error state with working Retry, and live search filtering.

### Build a release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

> Windows/OneDrive note: if the project folder lives inside OneDrive, the
> sync engine can lock files inside `build/` and fail the Gradle build.
> Pause OneDrive (or temporarily kill `OneDrive.exe`) during the build.
> Kotlin incremental compilation is already disabled (cross-drive cache
> limitation) via `android/gradle.properties`.

**Install on an Android phone:**

1. Copy `app-release.apk` to the phone.
2. Tap the file and allow *"Install from this source"* when prompted, or:
   ```bash
   adb install -r app-release.apk
   ```
3. Launch **SpendWise** from the launcher.

## 6. Data & privacy

* Database: local SQLite file in the app's private storage (table `expenses`).
* CSV export: written to the app documents directory, then shared via the
  Android share sheet — no data leaves the device except through the user's
  explicit share action.
* No third-party analytics, no network calls, no accounts.

## 7. Known limitations

* Physical-device verification (install + smoke test) is pending; all checks so
  far are build-level and emulator-level (`flutter analyze`, `flutter test`).
* CSV export targets the device share sheet; importing CSV back is not supported.
* Statistics charts cover 3 months (window configurable in code).

## 8. Team

| Member | Role | Contribution |
| --- | --- | --- |
| *Name — TODO* | *TODO* | *TODO* |
| *Name — TODO* | *TODO* | *TODO* |

## 9. Defects & incident log

See [DEFECT_LOG.md](DEFECT_LOG.md) for every real defect found during
development, its impact and its resolution status.
