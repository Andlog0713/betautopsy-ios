//
//  DecodeProofV3.swift
//  BetAutopsyTests (no test target exists; this is a standalone harness)
//
//  Decode proof for the report-trust wire format (web PR #74,
//  schema_version 3). Decodes the REAL deployed report row (Andrew's
//  account, created_at 2026-06-12 17:37:05, id 406e226d) through the
//  production iOS structs using the exact network decoder config
//  (.convertFromSnakeCase, AnalyzeClient.swift:542) and asserts the
//  new fields survive. If any assertion fails, the CodingKeys are
//  wrong: fix the models, not the harness.
//
//  Run from repo root (fixture path can be overridden as argv[1]):
//
//    swiftc -parse-as-library \
//      BetAutopsy/BetAutopsy/ReportModels.swift \
//      BetAutopsy/BetAutopsy/Tokens.swift \
//      BetAutopsy/BetAutopsy/BAFormat.swift \
//      BetAutopsy/BetAutopsy/Extensions/Int+Pluralize.swift \
//      BetAutopsy/BetAutopsy/Extensions/String+FirstSentence.swift \
//      BetAutopsyTests/DecodeProofV3.swift \
//      -o /tmp/decode_proof_v3 && /tmp/decode_proof_v3 <fixture.json>
//
//  The fixture is the raw report_json value pulled from Supabase
//  (autopsy_reports table). It contains real betting data; keep it in
//  /tmp, do not commit it.
//

import Foundation

@main
struct DecodeProofV3 {
    static var failures = 0

    static func check(_ name: String, _ condition: Bool, detail: String = "") {
        if condition {
            print("  PASS  \(name)\(detail.isEmpty ? "" : "  [\(detail)]")")
        } else {
            failures += 1
            print("  FAIL  \(name)\(detail.isEmpty ? "" : "  [\(detail)]")")
        }
    }

    static func main() throws {
        let path = CommandLine.arguments.count > 1
            ? CommandLine.arguments[1]
            : "/tmp/ba_report_json_v3.json"
        let data = try Data(contentsOf: URL(fileURLWithPath: path))

        // Exact production network decoder config (AnalyzeClient.swift:542).
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let analysis = try decoder.decode(AutopsyAnalysis.self, from: data)

        print("schema_version: \(analysis.schemaVersion.map(String.init) ?? "nil")")
        check("schemaVersion == 3", analysis.schemaVersion == 3)

        // recovery (TOP-LEVEL, camelCase wire keys)
        check("recovery != nil", analysis.recovery != nil)
        check("recovery.method != nil",
              analysis.recovery?.method.isEmpty == false,
              detail: analysis.recovery?.method ?? "nil")
        check("recovery.netUSD == -7862", analysis.recovery?.netUSD == -7862)
        check("recovery.biggestSingleLeakUSD == 17971",
              analysis.recovery?.biggestSingleLeakUSD == 17971)
        check("recovery.rangeLow == 14000", analysis.recovery?.rangeLow == 14000)
        check("recovery.overlapsExist == true", analysis.recovery?.overlapsExist == true)

        // charts
        check("charts != nil", analysis.charts != nil)
        check("charts.sessionTimeline.count == 4",
              analysis.charts?.sessionTimeline.count == 4,
              detail: "\(analysis.charts?.sessionTimeline.count ?? -1)")
        check("timeline last stakeUSD == 1000",
              analysis.charts?.sessionTimeline.last?.stakeUSD == 1000)
        check("timeline chase markers == 3",
              analysis.charts?.sessionTimeline.filter { $0.isChaseMarker }.count == 3)
        check("charts.heroSession != nil", analysis.charts?.heroSession != nil)
        check("heroSession.sessionId == SESSION-304",
              analysis.charts?.heroSession?.sessionId == "SESSION-304")
        check("heroSession.framing == loss",
              analysis.charts?.heroSession?.framing == "loss")
        check("charts.timeOfDayPnl.count == 24",
              analysis.charts?.timeOfDayPnl.count == 24)
        check("charts.dayOfWeekPnl.count == 7",
              analysis.charts?.dayOfWeekPnl.count == 7)
        check("dayOfWeekPnl[0].netUSD == -1244.4",
              analysis.charts?.dayOfWeekPnl.first?.netUSD == -1244.4)
        check("oddsBuckets[0].roiPct == 31.25",
              analysis.charts?.oddsBuckets.first?.roiPct == 31.25)
        check("stakeByStreak.after3LossesUSD == 90.74",
              analysis.charts?.stakeByStreak?.after3LossesUSD == 90.74)
        check("betTypeMix[0].betClass == other (wire key \"class\")",
              analysis.charts?.betTypeMix.first?.betClass == "other")

        // per-finding metadata (snake_case sub_splits: the acronym trap)
        let firstBias = analysis.biasesDetected.first
        check("first bias confidence != nil",
              firstBias?.confidence != nil,
              detail: firstBias?.confidence ?? "nil")
        check("first bias sub_splits decoded (2 rows)",
              firstBias?.subSplits?.count == 2)
        check("sub_split[0].netUSD == -9804.69 (wire net_usd)",
              firstBias?.subSplits?.first?.netUSD == -9804.69)
        check("sub_split[0].roiPct == -12.43 (wire roi_pct)",
              firstBias?.subSplits?.first?.roiPct == -12.43)
        let firstLeak = analysis.strategicLeaks.first
        check("first leak severity != nil",
              firstLeak?.severity != nil,
              detail: firstLeak?.severity ?? "nil")
        check("first leak confidence != nil", firstLeak?.confidence != nil)
        let sportFinding = analysis.sportSpecificFindings?.first
        check("sport finding confidence != nil", sportFinding?.confidence != nil)
        check("sport sub_split netUSD == -4087 with roiPct nil (null tolerance)",
              sportFinding?.subSplits?.first?.netUSD == -4087
                && sportFinding?.subSplits?.first?.roiPct == nil)

        // DetectedSession.framing on heated sessions
        let framedSessions = analysis.sessionDetection?.sessions.filter { $0.framing != nil } ?? []
        check("heated sessions carry framing", !framedSessions.isEmpty,
              detail: "\(framedSessions.count) sessions")

        // Cache round-trip: encode with the cache codec (default keys,
        // ReportCache.swift) and decode back; charts must survive.
        let cacheEncoder = JSONEncoder()
        let cacheData = try cacheEncoder.encode(analysis)
        let cacheDecoder = JSONDecoder()
        let roundTrip = try cacheDecoder.decode(AutopsyAnalysis.self, from: cacheData)
        check("cache round-trip preserves charts.sessionTimeline",
              roundTrip.charts?.sessionTimeline.count == 4)
        check("cache round-trip preserves recovery.netUSD",
              roundTrip.recovery?.netUSD == -7862)
        check("cache round-trip preserves bias subSplits.netUSD",
              roundTrip.biasesDetected.first?.subSplits?.first?.netUSD == -9804.69)

        print(failures == 0 ? "\nDECODE PROOF: ALL PASS" : "\nDECODE PROOF: \(failures) FAILURE(S)")
        exit(failures == 0 ? 0 : 1)
    }
}
