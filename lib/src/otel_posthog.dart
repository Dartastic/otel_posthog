// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_posthog_suppression.dart';

const _loggerName = 'package.posthog';

/// Bridges PostHog product analytics into OpenTelemetry log records.
///
/// Wrap your existing PostHog usage in [OTelPostHog]: every
/// `capture` / `identify` / `alias` / `group` call lands as an OTel
/// log record carrying the full payload. Optional `forwardXxx`
/// callbacks let you also forward to your existing PostHog client.
class OTelPostHog {
  /// Creates a bridge. Forward callbacks default to null (OTel-only).
  OTelPostHog({
    LoggerProvider? loggerProvider,
    this.forwardCapture,
    this.forwardIdentify,
    this.forwardAlias,
    this.forwardGroup,
  }) : _loggerProvider = loggerProvider;

  final LoggerProvider? _loggerProvider;

  /// Forward a `capture` event to the real PostHog client.
  final void Function(String eventName, Map<String, Object?>? properties)?
      forwardCapture;

  /// Forward an `identify` call.
  final void Function(String distinctId, Map<String, Object?>? userProperties)?
      forwardIdentify;

  /// Forward an `alias` call.
  final void Function(String alias)? forwardAlias;

  /// Forward a `group` call.
  final void Function(
    String groupType,
    String groupKey,
    Map<String, Object?>? groupProperties,
  )? forwardGroup;

  OTelLogger _logger() =>
      (_loggerProvider ?? OTel.loggerProvider()).getLogger(_loggerName);

  /// Captures an event. Forwards to PostHog if [forwardCapture] is set.
  void capture(String eventName, {Map<String, Object?>? properties}) {
    forwardCapture?.call(eventName, properties);
    if (postHogInstrumentationSuppressed()) return;
    _emit(
      body: 'posthog.capture $eventName',
      eventType: 'capture',
      base: <Attribute<Object>>[
        OTel.attributeString('posthog.event_name', eventName),
      ],
      flatPrefix: 'posthog.property.',
      payload: properties,
    );
  }

  /// Identifies the current user (and optionally sets user properties).
  void identify(String distinctId, {Map<String, Object?>? userProperties}) {
    forwardIdentify?.call(distinctId, userProperties);
    if (postHogInstrumentationSuppressed()) return;
    _emit(
      body: 'posthog.identify $distinctId',
      eventType: 'identify',
      base: <Attribute<Object>>[
        OTel.attributeString('posthog.distinct_id', distinctId),
        OTel.attributeString(User.userId.key, distinctId),
      ],
      flatPrefix: 'posthog.user_property.',
      payload: userProperties,
    );
  }

  /// Adds an alias for the current user.
  void alias(String alias) {
    forwardAlias?.call(alias);
    if (postHogInstrumentationSuppressed()) return;
    _emit(
      body: 'posthog.alias $alias',
      eventType: 'alias',
      base: <Attribute<Object>>[
        OTel.attributeString('posthog.alias', alias),
      ],
    );
  }

  /// Associates the user with a group (organization / project).
  void group(
    String groupType,
    String groupKey, {
    Map<String, Object?>? groupProperties,
  }) {
    forwardGroup?.call(groupType, groupKey, groupProperties);
    if (postHogInstrumentationSuppressed()) return;
    _emit(
      body: 'posthog.group $groupType:$groupKey',
      eventType: 'group',
      base: <Attribute<Object>>[
        OTel.attributeString('posthog.group_type', groupType),
        OTel.attributeString('posthog.group_key', groupKey),
      ],
      flatPrefix: 'posthog.group_property.',
      payload: groupProperties,
    );
  }

  void _emit({
    required String body,
    required String eventType,
    required List<Attribute<Object>> base,
    String? flatPrefix,
    Map<String, Object?>? payload,
  }) {
    final all = <Attribute<Object>>[
      OTel.attributeString('posthog.event_type', eventType),
      ...base,
    ];
    if (payload != null && flatPrefix != null) {
      payload.forEach((k, v) {
        if (v == null) return;
        final key = '$flatPrefix$k';
        if (v is String) {
          all.add(OTel.attributeString(key, v));
        } else if (v is int) {
          all.add(OTel.attributeInt(key, v));
        } else if (v is double) {
          all.add(OTel.attributeDouble(key, v));
        } else if (v is bool) {
          all.add(OTel.attributeBool(key, v));
        } else {
          all.add(OTel.attributeString(key, v.toString()));
        }
      });
    }
    _logger().emit(
      severityNumber: Severity.INFO,
      severityText: 'info',
      body: body,
      attributes: OTel.attributes(all),
    );
  }
}
