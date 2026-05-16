// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_posthog/otel_posthog.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemoryLogExporter logs;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_posthog-test',
    );
    logs = harness.logs;
  });

  setUp(() async {
    await harness.flushLogs();
    harness.clear();
  });

  Map<String, Object> attrsOf(LogRecord r) {
    final out = <String, Object>{};
    for (final a in r.attributes?.toList() ?? const <Attribute<Object>>[]) {
      out[a.key] = a.value;
    }
    return out;
  }

  test('capture emits INFO log with flattened properties', () async {
    final p = OTelPostHog();
    p.capture(
      'order_completed',
      properties: const {'revenue': 49.99, 'currency': 'USD', 'items': 3},
    );
    await harness.flushLogs();
    final rec = logs.records.single;
    expect(rec.body, 'posthog.capture order_completed');
    final a = attrsOf(rec);
    expect(a['posthog.event_type'], 'capture');
    expect(a['posthog.event_name'], 'order_completed');
    expect(a['posthog.property.revenue'], 49.99);
    expect(a['posthog.property.currency'], 'USD');
    expect(a['posthog.property.items'], 3);
  });

  test('identify emits log with user.id + distinct_id + traits', () async {
    final p = OTelPostHog();
    p.identify('user-42', userProperties: const {'plan': 'pro'});
    await harness.flushLogs();
    final a = attrsOf(logs.records.single);
    expect(a['posthog.event_type'], 'identify');
    expect(a['posthog.distinct_id'], 'user-42');
    expect(a['user.id'], 'user-42');
    expect(a['posthog.user_property.plan'], 'pro');
  });

  test('alias + group each emit their own event_type', () async {
    final p = OTelPostHog();
    p.alias('user-new');
    p.group(
      'organization',
      'org-1',
      groupProperties: const {'plan': 'enterprise'},
    );
    await harness.flushLogs();
    final byType = {
      for (final r in logs.records)
        attrsOf(r)['posthog.event_type'] as String: attrsOf(r),
    };
    expect(byType['alias']!['posthog.alias'], 'user-new');
    expect(byType['group']!['posthog.group_type'], 'organization');
    expect(byType['group']!['posthog.group_key'], 'org-1');
    expect(byType['group']!['posthog.group_property.plan'], 'enterprise');
  });

  test('forward callbacks fire when supplied', () async {
    String? capturedEvent;
    final p = OTelPostHog(forwardCapture: (e, _) => capturedEvent = e);
    p.capture('forwarded');
    expect(capturedEvent, 'forwarded');
  });

  test('suppression skips OTel emit but still forwards', () async {
    var forwarded = 0;
    final p = OTelPostHog(forwardCapture: (_, __) => forwarded++);
    await runWithoutPostHogInstrumentationAsync(() async {
      p.capture('x');
    });
    await harness.flushLogs();
    expect(logs.records, isEmpty);
    expect(forwarded, 1);
  });
}
