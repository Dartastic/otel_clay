// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_clay/otel_clay.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_clay-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('cells.run_formula records waterfall step + provider + credits',
      () async {
    await tracedClay<String>(
      operation: 'cells.run_formula',
      invoke: () async => const ClayCallResult(
        value: 'ok',
        result: ClayResult(
          workspaceId: 'ws_1',
          tableId: 'tbl_1',
          tableName: 'target_prospects',
          columnId: 'col_email',
          columnName: 'work_email',
          formulaType: 'enrichment',
          providerKey: 'apollo',
          waterfallStep: 2,
          waterfallStepsTotal: 5,
          match: true,
          rowsProcessed: 1,
          creditsClay: 1,
          creditsProvider: 1,
          cachedHit: false,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('clay cells.run_formula')!);
    expect(a['clay.formula.type'], 'enrichment');
    expect(a['clay.provider.key'], 'apollo');
    expect(a['clay.waterfall.step'], 2);
    expect(a['clay.match'], true);
    expect(a['clay.credits.clay'], 1);
  });

  test('cache hit records zero credits with match', () async {
    await tracedClay<String>(
      operation: 'cells.run_formula',
      invoke: () async => const ClayCallResult(
        value: 'ok',
        result: ClayResult(
          providerKey: 'clearbit',
          waterfallStep: 1,
          match: true,
          creditsClay: 0,
          cachedHit: true,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('clay cells.run_formula')!);
    expect(a['clay.cached.hit'], true);
    expect(a['clay.credits.clay'], 0);
  });

  test('HTTP 429 sets span error', () async {
    await tracedClay<String>(
      operation: 'rows.create',
      invoke: () async => const ClayCallResult(
        value: 'ok',
        result: ClayResult(statusCode: 429),
      ),
    );
    expect(
      spans.findSpanByName('clay rows.create')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutClayInstrumentationAsync(() async {
      await tracedClay<String>(
        operation: 'tables.list',
        invoke: () async => const ClayCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('clay '), isEmpty);
  });
}
