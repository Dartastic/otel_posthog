// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #dartastic_otel_libs_posthog_suppress;

bool postHogInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

T runWithoutPostHogInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

Future<T> runWithoutPostHogInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
