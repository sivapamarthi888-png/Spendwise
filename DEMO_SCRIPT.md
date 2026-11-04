# SpendWise — 5-Minute Live Demonstration Script

Format per the programme specification (Section 5.1). Rehearse once with a
timer. **Every member speaks.** The phone must run the installed release APK
(`app-release.apk`).

| Time | Segment | What to do |
| --- | --- | --- |
| 0:00–0:30 | **Who it's for & the problem** | "SpendWise is for anyone who wants to track daily income and expenses without accounts or cloud services. The problem: most expense apps need sign-ups and internet; SpendWise is offline-first — every rupee is stored privately on the device in SQLite." Show the launcher icon, open the app. |
| 0:30–1:30 | **Add a transaction (primary flow)** | Tap **+** → enter amount (e.g. ₹250), pick category **Food**, payment method **UPI**, optional note "Lunch", pick today's date → **Save**. Dashboard updates: This Month's Spending, Today chip, transaction card appears. |
| 1:30–2:15 | **Rejected form entry (on purpose)** | Tap **+** again → leave everything empty → **Save**. Point at the per-field errors: *"Amount must be numeric / greater than zero"*, payment-method error. Then type `1.2.3` into the amount field to show the numeric-validation error. Correct the values and save successfully. |
| 2:15–3:00 | **Browse, search & filter** | Use the search box to filter by note/category; open the **month filter**; tap a transaction → **detail screen** (full record) → tap **Edit**, change the amount, save; reopen and **Delete** with confirmation. |
| 3:00–3:30 | **Statistics + empty/error state** | Open the **Statistics** tab: monthly bar chart, category breakdown with highest-category highlight, average daily spend. (If you cleared data earlier in rehearsal, show the friendly **empty state** with its CTA; otherwise mention it.) |
| 3:30–4:30 | **Technical problem & how we solved it** | Tell the D-14 story from DEFECT_LOG.md: *"Release builds kept failing mid-build — Kotlin incremental caches can't handle pub-cache and project on different drive roots, and OneDrive was locking files inside build/. We disabled Kotlin incremental compilation, paused OneDrive during builds, purged the build tree — and the APK built cleanly. We logged every defect with reproduction steps in DEFECT_LOG.md."* (Second member can tell the D-16/D-17 web story: CSV export and persistence on web.) |
| 4:30–5:00 | **GitHub + APK** | Open the repo on the phone/laptop: show the commit history (github.com/sivapamarthi888-png/Spendwise), the README, DEFECT_LOG.md, and the committed `app-release.apk`. Mention the live web version: spendwise-eta-swart.vercel.app. |

## Evidence checklist (prepare before the demo)

- [ ] APK installed on the physical phone (settings → allow install from this source)
- [ ] Phone charged, screen recording enabled (optional but useful as backup evidence)
- [ ] Repo open in a browser tab at the commit-history page
- [ ] Live website open in a phone browser tab (for the bonus mention)
- [ ] A few transactions pre-seeded so charts/statistics look real — but keep one empty-filter moment ready

## Q&A preparation (likely questions)

1. **Where is the data stored?** — Private SQLite file on device (`sqflite`); on web, SQLite-WASM in browser storage. Nothing leaves the device.
2. **How is state managed?** — `provider` (`ChangeNotifier`); screens never touch the DB directly; a `TransactionStore` interface separates storage from logic (that's also how tests run hermetically).
3. **How do you validate input?** — Required amount, numeric formatters, `> 0` bound, max caps, per-field error messages (demonstrate live at 1:30).
4. **How was it tested?** — 33 automated tests (model, provider, widget) + `flutter analyze` clean; defect log with repro steps.
5. **What was hardest?** — The release-build failures (D-14) and making SQLite work in the browser (D-17).
