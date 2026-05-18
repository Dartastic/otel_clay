// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_clay_suppression.dart';

const _tracerName = 'dartastic_otel_libs_clay';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class ClayResult {
  const ClayResult({
    this.workspaceId,
    this.tableId,
    this.tableName,
    this.columnId,
    this.columnName,
    this.formulaType,
    this.providerKey,
    this.waterfallStep,
    this.waterfallStepsTotal,
    this.match,
    this.rowsProcessed,
    this.creditsClay,
    this.creditsProvider,
    this.cachedHit,
    this.webhookDelivered,
    this.statusCode,
  });

  /// Clay workspace.
  final String? workspaceId;

  final String? tableId;
  final String? tableName;

  final String? columnId;
  final String? columnName;

  /// `enrichment` / `formula` / `ai` / `http` / `claygent` /
  /// `webhook` / `lookup`.
  final String? formulaType;

  /// Provider invoked by the enrichment cell (`apollo` / `clearbit` /
  /// `hunter` / `findymail` / `prospeo` / `zerobounce` /
  /// `linkedin_scraper` / `peopledatalabs` / `openai` / `anthropic`
  /// / `serper` / ...).
  final String? providerKey;

  /// Position within the waterfall (1-based) — Clay tries providers in
  /// order until one matches.
  final int? waterfallStep;

  final int? waterfallStepsTotal;

  /// `true` if this provider returned data (waterfall stops on match).
  final bool? match;

  /// Number of rows the formula ran across.
  final int? rowsProcessed;

  /// Clay credits charged at the table level (the displayed price).
  final int? creditsClay;

  /// Underlying provider credit/charge (sometimes zero when Clay
  /// absorbs the cost in its bundled plan).
  final int? creditsProvider;

  /// `true` when Clay served a cached enrichment instead of charging
  /// new credits.
  final bool? cachedHit;

  /// `true` when the row was forwarded to a downstream webhook.
  final bool? webhookDelivered;

  final int? statusCode;
}

class ClayCallResult<T> {
  const ClayCallResult({required this.value, this.result});
  final T value;
  final ClayResult? result;
}

/// Wraps a Clay API call in a CLIENT span. [operation] is one of
/// `tables.list`, `tables.get`, `tables.create`, `rows.create`,
/// `rows.list`, `rows.update`, `rows.delete`, `cells.run_formula`,
/// `cells.write`, `cells.batch_write`, `workflows.run`,
/// `webhooks.send`.
Future<T> tracedClay<T>({
  required String operation,
  required Future<ClayCallResult<T>> Function() invoke,
}) async {
  if (clayInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'clay',
    'rpc.method': operation,
    'clay.operation': operation,
  };

  final span = _tracer().startSpan(
    'clay $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.workspaceId != null) {
        extras.add(OTel.attributeString(
          'clay.workspace.id',
          r.result!.workspaceId!,
        ));
      }
      if (r.result!.tableId != null) {
        extras.add(OTel.attributeString(
          'clay.table.id',
          r.result!.tableId!,
        ));
      }
      if (r.result!.tableName != null) {
        extras.add(OTel.attributeString(
          'clay.table.name',
          r.result!.tableName!,
        ));
      }
      if (r.result!.columnId != null) {
        extras.add(OTel.attributeString(
          'clay.column.id',
          r.result!.columnId!,
        ));
      }
      if (r.result!.columnName != null) {
        extras.add(OTel.attributeString(
          'clay.column.name',
          r.result!.columnName!,
        ));
      }
      if (r.result!.formulaType != null) {
        extras.add(OTel.attributeString(
          'clay.formula.type',
          r.result!.formulaType!,
        ));
      }
      if (r.result!.providerKey != null) {
        extras.add(OTel.attributeString(
          'clay.provider.key',
          r.result!.providerKey!,
        ));
      }
      if (r.result!.waterfallStep != null) {
        extras.add(OTel.attributeInt(
          'clay.waterfall.step',
          r.result!.waterfallStep!,
        ));
      }
      if (r.result!.waterfallStepsTotal != null) {
        extras.add(OTel.attributeInt(
          'clay.waterfall.steps_total',
          r.result!.waterfallStepsTotal!,
        ));
      }
      if (r.result!.match != null) {
        extras.add(OTel.attributeBool('clay.match', r.result!.match!));
      }
      if (r.result!.rowsProcessed != null) {
        extras.add(OTel.attributeInt(
          'clay.rows.processed',
          r.result!.rowsProcessed!,
        ));
      }
      if (r.result!.creditsClay != null) {
        extras.add(OTel.attributeInt(
          'clay.credits.clay',
          r.result!.creditsClay!,
        ));
      }
      if (r.result!.creditsProvider != null) {
        extras.add(OTel.attributeInt(
          'clay.credits.provider',
          r.result!.creditsProvider!,
        ));
      }
      if (r.result!.cachedHit != null) {
        extras.add(OTel.attributeBool(
          'clay.cached.hit',
          r.result!.cachedHit!,
        ));
      }
      if (r.result!.webhookDelivered != null) {
        extras.add(OTel.attributeBool(
          'clay.webhook.delivered',
          r.result!.webhookDelivered!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Clay HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
