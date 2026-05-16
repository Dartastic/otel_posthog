// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// OpenTelemetry bridge for PostHog product analytics.
///
/// Wrap your PostHog usage in [OTelPostHog]: every `capture` /
/// `identify` / `alias` / `group` call lands as an OTel log record
/// with `posthog.*` attrs. Pass `forwardXxx` callbacks to also
/// forward to a real PostHog client, or omit them for OTel-only emit.
library;

export 'src/otel_posthog.dart';
export 'src/otel_posthog_suppression.dart';
