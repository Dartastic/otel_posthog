// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

/// OpenTelemetry bridge for PostHog product analytics.
///
/// Wrap your PostHog usage in [OTelPostHog]: every `capture` /
/// `identify` / `alias` / `group` call lands as an OTel log record
/// with `posthog.*` attrs. Pass `forwardXxx` callbacks to also
/// forward to a real PostHog client, or omit them for OTel-only emit.
library;

export 'src/otel_posthog.dart';
export 'src/otel_posthog_suppression.dart';
