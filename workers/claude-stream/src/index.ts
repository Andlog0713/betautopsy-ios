//
//  src/index.ts
//  claude-stream worker
//
//  Streams Claude API responses to iOS app via SSE.
//  Bypasses Vercel's 60-second function timeout.
//
//  Endpoints:
//    GET  /         → health check
//    POST /stream   → proxies streaming Claude completion
//

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import Anthropic from '@anthropic-ai/sdk';

type Env = {
  ANTHROPIC_API_KEY: string;
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
};

type StreamRequest = {
  messages: Array<{
    role: 'user' | 'assistant';
    content: string;
  }>;
  system?: string;
  max_tokens?: number;
  model?: string;
};

const app = new Hono<{ Bindings: Env }>();

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// Health check
app.get('/', (c) => {
  return c.json({
    status: 'ok',
    service: 'claude-stream',
    version: '0.1.0',
  });
});

// Streaming proxy
app.post('/stream', async (c) => {
  // Verify auth: require Bearer token in Authorization header
  // (real Supabase JWT validation comes later when auth is wired)
  const authHeader = c.req.header('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Missing Authorization header' }, 401);
  }

  let body: StreamRequest;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: 'Invalid JSON body' }, 400);
  }

  if (!body.messages || !Array.isArray(body.messages) || body.messages.length === 0) {
    return c.json({ error: 'messages array required' }, 400);
  }

  const anthropic = new Anthropic({
    apiKey: c.env.ANTHROPIC_API_KEY,
  });

  // Set up streaming response
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      try {
        const messageStream = anthropic.messages.stream({
          model: body.model ?? 'claude-sonnet-4-5-20250929',
          max_tokens: body.max_tokens ?? 4096,
          system: body.system,
          messages: body.messages,
        });

        for await (const event of messageStream) {
          // Forward each event as Server-Sent Event
          const sseData = `event: ${event.type}\ndata: ${JSON.stringify(event)}\n\n`;
          controller.enqueue(encoder.encode(sseData));
        }

        // Send final done event
        controller.enqueue(encoder.encode(`event: done\ndata: {}\n\n`));
        controller.close();
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : 'Unknown error';
        controller.enqueue(
          encoder.encode(`event: error\ndata: ${JSON.stringify({ error: errorMsg })}\n\n`)
        );
        controller.close();
      }
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
});

export default app;
