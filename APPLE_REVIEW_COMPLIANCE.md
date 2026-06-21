# Apple App Store review compliance for BetAutopsy

**Version 1.0. Author: Diagnostic Sports, LLC. Date: May 12, 2026. Drop into the repo as `APPLE_REVIEW_COMPLIANCE.md`.**

BetAutopsy is approvable on the first or second submission cycle if it executes a specific, narrow strategy. The strategy is: position as a behavioral diagnostic that reads user-uploaded historical data, never as a betting tool. Mirror Pikkit's "tracker, not a sportsbook" disclaimer language almost verbatim. Submit as an LLC. Ship a "Sample Report" path that bypasses CSV upload entirely. Rate 17+ with Frequent Gambling references, override to 18+ for legal cover. Exclude Brazil. Use one Consumable for the single report, one Consumable for the bundle, one Auto-Renewable for the annual. Lead Review Notes with "We are not a sportsbook" and provide the reviewer three independent ways to see a working report.

The risk is real but bounded. Every direct competitor that ships today, Pikkit, OddsJam, Rithmm, Action Network, Juice Reel, Betstamp, cleared review using a small set of repeatable patterns. None of them publicly report rejection horror stories. The single dominant rejection vector for an app like BetAutopsy is not Guideline 5.3 gambling enforcement, it is Guideline 2.1 demo credentials failure, because the reviewer has no real bet history to upload. Solve that and you solve 80% of the review risk.

This document is the BetAutopsy-specific playbook. It is opinionated. Where there is a real choice to make, the choice is stated. Where reviewers might ask a question, the answer is written. Use it as a reference at submission time and as the source of the exact text that goes into App Store Connect.

---

## 1. The review climate in 2026

Apple's App Store Review Guidelines were last updated February 6, 2026. The relevant clauses for BetAutopsy are 1.1, 1.4.1, 1.4.5, 2.1, 2.3.1, 2.3.6, 2.3.8, 3.1.1, 3.1.2, 4.0/4.2, 5.1.1, and 5.3. Three changes in the last 18 months matter:

**The May 1, 2025 IAP update.** Following the Epic v. Apple ruling, Apple permits buttons and external links to alternative payment methods on the US storefront. This is not relevant to BetAutopsy. Use standard IAP and skip the workaround entirely.

**The November 13, 2025 update.** Clarified that HTML5 and JavaScript mini-apps fall inside 4.7, tightened anti-copycat enforcement under 4.1(c), and added 1.2.1(a) creator-content age gating. The 4.1(c) anti-copycat clause is a quiet new risk for BetAutopsy if the icon or name reads as a Pikkit lookalike. Pick a distinct icon and a name that does not begin with "Bet" plus another tracker's word.

**The May 8, 2026 Brazil SPA license enforcement.** Apps that answer "Yes" to the Gambling content question in the age-rating questionnaire must provide a Brazilian Secretariat of Prizes and Bets license to ship in Brazil. BetAutopsy cannot get an SPA license because it is not an operator. Exclude Brazil. This is non-negotiable.

The broader review climate is that gambling-adjacent apps are routed to a specialty reviewer team and take 1 to 3 extra days. Apple's published median review time is 1.5 days, with 90% of submissions returned within 48 hours, against approximately 200,000 weekly submissions. Mac reviews are longer. Expect 2 to 4 days for first review of BetAutopsy, longer if rejected. The single most important calendar fact: **do not submit on Friday afternoon.** Submit Tuesday 9am ET. The Saturday-Sunday review queue is the slowest and least forgiving.

**What changed for DFS, prediction markets, and analytics apps specifically.** PrizePicks and Underdog pivoted to CFTC-registered event contracts in 2025 to preempt state-by-state cease-and-desist pressure. Kalshi has been on iOS in the **Finance** category since 2022 by framing itself as a CFTC Designated Contract Market, not a sportsbook, and discipline of language (trade, shares, contracts, never bet) is the reason it survived where Polymarket spent four years off iOS. Polymarket returned to iOS December 3, 2025 only after acquiring QCEX for $112 million to inherit a CFTC license, then received Apple approval. The lesson for BetAutopsy is structural: Apple cares about the regulatory shell around real-money outcomes. BetAutopsy has no real-money outcomes inside the app, so 5.3 is not actually triggered. The risk is that a reviewer reads "betting" in metadata and reflexively applies 5.3 anyway. Defuse that reflex preemptively in Notes for Review.

**Stake.us and Chumba Lite are the sweepstakes precedent and they do not apply to BetAutopsy.** They cleared iOS by accepting only the non-redeemable currency through IAP and gating to 21+ internally. BetAutopsy does not need any sweepstakes framing.

**23andMe, MacroFactor, Whoop, and Daylio are the more useful precedent.** They are the diagnostic apps BetAutopsy actually resembles. The patterns to inherit from them: explicit "not intended to diagnose any condition" disclaimer copy, framing as **insights** and **coach** and **patterns** rather than **diagnosis** or **treatment**, privacy as marketing (Daylio's "we do not store or collect your data" is brand asset and review armor at once), and onboarding that produces something the reviewer can see without supplying their own data.

## 2. The five guidelines that matter, applied

**Guideline 5.3, Gaming, Gambling, and Lotteries.** The operative clause is 5.3.4: "Apps that offer real money gaming (e.g. sports betting, poker, casino games, horse racing) or lotteries must have necessary licensing and permissions in the locations where the app is used, must be geo-restricted to those locations, and must be free on the App Store. Illegal gambling aids, including card counters, are not permitted on the App Store." BetAutopsy does not offer real-money gaming, does not provide an edge on future bets, and is not a card counter. The "illegal gambling aids" clause is the actual trap. A reviewer could misread "bias analysis" as "edge identification." Mitigation is language discipline: never use **edge**, **+EV**, **sharp**, **picks**, **predictions**, **win more**, **boost ROI**, or **beat the book** in any user-facing string or metadata. BetAutopsy is forensic, post-hoc, and historical. It is a mirror, not a weapon.

**Guideline 2.1, App Completeness.** The dominant rejection vector for this app. Apple's exact rejection language, reproduced consistently in developer forums: "We were unable to sign in with the demo account credentials you provided." For a CSV-upload diagnostic, the reviewer has no CSV. Solve this with three layers: a pre-seeded Sign in with Apple demo account that lands on a populated dashboard, a "See a Sample Report" button on the welcome screen accessible without any sign-in, and a reviewer-bypass tap sequence on the logo with a code disclosed in Review Notes. Attach the sample CSV as a file in App Review Information. Attach a 90-second walkthrough video. Belt, suspenders, and a backup belt.

**Guideline 2.3.1, Accurate Metadata.** Screenshots cannot show real sportsbook logos, real bet slips, or implied wins. They must depict the diagnostic report. Description cannot claim "AI-powered insights" if the user-facing strings never use the word. Every claim in the App Store listing has to be visibly present in the first 30 seconds of app use.

**Guideline 3.1.1 and 3.1.2, In-App Purchase.** The clean configuration is: single report as a Consumable at $9.99, three-report bundle as a Consumable at $19.99, annual at $99.99 as an Auto-Renewable Subscription. A single report is Consumable, not Non-Consumable, because the user consumes the generated content and may buy another. Non-Consumable would entitle the user to all future reports via Restore Purchases and break the model. Family Sharing must be off on all three, and on the subscription this decision is permanent. Once Family Sharing is enabled on an auto-renewable subscription it cannot be disabled. Leave it off.

The subscription needs "ongoing value" to satisfy 3.1.2(a). One report a year does not. Build in monthly re-analysis with new uploaded CSVs, a longitudinal comparison view, and a behavioral pattern glossary. The subscription's value proposition is "we re-diagnose you every time you upload fresh data, and we show you the trend." This is the MacroFactor pattern and it survives review.

**Guideline 5.1.1, Privacy.** Sub-clause 5.1.1(ix) explicitly puts gambling in the highly regulated fields bucket: "Apps that provide services in highly regulated fields (such as banking and financial services, healthcare, gambling, legal cannabis use, air travel and crypto exchanges) or that require sensitive user information should be submitted by a legal entity that provides the services, and not by an individual developer." BetAutopsy must be submitted by Diagnostic Sports, LLC, never by an individual developer account. This is already the configuration. Keep it.

**Guideline 1.4.1, Physical Harm.** Risk only if BetAutopsy ever uses the word **diagnose**, **addiction**, **pathological**, or **disorder** in a clinical sense. The correct framing throughout the product and metadata is **behavioral patterns**, **decision history**, **forensic review**. Include in-app and in description: "BetAutopsy is not a medical or psychiatric tool. If our analysis raises concerns for you, please consult a qualified professional and call 1-800-GAMBLER."

**Guideline 4.0/4.2, Design.** A one-shot diagnostic with a paywall and no persistent reason to keep the app is the canonical 4.2 minimum-functionality rejection. Three mitigations: re-runnable analysis on fresh CSVs, an in-app glossary of behavioral patterns the user can browse anytime, and exportable PDF artifacts. The app must justify staying installed.

## 3. What the comparables actually did

The audit produced a clear template, copyable line by line, that BetAutopsy should mirror. The five most useful direct comparables are Pikkit, OddsJam, Rithmm, Action Network, and Juice Reel. All five are rated 17+ with Simulated Gambling content descriptors. All five include a "not a sportsbook" disclaimer in their App Store description. None publicly discuss rejections. The pattern works.

**Pikkit's exact disclaimer is the strongest model.** Verbatim: "Pikkit is a bet tracker app and not a sportsbook. Nor does it accept wagers or real-money deposits. All information and gambling-related content is for informational and entertainment purposes only and is not gambling or financial advice." BetAutopsy's near-clone of this: "BetAutopsy is a behavioral analytics app and not a sportsbook. It does not accept wagers, place bets, recommend wagers, or provide odds. All information is for informational purposes only and is not gambling, financial, or medical advice. If you or someone you know has a gambling problem, call 1-800-GAMBLER."

**OddsJam's framing of itself as a platform, not an app, widens the category.** Their headline language, "Sports Data and Analytics Redefined," does compliance work. BetAutopsy should consider "Behavioral Analytics for Sports Bettors" or "Bet History Diagnostic Platform" in the subtitle, not "Sports Betting Tracker."

**Rithmm self-imposes 21+ in description copy even at 17+ Apple rating.** This is belt-and-suspenders and it smooths review. BetAutopsy should do the same: rate 17+ legacy, override to 18+ for legal cover, state in description "Must be 18+. Sports betting age varies by state, 21+ where required."

**Action Network's "We do not believe in 'locks'" is a brand-on disavowal of pick-selling.** BetAutopsy gets the same effect with "BetAutopsy does not provide picks, predictions, or recommend wagers. It diagnoses how you bet, not what to bet."

**The Tier C diagnostic apps inform the framing.** 23andMe's "The reports are not intended to diagnose any disease, tell you about your current state of health, or for use in making medical decisions" is the medical-disclaimer template. MacroFactor's subscription-only structure with 7-day trial is the IAP template. Daylio's "Data stored in the app's private directories is not accessible by any other apps or processes" is the privacy template. Each of these patterns should appear in BetAutopsy's metadata in modified form.

**Quotable subtitle precedents for BetAutopsy:** Pikkit uses "30+ Sportsbooks: Odds & Lines" (functional), OddsJam uses "Player Props, +EV, & Arbitrage" (feature-list), Rithmm uses "Player Props & Predictions" (outcome). BetAutopsy candidate: **"Forensic Bet History Analysis"** or **"Find Out Why You Lose."** The second is more on-brand but riskier under 1.1.6 if the reviewer reads it as a guarantee.

**Privacy label benchmarks.** OddsJam discloses only Contact Info (email), User ID, Device ID, all Linked, no Tracking. This is the lean target. Pikkit is heavier because it is social (Contacts, Photos, UGC, Identifiers with tracking). BetAutopsy is not social. Mirror OddsJam's lean posture.

## 4. The rejection categories and the responses

Every probable rejection has a specific response. The matrix below is the playbook.

**Guideline 5.3 cited for gambling content without licensing.** Apple's boilerplate: "We noticed your app includes features that facilitate real money gaming. Please provide a list of all locations where you have legal authorization to provide your app's features." Response: "BetAutopsy is not a real-money gaming app. It does not accept wagers, place bets, hold customer funds, display live odds, recommend specific wagers, or integrate with any sportsbook. It is a post-hoc behavioral analysis tool that reads user-uploaded CSV exports of historical betting records. The structural precedent is Pikkit (id1586567110), Betstamp, and Juice Reel, none of which hold gambling licenses because they do not offer gambling services. Guideline 5.3.4 does not apply."

**Guideline 5.3 cited for facilitating gambling.** Response: "BetAutopsy does not facilitate gambling. There is no path inside the app from the user to a sportsbook, prediction market, or gaming operator. The user manually exports their own historical data from a third-party tracker, manually uploads the CSV, and receives a behavioral diagnostic. No bets are placed, no funds move, no recommendations are made for future wagers."

**Guideline 1.1 cited for risky behavior or addiction.** Response: "BetAutopsy is the opposite of encouragement. The product surfaces costly biases and quantifies their dollar impact, with the explicit goal of producing self-awareness. The app includes 1-800-GAMBLER references on the home tab and in settings, surfaces warning-sign patterns (loss-chasing, escalating stakes, late-night clustering) in the report, and is gated to users 18+ at first launch."

**Guideline 2.1 cited for missing demo or incomplete app.** Response: "The reviewer can test BetAutopsy three ways without supplying any data. (a) The demo Apple Sign-In account [appreview-2026@betautopsy.com / ReviewBA_2026!] is pre-seeded with three months of sample bets and a generated report; on sign-in the reviewer lands directly on the dashboard. (b) On the welcome screen, tap 'See a Sample Report' to view the full report experience without sign-in. (c) If Sign in with Apple fails on the reviewer's network, tap the BetAutopsy logo 5 times within 3 seconds and enter code 729104 to bypass auth into the same demo account."

**Guideline 2.3.1 cited for metadata overstatement.** Response: "Every claim in the App Store listing maps to a visible screen in the app, demonstrated in the attached 90-second walkthrough. The BetIQ score, behavioral archetype, dollar-impact analysis, and 7-chapter report are all rendered for the demo account at first launch."

**Guideline 3.1.1 cited for IAP issues.** Response: "BetAutopsy uses standard StoreKit IAP via RevenueCat. Single Report ($9.99) and Three-Report Bundle ($19.99) are Consumables; Annual ($99.99) is an Auto-Renewable Subscription. None of the IAPs purchase gambling credit, sweepstakes entries, or anything redeemable on a gaming platform. Per Guideline 5.3.3, no IAP is used in conjunction with real-money gaming. The products deliver digital content, the behavioral analysis report, consumed entirely within BetAutopsy."

**Guideline 5.1.1 cited for privacy.** Response: "The privacy manifest declares Other Financial Info and Other User Content (linked, not tracked) for bet history, User Content for quiz responses, User ID for Apple Sign-In, Product Interaction (not linked, not tracked) for TelemetryDeck, and Purchase History (linked, not tracked) for RevenueCat. NSPrivacyTracking is false. The privacy policy at https://betautopsy.com/privacy discloses each category and provides in-app account deletion. BetAutopsy is submitted by Diagnostic Sports, LLC, per 5.1.1(ix)."

**Guideline 1.4.1 cited for medical/health claims.** Response: "BetAutopsy makes no medical or clinical claims. The user-facing language is behavioral, not diagnostic. The app includes a permanent disclaimer: 'BetAutopsy is not a medical or psychiatric tool. If you or someone you know has a gambling problem, call 1-800-GAMBLER.' This mirrors 23andMe's disclaimer language at App Store metadata level."

**Guideline 4.2 cited for thin app.** Response: "BetAutopsy provides ongoing utility beyond a single report. Users may upload fresh CSVs monthly and receive recalibrated reports with longitudinal trend analysis. The app includes a Behavioral Patterns glossary (12 entries covering loss-chasing, hot-hand bias, anchoring, sunk-cost continuation, and others), exportable PDF reports, and comparison views across reporting periods. The annual subscription delivers ongoing recalibration per 3.1.2(a)."

## 5. Demo credentials and the test flow

The single most important piece of submission infrastructure is the demo path. The strategy is triple-layered.

**Layer one, the pre-seeded demo account.** Create Apple ID `appreview-2026@betautopsy.com`. Sign in on a sandbox device once to pre-provision the Sign in with Apple token. Pre-load it with three months of sample bet history, a fully generated BetIQ score, behavioral archetype assignment, and the 7-chapter report. The reviewer signs in and lands directly on the dashboard. Nothing to upload, nothing to configure, nothing to find. Password: `ReviewBA_2026!` rotated quarterly.

**Layer two, the unauthenticated sample report.** On the welcome screen, place a button labeled "See a Sample Report." This loads a bundled, fictional CSV (not real data) through the full analysis pipeline and renders a complete report. No sign-in, no upload, no account. This is what Copilot Money, Lunch Money, and PhotoRoom do, and it works.

**Layer three, the reviewer bypass.** Apple's Sign in with Apple environment fails unpredictably on internal review networks. Build a tap-sequence bypass: tap the BetAutopsy logo five times within three seconds on the sign-in screen, prompted code field appears, enter `729104`, signed into the demo account without any auth call. Disclose explicitly in Review Notes. This is the single feature that prevents a multi-cycle rejection if Apple's SiwA infrastructure fails on the day of review.

**Guideline 4.8, Sign in with Apple (PR-AUTH).** The app now offers three sign-in methods — Sign in with Apple, Continue with Google, and email/password. Because a third-party social login (Google) is present, 4.8 requires Sign in with Apple to also be offered; it is, and it stays prominent (top of the auth screen, equal weight). Email/password is a first-party account system and does not itself trigger 4.8. No login is limited to data collection beyond name + email, and none requires it for advertising — both 4.8 conditions satisfied. The reviewer demo path is unchanged (pre-seeded Apple account, unauthenticated sample report, and the 5-tap bypass code 729104).

**The CSV attachment.** Apple's App Review Information field accepts file attachments. Attach `BetAutopsy_AppReview_SampleBets.csv` directly. Tell the reviewer in Notes: "If the demo account fails, AirDrop this CSV to Files on the test device, then on the upload screen choose 'From Files'."

**The walkthrough video.** Apple's submission tooling allows direct video attachment, not just a link. Record 60 to 90 seconds: cold launch, age gate, sample report preview, quiz, archetype reveal, CSV upload via demo, report rendering, paywall walkthrough. M4V or MP4, 1290 × 2796. Apple's own guidance is that video supplements but does not replace a working demo. We provide both.

**Test path the reviewer is asked to follow.** Cold launch. Tap through age gate (confirm 18+). On welcome screen, tap "See a Sample Report" for the unauthenticated path. Return to welcome. Tap "Sign In" and use demo credentials. Land on populated dashboard. Tap "View Report" to see the 7-chapter report rendered. Tap "Generate New Report" to surface the paywall. Validate IAP via sandbox. Done.

## 6. Age rating, defended

**Rate 17+ in the legacy system, which maps to 18+ in Apple's 2025 system.** Use the App Store Connect override to higher age rating to set 18+ as the floor regardless of mapping.

Answer the age-rating questionnaire as follows. **Simulated Gambling: None.** BetAutopsy has no game mechanics. **Gambling (real-money references): Frequent/Intense.** The entire premise is analyzing real-money sports betting history. **Medical/Treatment Information: Infrequent/Mild.** The app references warning signs of problem gambling and the 1-800-GAMBLER hotline. **Everything else: None.** No violence, no nudity, no profanity, no contests, no UGC, no messaging, no unrestricted web access.

This produces 17+ legacy with Frequent Gambling content descriptor. The 18+ override is the legal floor and is non-reversible. Take it. Operationally there is nothing lost: BetAutopsy's users are adult sports bettors. The 18+ tier excludes the app from K-12 Apple Education deployments, which we do not target, and from default Family Sharing for under-18 accounts, which is appropriate. France's ANFR will auto-display 18+ regardless. Brazil's automatic A18 will trigger because we answered Yes to Gambling, which is fine because we are excluding Brazil from territories entirely.

The lower-rating option, 12+ or 13+ with Infrequent/Mild gambling references, is not defensible. The product is fundamentally about real-money betting behavior. Pikkit and OddsJam, both with less gambling-saturated content than BetAutopsy will have, both sit at 17+ Frequent. Action Network is at 18+ in the new system. The norm is 17+/18+ and we should match it.

## 7. Geo-restriction at the App Store Connect territory level

**Enable approximately 34 countries at launch.** Americas: United States (all 50 states; Apple cannot geo-restrict by state and we do not need to because we are not real-money gaming), Canada, Mexico. Europe and EEA: United Kingdom, Ireland, France, Germany, Spain, Italy, Portugal, Netherlands, Belgium, Luxembourg, Austria, Switzerland, Denmark, Sweden, Norway, Finland, Iceland, Poland, Czech Republic, Slovakia, Hungary, Slovenia, Croatia, Estonia, Latvia, Lithuania, Greece, Malta, Cyprus, Romania, Bulgaria. Oceania: Australia, New Zealand. Asia: Japan.

**Explicitly exclude.** Brazil (SPA license requirement, cannot comply). Mainland China, Hong Kong, Macau. All MENA Islamic-law jurisdictions including UAE, Saudi Arabia, Qatar, Kuwait, Bahrain, Oman, Iran, Iraq, Egypt, Jordan, Morocco, Algeria, Tunisia. Turkey, Russia, Belarus, Ukraine. South Korea (GRAC regional rating risk; re-evaluate post-launch). Singapore, Malaysia, Indonesia, Thailand, Vietnam, Philippines, Pakistan, Bangladesh, Sri Lanka, Cambodia. India (state-by-state risk). South Africa, Nigeria, Kenya.

**Can BetAutopsy ship in US states where sports betting is illegal?** Yes. The product analyzes past behavior, does not facilitate or place bets, does not transmit wagers or process gambling payments. Federal Wire Act and UIGEA target operators, not analytics. State laws prohibit engaging in or facilitating gambling; past records analysis is neither. Pikkit and OddsJam both ship nationwide including in California, Texas, and Utah, where sports betting remains illegal. Apple's Guideline 5.3.4 geo-restriction requirement applies to real-money gaming operators, which we are not. **Ship in all 50 states.** Do not implement state-level in-app geofencing for the App Store version. We are not gambling.

**Top 25 vs all 50 US states.** The original spec mentioned restricting to top 25 legal states. This is unnecessary and counterproductive. It cuts the addressable market by roughly 40% and introduces in-app geofencing complexity (CoreLocation, IP geolocation, server-side enforcement) that does nothing for compliance and a lot for friction. Ship to all 50.

**International gambling-adjacent rules confirmed.** UK Gambling Commission does not regulate analytics tools that do not accept bets. Australia's Interactive Gambling Act 2001 targets operators only. Canada is provincial and does not regulate analytics. EU GDPR applies and is covered by the privacy manifest and policy.

**Will Apple challenge a US-heavy listing?** No. Pikkit launched US-only and expanded later. OddsJam is global. Apple's territory selection is a developer choice, not a 5.3 trigger.

## 8. Privacy manifest configuration

The `PrivacyInfo.xcprivacy` file at the BetAutopsy app target level should declare four required-reason API categories and six collected-data type entries. The full XML is below. Configure NSPrivacyTracking to false and leave NSPrivacyTrackingDomains empty.

**Required-reason APIs.** UserDefaults with reason CA92.1 for storing app settings. FileTimestamp with reasons C617.1 and 3B52.1 for accessing file metadata in the app container and on user-picked CSVs via the document picker. SystemBootTime with reason 35F9.1 for measuring intervals between in-app events. DiskSpace with reason E174.1 for checking available disk before writing decoded CSV and SQLite data. ActiveKeyboards is not needed.

**Collected data types.** Six entries.

Bet history CSV declared twice, defensively, as Other Financial Info (Linked, not Tracked, purposes App Functionality and Analytics) and Other User Content (Linked, not Tracked, purpose App Functionality). The double declaration is intentional: a reviewer's reflex on dollar-amount data is to expect Financial Info, and we satisfy that, while accurately also declaring it as user-uploaded content.

Quiz responses as Other User Content (Linked, not Tracked, purposes App Functionality and Product Personalization).

Hashed Apple Sign-In identifier as User ID (Linked, not Tracked, purpose App Functionality).

TelemetryDeck events as Product Interaction (NOT Linked, not Tracked, purpose Analytics). TelemetryDeck is anonymized by design and explicitly not tracking per their privacy FAQ.

RevenueCat purchases as Purchase History (Linked because we pass the Apple Sign-In hash as appUserID, not Tracked, purposes App Functionality and Analytics).

**Pikkit is not a third party in privacy manifest terms.** Pikkit is a user-controlled data source. The user exports a CSV from Pikkit on their own initiative and uploads it to BetAutopsy. There is no SDK, no API integration, no data sharing. Pikkit does not appear in the privacy manifest. The privacy policy should clarify: "BetAutopsy does not connect to Pikkit, sportsbook, or third-party betting services. All CSV imports are user-initiated."

**RevenueCat ships its own PrivacyInfo.xcprivacy via Swift Package Manager. TelemetryDeck ships its own.** Use SPM for both. App Store Connect privacy labels must declare Purchase History (linked, no tracking, app functionality + analytics) at the app level regardless of the SDK's manifest.

The full XML configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string><string>3B52.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>35F9.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>E174.1</string></array>
    </dict>
  </array>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeOtherFinancialInfo</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        <string>NSPrivacyCollectedDataTypePurposeAnalytics</string>
      </array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeOtherUserContent</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeUserID</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeProductInteraction</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><false/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAnalytics</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypePurchaseHistory</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        <string>NSPrivacyCollectedDataTypePurposeAnalytics</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
```

## 9. The IAP configuration in App Store Connect

Three products. Configure each in App Store Connect, mark Ready to Submit, and **attach all three to the version page of the build before submitting**, in the In-App Purchases and Subscriptions section of the version. This is the single most common RevenueCat-related rejection: IAPs exist but are not attached to the build.

**`com.diagnosticsports.betautopsy.report.single` at $9.99.** Type: Consumable. Reference Name: "BetAutopsy Single Report." Display Name: "BetAutopsy Report." Description: "One complete behavioral analysis report including BetIQ score, behavioral archetype, dollar-impact analysis, and full 7-chapter forensic report." Family Sharing: off (not eligible for consumables).

**`com.diagnosticsports.betautopsy.report.bundle3` at $19.99.** Type: Consumable. Reference Name: "BetAutopsy Three-Report Bundle." Display Name: "Three Reports." Description: "Three complete behavioral analysis reports, generated at any time over the next 12 months." Family Sharing: off.

**`com.diagnosticsports.betautopsy.subscription.annual` at $99.99/year.** Type: Auto-Renewable Subscription in the "BetAutopsy Pro" Subscription Group. Reference Name: "BetAutopsy Annual." Display Name: "BetAutopsy Pro Annual." Description: "Unlimited reports for one year with monthly behavioral recalibration, longitudinal trend analysis, and full archive of past reports." Family Sharing: off (permanent decision; do not enable). Free Trial: optional, recommended 7-day Introductory Offer to give reviewers a way to validate the subscription path.

**Why single = Consumable.** Non-Consumable entitles the user to all future reports via Restore Purchases and breaks the model. Consumable matches the user mental model: pay, receive the report, may buy another later. This is the exact precedent Apple has directed developers toward in documented Resolution Center cases for one-time-access products.

**RevenueCat-side.** Use Swift Package Manager (v5.x or later). Anonymous appUserID at first launch, transitioned to hashed Apple Sign-In ID after authentication. Server-side receipt validation is handled by RevenueCat automatically. Entitlement key: `premium`.

**Paid Applications Agreement.** Must be signed by the Account Holder in App Store Connect → Business → Agreements before any IAP works, in sandbox or production. Tax forms (W-9) must clear. Allow 3 to 5 business days. This is the silent gate that catches solo founders the week of submission.

## 10. The App Store listing copy

**App Name (30 chars max).** `BetAutopsy: Bet Diagnostic` (26).

**Subtitle (30 chars max).** `Forensic Bet History Analysis` (29).

**Promotional Text (170 chars).** `Upload your bet history. Get a forensic report. See the cognitive biases that cost you money, the archetype you bet like, and your BetIQ score from 0 to 100.`

**Description first paragraph.** `BetAutopsy is a behavioral analytics app for sports bettors who want to understand why they lose money. Upload your bet history. The app generates a forensic-style diagnostic report covering cognitive bias detection, dollar-impact analysis, behavioral archetype assignment, and a BetIQ score from 0 to 100.`

**Description compliance block (at the end of the listing, in its own paragraph).** `BetAutopsy is a behavioral analytics app and not a sportsbook. It does not accept wagers, place bets, recommend wagers, or provide odds. BetAutopsy does not provide picks or predictions. It diagnoses how you bet, not what to bet. Information is for informational purposes only and is not gambling, financial, or medical advice. Must be 18+. Sports betting age varies by state; 21+ where required. If you or someone you know has a gambling problem, call 1-800-GAMBLER or visit ncpgambling.org. Diagnostic Sports, LLC is not affiliated with or endorsed by Apple, the NFL, MLB, NBA, NHL, PGA, the NCAA, or any other sports league, nor is it a gambling site.`

**Keywords (100 chars).** `bet,history,analysis,betting,sportsbook,tracker,analytics,forensic,diagnostic,gambler,behavior,pikkit`

**Primary Category.** Sports. Finance is tempting for compliance reasons but does not match user search intent. Stick with Sports, same as Pikkit, OddsJam, Rithmm, Action Network. Apple's gambling-team routing happens regardless of category for any app with betting references.

**Secondary Category.** Lifestyle.

**Screenshot captions.** Each screenshot caption must describe a feature visible in that screenshot. Recommended set: "Your BetIQ score from 0 to 100" / "Nine behavioral archetypes. Which one are you." / "Cognitive biases, costed in real dollars." / "Seven-chapter forensic report." / "Upload once. Re-diagnose monthly."

Screenshots must not show real sportsbook logos, real bet slips, real dollar wins. Use the demo CSV's fictional data throughout. The 7-chapter report rendering should be the centerpiece.

## 11. The App Review notes paragraph, final form

This is the exact text to paste into App Store Connect → App Review Information → Notes. Approximately 700 words. Tested against the questions Apple is likely to ask.

```
BetAutopsy is a behavioral analysis app that reads user-uploaded bet history exports and produces forensic diagnostic reports. The product is structurally similar to 23andMe's one-shot diagnostic model and MacroFactor's behavioral analytics, applied to sports betting. It is sold to people who already bet and want to understand why they lose money.

What BetAutopsy does NOT do.
- It does not place bets.
- It does not accept wagers or hold customer funds.
- It does not recommend specific wagers, provide picks, or display predictions.
- It does not show live odds, lines, or sportsbook integrations.
- It does not connect to any sportsbook, prediction market, or gaming operator.
- It does not facilitate gambling in any form.

Guideline 5.3 does not apply. BetAutopsy is not a real-money gaming app. Guideline 5.3.4's licensing and geo-restriction requirements apply to apps that offer real-money gaming. BetAutopsy is a post-hoc analytics tool, structurally identical to Pikkit (id1586567110), Betstamp, and Juice Reel, none of which hold gambling licenses because they do not offer gambling services. Guideline 5.1.1(ix) is satisfied: this submission is by Diagnostic Sports, LLC, a registered legal entity.

Data flow. The user manually exports their own historical betting records as a CSV from a third-party tracker (Pikkit is the recommended source) and uploads the CSV directly to BetAutopsy. We have no API connections to sportsbooks. We do not scrape. The user controls the data flow end to end.

In-app purchases. Three products are configured via RevenueCat and submitted with this build for joint review. Single Report ($9.99, Consumable). Three-Report Bundle ($19.99, Consumable). Annual Pro Subscription ($99.99/yr, Auto-Renewable). The paywall is reachable from the dashboard's "Generate New Report" CTA. None of the IAPs purchase gambling credit or anything redeemable on a gaming platform. Per 5.3.3, no IAP is used in conjunction with real-money gaming. All IAPs deliver digital content (the behavioral report and ongoing recalibrations) consumed entirely within BetAutopsy.

Responsible-use commitment. The app surfaces 1-800-GAMBLER on the home tab and in Settings. The report's "Warning Signs" chapter flags loss-chasing, escalating stakes, and other patterns associated with problem gambling, with informational text and helpline references. The app includes an 18+ age gate at first launch and a non-medical disclaimer: "BetAutopsy is not a medical or psychiatric tool. If our analysis raises concerns for you, please consult a qualified professional."

Privacy. The privacy manifest declares Other Financial Info and Other User Content for bet history (Linked, not Tracked), User Content for quiz responses, User ID for Apple Sign-In, Product Interaction for TelemetryDeck (Not Linked, not Tracked), and Purchase History for RevenueCat. NSPrivacyTracking is false. Privacy policy: https://betautopsy.com/privacy. In-app account deletion is provided under Settings.

Age. The app is rated 17+ with Frequent Gambling content descriptor, overridden to 18+ for legal cover. The in-app age gate at first launch requires 18+ attestation. Sports betting age varies by US state and the app reminds users of 21+ where required.

How to test.

(1) Pre-seeded demo account, signs in to a populated dashboard.
Apple ID: appreview-2026@betautopsy.com
Password: ReviewBA_2026!

(2) Unauthenticated sample. On the welcome screen, tap "See a Sample Report." Full report rendering without sign-in.

(3) Reviewer bypass if Sign in with Apple fails on your network. On the sign-in screen, tap the BetAutopsy logo 5 times within 3 seconds, enter code 729104. Bypasses auth into the same demo account.

(4) Full upload flow. Sign out, sign back in, tap "Upload Bet History," select the attached BetAutopsy_AppReview_SampleBets.csv. Report generates in approximately 5 seconds.

A 90-second video walkthrough is attached as BetAutopsy_Walkthrough.mp4.

Reviewer test path. Cold launch. Age gate. Sample preview. Quiz. Archetype reveal. CSV upload via demo. Report rendering. Paywall walkthrough.

Founder contact: [Name], [Phone], [Email]. Available 9am-9pm ET for App Review Board calls.
```

## 12. Pre-emptive responses to likely reviewer questions

**"How does your app handle gambling content?"** BetAutopsy does not contain gambling content. It does not accept wagers, place bets, display live or future odds, recommend specific wagers, integrate with any sportsbook, or facilitate any real-money transaction. It performs statistical analysis on a user-uploaded CSV of historical betting records. Output is a descriptive report on past behavior, structurally analogous to a financial expense report or a Strava annual recap.

**"Are you licensed to provide gambling services in [territory]?"** No, and no license is required. BetAutopsy is not a gambling operator. It does not accept wagers, hold customer funds, settle outcomes, or offer odds. We are submitted by Diagnostic Sports, LLC, a registered US legal entity, in compliance with Guideline 5.1.1(ix). The closest precedent is Pikkit (id1586567110), which operates the same analytics-only model without any gambling licensing.

**"What is the user's source of bet history data?"** The user. Every major sportsbook (DraftKings, FanDuel, BetMGM, Caesars) provides self-service CSV export. Pikkit also provides CSV export of aggregated histories. The user exports the file on their own and uploads it to BetAutopsy. We have no API integrations to sportsbooks, we do not scrape, and we do not connect to operators.

**"How do you prevent users under 18 from accessing the app?"** Three mechanisms. Apple rating set to 17+ legacy and 18+ override. In-app age gate at first launch requiring 18+ attestation before any analysis can be initiated. Reminder to users of legal sports betting age in their state (21+ in most US states) at the gate. We will adopt Apple's Declared Age Range API once it ships GA.

**"Why is your app rated 17+ and not 18+?"** 17+ is the highest tier in Apple's legacy age rating system. We have used the "Override to Higher Age Rating" feature in App Store Connect to set the floor to 18+, and Apple's new 2025 age rating system maps Frequent Gambling content to 18+ automatically. In France, the ANFR rule displays 18+. In Brazil, the rating would auto-set to A18 if we were distributing there (we are not).

**"How does your in-app purchase work for gambling content?"** It does not. BetAutopsy's IAPs unlock digital diagnostic content (a behavioral report) consumed entirely inside the app. No IAP buys gambling credit, sweepstakes entries, lottery tickets, or anything redeemable on a gaming platform. Per Guideline 5.3.3, no IAP is used in conjunction with real-money gaming. The single report is a Consumable; the bundle is a Consumable; the annual is an Auto-Renewable Subscription.

**"Can you provide demo credentials?"** Yes, three ways. Pre-seeded Apple Sign-In account `appreview-2026@betautopsy.com` with password `ReviewBA_2026!` lands on a populated dashboard. An unauthenticated "See a Sample Report" button on the welcome screen shows the full report without sign-in. A reviewer bypass tap-sequence on the sign-in screen logo (5 taps in 3 seconds, code 729104) bypasses auth if Apple's SiwA fails. Plus a CSV file attached in Review Notes for the upload path.

**"What happens if a user uploads a CSV with a different format?"** Our parser detects invalid CSVs and surfaces a friendly error: "This CSV could not be parsed. Please ensure the file is a valid export from a supported sportsbook." Supported formats are listed in app help. No data is uploaded server-side until parsing succeeds. Reviewers can test by uploading any non-CSV file or a malformed CSV.

**"How do you handle responsible gambling concerns?"** Five mechanisms. 1-800-GAMBLER referenced on the home tab and in Settings, linked to ncpgambling.org. A "Warning Signs" chapter in the report that flags loss-chasing, escalating stakes, late-night clustering, and other patterns associated with problem gambling, with informational text and helpline references. An 18+ age gate at first launch. Explicit non-medical disclaimer: "BetAutopsy is not a medical or psychiatric tool." No notifications, rewards, or incentives that encourage additional betting.

## 13. The submission sequence

Day-by-day. The window from Day -10 to Day +5.

**Day -10.** Sign the Paid Applications Agreement. Submit W-9. Begin tax form clearance, which takes 3 to 5 business days and is a silent blocker for IAP. Privacy policy and Support URL live on production domains, not staging.

**Day -7.** Build 1 to internal TestFlight. Founder plus one or two collaborators test the full flow on real devices. Confirm Sign in with Apple works, demo account is pre-seeded with sample bets and rendered report, sample report path works without auth, reviewer bypass works.

**Day -5.** Build 2 (fixes from internal) to internal TestFlight. Demo account refreshed if needed. CSV attachment file finalized. 90-second walkthrough video recorded.

**Day -4.** Submit Build 2 to external TestFlight with a cohort of 10 trusted bettors. First-time external Beta App Review begins (24 to 48 hours). External TestFlight is less strict than App Store review but stricter than internal. Crashes, missing functionality, and metadata mismatches get bounced; polish does not.

**Day -3 to -2.** External cohort uses the app. Collect crash reports and qualitative feedback. Patch.

**Day -1.** Build 3 (final) to external TestFlight (auto-approves on the same version chain). Lock metadata, screenshots, IAP products, and demo credentials into the App Store Connect version. All three IAPs attached to the version on the In-App Purchases section.

**Day 0, Tuesday 9am ET.** Submit Build 3 plus metadata plus IAPs to App Store Review. Status: Waiting for Review.

**Day +1 to +2.** Status moves to In Review then Approved (median) or rejection notice. If rejected, reply within 6 hours via Reply to App Review with a specific response from the rejection-response playbook below. Most rejections clear on resubmission within another 24 hours.

**Day +2 if approved.** Set release option to Manual Release. Wait 24 hours for IAP propagation across Apple's CDN. RevenueCat explicitly warns against marketing before this window closes.

**Day +3.** Manually release. Begin marketing.

**Do not request expedited review on first submission.** It is rarely granted and may flag the app for closer scrutiny. Save expedite for the first post-launch hotfix if needed.

## 14. The rejection-response playbook

For each likely rejection, the response is pre-written. Reply within 6 hours.

**Rejected under 5.3 for facilitating gambling.** Reply: "BetAutopsy does not facilitate gambling. The app does not accept wagers, hold customer funds, display live odds, recommend wagers, or connect to any sportsbook or prediction market. The user manually exports their historical betting records as a CSV from a third-party tracker (Pikkit, id1586567110, is the recommended source; Pikkit operates the same analytics-only model and is approved on the App Store) and uploads the file directly. The output is a descriptive behavioral diagnostic report on past behavior, structurally similar to a financial expense report. Guideline 5.3.4 applies to apps offering real-money gaming, which we do not. We are submitted by Diagnostic Sports, LLC, satisfying 5.1.1(ix). The 'See a Sample Report' button on the welcome screen demonstrates the full product without any gambling activity."

**Rejected under 5.3 for licensing.** Reply: "BetAutopsy is not a gambling operator and does not require a gambling license. We do not accept wagers, settle outcomes, or hold customer funds. The structural precedent is Pikkit (id1586567110), Betstamp, OddsJam, and Juice Reel, none of which hold gambling licenses. The licensing requirement in 5.3.4 applies to operators offering real-money gaming, not to behavioral analytics tools."

**Rejected under 2.1 for demo credentials.** Reply: "We've provided three independent paths for testing. (1) Demo Apple Sign-In account `appreview-2026@betautopsy.com` / `ReviewBA_2026!` lands on a pre-seeded dashboard. (2) An unauthenticated 'See a Sample Report' button on the welcome screen renders the full report without any sign-in. (3) A reviewer bypass: tap the BetAutopsy logo 5 times within 3 seconds on the sign-in screen, enter code 729104. The attached 90-second video walkthrough demonstrates all three paths." Refresh the demo password if there's any chance it's been changed. Re-record the walkthrough showing the current build.

**Rejected under 2.3.1 for metadata.** Reply: "Every claim in the App Store listing maps to a screen visible in the demo account on first launch. The BetIQ score is on the dashboard. The behavioral archetype is on the first report screen. The dollar-impact analysis is in Chapter 3. The 7-chapter report is the report container itself. The attached walkthrough demonstrates each claim in order." Adjust description copy if the rejection specifies a particular claim.

**Rejected under 3.1.1 for IAP issues.** Reply: "The three IAPs are configured and attached to this build version in the In-App Purchases section of the version page. Single Report (Consumable, $9.99), Three-Report Bundle (Consumable, $19.99), Annual Pro (Auto-Renewable, $99.99/yr). The paywall is reachable from the dashboard's 'Generate New Report' CTA. Sandbox testing confirmed all three work as of [date]. Paid Applications Agreement is signed." Verify in App Store Connect that all IAPs show "Ready to Submit" and are attached.

**Rejected under 4.2 for thin app.** Reply: "BetAutopsy is not a one-shot tool. The app supports re-uploading fresh CSVs at any time for recalibrated reports, includes a 12-entry Behavioral Patterns glossary browsable anytime, generates exportable PDF reports, and the annual subscription delivers monthly longitudinal trend analysis and historical archive. The walkthrough video shows the Patterns library and re-run flow at 0:47."

**Rejected under 1.1 for objectionable content or 1.4.1 for medical claims.** Reply: "BetAutopsy makes no medical or clinical claims. User-facing strings use 'behavioral patterns,' 'bias indicators,' 'decision history,' never 'diagnose,' 'addiction,' 'pathological,' or 'disorder.' The app includes a permanent non-medical disclaimer in Settings and the 'Warning Signs' chapter explicitly references 1-800-GAMBLER and ncpgambling.org. The diagnostic-framing comparable is 23andMe (id952516687), whose disclaimer language we have modeled."

**Rejected under 5.1.1 for privacy.** Reply: "The PrivacyInfo.xcprivacy declares NSPrivacyTracking false and four required-reason APIs (UserDefaults CA92.1, FileTimestamp C617.1+3B52.1, SystemBootTime 35F9.1, DiskSpace E174.1). Six collected data types are declared. The App Store Connect privacy labels match the manifest. Privacy policy at https://betautopsy.com/privacy discloses every category. In-app account deletion is at Settings → Account → Delete Account. We are submitted by Diagnostic Sports, LLC per 5.1.1(ix)."

**After two rejections on the same issue.** Request an App Review Board call through Reply to App Review. Include a written summary of the issue and the responses already provided. The board will assign a senior reviewer and the case typically resolves within 5 to 7 days.

## 15. The week-before-submission order of operations

A specific seven-day checklist. Run in this order. Each line is binary, done or not done.

**Monday.** Paid Applications Agreement signed. W-9 submitted. Privacy policy URL live. Support URL live. Legal entity (Diagnostic Sports, LLC) confirmed in App Store Connect → Business → Legal Entity. Bundle ID `com.diagnosticsports.BetAutopsy` registered. Team ID PAU6GLBN86 confirmed.

**Tuesday.** Three IAPs created in App Store Connect. Each in "Ready to Submit" status. RevenueCat product IDs match exactly. Sandbox purchase test passes for each product on a real device. Subscription group "BetAutopsy Pro" created. Family Sharing confirmed off on all three.

**Wednesday.** Build 1.0 (1) produced. Privacy manifest in app target. RevenueCat SDK via SPM. TelemetryDeck SDK via SPM. Sign in with Apple capability enabled. Build uploaded to App Store Connect via Xcode or Transporter. Internal TestFlight active.

**Thursday.** All metadata complete. Name (BetAutopsy: Bet Diagnostic), subtitle (Forensic Bet History Analysis), promotional text, description, keywords, copyright, primary category (Sports), secondary (Lifestyle). Screenshots (1290 × 2796) for iPhone 6.9". App Preview video 15 to 30 seconds. Age rating questionnaire answered with Override to Higher Age Rating set to 18+.

**Friday.** Demo Apple Sign-In account created and pre-seeded with three months of sample bets and a generated report. Reviewer bypass tap-sequence tested. Sample report path on welcome screen tested without sign-in. CSV attachment `BetAutopsy_AppReview_SampleBets.csv` finalized. 90-second walkthrough video recorded and attached.

**Saturday and Sunday.** Beta cohort uses the external TestFlight build. Collect crashes. Triage feedback. No submissions on weekends.

**Monday.** Final build uploaded. All three IAPs attached to version page in In-App Purchases section. Demo credentials confirmed in App Review Information. Notes for Review paragraph pasted. CSV and video attached. Territories selected (the 34-country list). Release option set to Manual Release.

**Tuesday 9am ET.** Submit.

## 16. The one-page App Review submission checklist

Drop this on a single sheet at submission time.

**Legal and identity.** Submitted by Diagnostic Sports, LLC (not individual). Team ID PAU6GLBN86. Paid Applications Agreement signed. W-9 cleared. Privacy policy live at https://betautopsy.com/privacy. Support URL live.

**Build.** Bundle ID `com.diagnosticsports.BetAutopsy`. Sign in with Apple capability on. RevenueCat SDK and TelemetryDeck SDK via SPM. Privacy manifest at app target with NSPrivacyTracking=false, four required-reason APIs, six collected-data types.

**Metadata.** Name "BetAutopsy: Bet Diagnostic" (26). Subtitle "Forensic Bet History Analysis" (29). Primary category Sports. Secondary Lifestyle. Age rating 17+ legacy with Override to 18+. Frequent Gambling = Yes. Simulated Gambling = No. Medical/Treatment = Infrequent/Mild. Everything else None. Compliance block at the end of description includes "not a sportsbook," "does not accept wagers," "does not provide picks," "1-800-GAMBLER," 18+ requirement, and league non-affiliation.

**IAPs.** Three products in Ready to Submit status, all attached to the version page. Single Report Consumable $9.99. Three-Report Bundle Consumable $19.99. Annual Auto-Renewable Subscription $99.99 in "BetAutopsy Pro" group. Family Sharing off on all three.

**Demo.** Apple Sign-In demo account `appreview-2026@betautopsy.com` / `ReviewBA_2026!` pre-seeded. "See a Sample Report" on welcome screen works without auth. Reviewer bypass (5 logo taps, code 729104) tested. Sample CSV attached. 90-second walkthrough video attached.

**Review Notes.** Full paragraph pasted (Section 11 above), with founder name, phone, email at the end.

**Territories.** 34 countries enabled. Brazil excluded. MENA excluded. China/HK/Macau excluded. Russia/Turkey/Belarus excluded. South Korea excluded. Most of South Asia and SE Asia excluded.

**Submission timing.** Tuesday morning ET. Manual release. No expedite request.

## Closing

The strategy works because every individual element is borrowed from an approved comparable. Pikkit's disclaimer language. MacroFactor's subscription justification. 23andMe's medical disclaimer. OddsJam's lean privacy posture. Action Network's no-picks disavowal. Rithmm's self-imposed 21+ in copy. Each element is a small, defensible move. The composition is BetAutopsy.

The single failure mode that kills launch is a 2.1 demo-credentials rejection from a reviewer who has no bet history of their own. Three independent demo paths, a CSV attachment, and a walkthrough video close this off. The second failure mode is a 5.3 reflex from a reviewer who reads "betting" and applies the operator-licensing clause without reading further. The Review Notes paragraph defuses this by leading with "we are not a sportsbook" and citing Pikkit as precedent.

If the app is rejected once, the rejection-response playbook in Section 14 has the reply pre-written. If rejected twice on the same issue, escalate to the App Review Board. Most first-time gambling-adjacent apps clear on submission 1 or 2. Plan for two cycles; aim for one.

Submit Tuesday morning. Release Manual. Wait the 24 hours for IAP propagation. Then ship.