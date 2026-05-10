//
//  src/trigger/analyzeCsv.ts
//  Trigger.dev task: analyze-csv
//
//  Stub for now. Real implementation will:
//  1. Download CSV from Supabase Storage signed URL
//  2. Parse with existing TypeScript parser (ported from Vercel)
//  3. Run archetype classifier waterfall (Heat Chaser → Parlay Dreamer → Surgeon → Grinder → Gut Bettor)
//  4. Run bias detection rules
//  5. Stream Claude analysis via CF Worker (claude-stream)
//  6. Write report to Supabase reports table
//
//  Triggered from iOS app after user uploads CSV to Supabase Storage.
//

import { task } from "@trigger.dev/sdk/v3";

type AnalyzeCsvPayload = {
  userId: string;
  reportId: string;
  csvUrl: string;
};

type AnalyzeCsvOutput = {
  reportId: string;
  archetype: string;
  dollarImpact: number;
  heatedSessionCount: number;
  topBiases: string[];
  status: "complete" | "failed";
};

export const analyzeCsv = task({
  id: "analyze-csv",
  maxDuration: 300,
  run: async (payload: AnalyzeCsvPayload, { ctx }): Promise<AnalyzeCsvOutput> => {
    console.log("Starting analyze-csv task", { payload, runId: ctx.run.id });

    // STUB: real implementation goes here in a future session
    // For now: return realistic mock output

    await new Promise(resolve => setTimeout(resolve, 2000)); // simulate work

    const mockOutput: AnalyzeCsvOutput = {
      reportId: payload.reportId,
      archetype: "Heat Chaser",
      dollarImpact: 1847,
      heatedSessionCount: 6,
      topBiases: ["Recency bias", "Sunk cost fallacy", "Hot hand fallacy"],
      status: "complete",
    };

    console.log("analyze-csv task complete (stub)", mockOutput);

    return mockOutput;
  },
});
