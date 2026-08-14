# Architecture

Product: see `specs/SPECS.md`. Update paths here as you implement (pointers only, no code dumps).

```text
src/
  index.ts   # Entry — starts HTTP server
  server.ts  # Node http server + routing
tests/
  health.test.ts  # GET /health integration test
  smoke.test.ts
```

Harness: `docs/HARNESS.md`.
