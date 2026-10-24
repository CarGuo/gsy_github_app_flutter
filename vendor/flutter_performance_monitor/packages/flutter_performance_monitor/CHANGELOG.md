## 0.1.0 (unreleased, private)

- 2026-10-23: make frame collection passive for default driver frameSync,
  widget-test completion and idle tasks; preserve page scenes under popups
- Retain detached windows until worker acknowledgement; isolate invalid events
  and distinguish materialization failure from storage failure
- Enforce outbox ownership across isolates/processes using an ownership worker;
  publish capacity estimates and reject conflicting active configurations
- Defer automatic export until the first observed raster timing; invalidate
  startup samples interrupted by backgrounding; expose local CPU failure detail
- Add per-send HTTPS authorization, preserve 401/403 batches during credential
  recovery, and distinguish caller cancellation from transport failure

- Add central monitor lifecycle, stable scene/operation registries and optional session sampling
- Add passive frameNumber context association, bounded retention and explicit attribution/repetition diagnostics
- Add fixed-bucket histograms and immutable schema-1 events
- Add shared package:http headers timing and explicit operation wall-time measurement
- 2026-10-23: detach complete recorder windows before asynchronously validating
  and encoding them on a worker; reserve sequence IDs before yielding so collection
  continues without changing event identity or window boundaries. Share an
  idempotent send-to-headers token between package:http and the optional Dio adapter
- Add process RSS and Android/Darwin CPU sampling with unsupported/error paths
- 2026-10-23: execute Android/iOS process sampling on Flutter background task
  queues and macOS sampling on a serial DispatchQueue. Preserve the existing
  deadline and wire diagnostics, with one local failure-kind/wait snapshot for
  investigating native errors without retaining private exception details
- Add bounded durable OTLP JSON Logs export, retry/partial-success handling and process-restart recovery
- Keep live outbox retry/rate/TTL progress moving after clock rollback or error
  with a private elapsed-time fallback. Persisted epoch timestamps and restart/skew
  policy remain unchanged; forward corrections can still advance age
- Treat oversized decoded OTLP responses as explicit loss, except 401/403 which
  preserve the batch for authentication recovery; never mistake them for ACKs
- Skip writer work for fully capacity-rejected nonempty direct enqueues while
  preserving earlier accepted-write completion and all drop diagnostics. This is
  direct-API backpressure hardening, not a facade/device speedup claim
- Move pure bounded queue codecs to short-lived serially awaited isolates; retain one owner for state, files and transport
- Add canonical example, ordinary engine probe, real Collector/ClickHouse reconciliation and host measurement tools
- Keep physical-device performance, native Apple builds, minimum Flutter compatibility and Grafana datasource/UI gates explicit

No production-performance, universal navigation coverage or public release claim
is implied by this initial implementation.
