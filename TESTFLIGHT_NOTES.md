# TestFlight submission pack (PR-12, TESTFLIGHT-MIN)

Prepared 2026-06-12. Build identity: 1.0 (1). This file holds the
"What to Test" copy to paste into App Store Connect and the manual
upload checklist. Copy below follows COPY_SYSTEM (no banned phrases,
no em dashes, "heated session" never "tilt") and the DO-NOT-MARKET
gate (no recovery-tier language anywhere in tester-facing text).

---

## Version and build

- MARKETING_VERSION 1.0, CURRENT_PROJECT_VERSION 1. This is the
  correct identity for a first TestFlight submission (matches the
  APPLE_REVIEW_COMPLIANCE Day -7 plan, "Build 1.0 (1)").
- Every subsequent upload on 1.0 increments the build number only
  (2, 3, ...) in Xcode: target BetAutopsy, General tab, Build field.
  Claude Code does not edit the project file; bumps are manual.

---

## What to Test (paste into TestFlight)

BetAutopsy reads your exported bet history and builds a behavioral
report: where you make money, where you leak it, and what your
betting looks like when emotion takes over.

Please walk this path and tell us where anything feels broken,
confusing, or slow:

1. Sign in with Apple and complete the opening questions.
2. Upload a CSV export of your bet history. Pikkit exports work
   best. The analysis takes a minute or two.
3. Read your free snapshot top to bottom. Locked items are expected;
   that is the paid layer.
4. If you purchase the full report (sandbox, no real charge), check
   that every locked item opens and the dollar figures look sane
   against your own records.
5. Open the report a second time, scroll fast, rotate through tabs,
   and try the pre-bet check-in from the Today tab.

Things we most want to hear about: numbers that look wrong, charts
that look empty or broken, text colliding with the clock or the home
indicator, anything you tapped that did nothing, and anywhere the
report misreads your betting.

If gambling has stopped being fun, call 1-800-MY-RESET.

---

## Manual upload checklist (Andrew)

1. Pull main (post-merge), open BetAutopsy.xcodeproj in Xcode.
2. Confirm the local Info.plist has the REAL Supabase anon key
   (grep SUPABASE_ANON_KEY; if it reads PASTE_REAL_KEY_HERE, paste
   the key and re-run `git update-index --assume-unchanged
   BetAutopsy/BetAutopsy/Info.plist`).
3. Select the BetAutopsy scheme, destination "Any iOS Device (arm64)".
4. Product > Archive. Wait for the Organizer window.
5. In Organizer: Distribute App > TestFlight & App Store > Upload.
   Keep the defaults (symbols on, app thinning automatic). Signing:
   automatic, team PAU6GLBN86.
6. App Store Connect (appstoreconnect.apple.com) > My Apps >
   BetAutopsy > TestFlight tab. The build appears under iOS builds
   and shows "Processing" for roughly 10 to 30 minutes.
7. Export compliance should NOT prompt (ITSAppUsesNonExemptEncryption
   is declared in Info.plist). If it prompts anyway, answer: uses
   encryption yes, only exempt standard encryption.
8. When processing finishes, add the build to the Internal Testing
   group (create one named "Core" with your account if none exists).
9. Paste the What to Test section above into the build's Test
   Details. Do not add anything about risk tiers or recovery
   recommendations to any tester-facing field.
10. Install via the TestFlight app on your device and verify:
    a. Cold launch reaches the age gate, onboarding completes, Sign
       in with Apple works on a production-signed build.
    b. Reports tab hydrates your existing reports (production env
       per the PR #32 env switch).
    c. Open the fresh full report: hero session chart, recovery
       range, charts render; no LOCKED pills anywhere in a paid
       report.
    d. A snapshot still shows its locks and the paywall opens.
    e. Status bar and home indicator: nothing collides on the report
       reader, Reports tab, or Sessions tab.
    f. Pre-bet check-in: stake keyboard shows a Done button and
       dismisses.
11. Sandbox purchase check on device: buy the full report with a
    sandbox account; entitlement should land via the RevenueCat
    webhook and the snapshot should swap in place.

---

## Privacy and metadata state (verified this PR)

- PrivacyInfo.xcprivacy present in the app target.
- No NSUsageDescription strings required: no camera, photos,
  location, microphone, or contacts access. The CSV document picker
  and provisional push notifications need none.
- ITSAppUsesNonExemptEncryption = false committed (standard HTTPS
  only).
- Launch screen: generated (INFOPLIST_KEY_UILaunchScreen_Generation),
  no splash beyond system launch, per scope.
