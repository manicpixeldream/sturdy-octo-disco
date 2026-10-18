import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/affidavit.dart';
import 'package:gavel/data/models/case_brief.dart';
import 'package:gavel/data/models/stipulation.dart';
import 'package:gavel/data/models/timing_rule.dart';
import 'package:gavel/data/models/trial_side.dart';

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));
  Map<String, Object?> jsonRoundTrip(Map<String, Object?> map) =>
      Map<String, Object?>.from(jsonDecode(jsonEncode(map)) as Map);

  test('workspace records and nested brief survive JSON storage with value equality', () {
    for (final affidavit in seed.affidavits) {
      final copy = Affidavit.fromMap(jsonRoundTrip(affidavit.toMap()));
      expect(copy, affidavit);
      expect(copy.hashCode, affidavit.hashCode);
    }
    for (final stipulation in seed.stipulations) {
      final copy = Stipulation.fromMap(jsonRoundTrip(stipulation.toMap()));
      expect(copy, stipulation);
      expect(copy.hashCode, stipulation.hashCode);
    }
    for (final rule in seed.timingRules) {
      final copy = TimingRule.fromMap(jsonRoundTrip(rule.toMap()));
      expect(copy, rule);
      expect(copy.hashCode, rule.hashCode);
    }
    final brief = seed.caseBrief;
    final copy = CaseBrief.fromMap(jsonRoundTrip(brief.toMap()));
    expect(copy, brief);
    expect(copy.hashCode, brief.hashCode);
  });

  test('copyWith preserves identity and unmodified fields', () {
    final affidavit = seed.affidavits.first;
    expect(affidavit.copyWith(body: 'Edited').body, 'Edited');
    expect(affidavit.copyWith(body: 'Edited').witnessId, affidavit.witnessId);
    expect(seed.stipulations.first.copyWith(number: 7).number, 7);
    expect(seed.timingRules.first.copyWith(minutes: 6).minutes, 6);
    expect(
      seed.timingRules[1]
          .copyWith(sharedAcrossWitnesses: false)
          .sharedAcrossWitnesses,
      isFalse,
    );
    final brief = seed.caseBrief;
    final fact = brief.facts.first;
    final link = fact.evidence.first;
    final argument = brief.arguments.first;
    expect(link.copyWith(note: 'Changed').sourceId, link.sourceId);
    expect(fact.copyWith(text: 'Changed').evidence, fact.evidence);
    expect(argument.copyWith(side: TrialSide.defense).side, TrialSide.defense);
    expect(brief.copyWith(arguments: []).facts, brief.facts);
  });

  test('brief takes immutable snapshots of nested input lists', () {
    final links = [...seed.caseBrief.facts.first.evidence];
    final fact = BriefFact(id: 'f', text: 'Fact', evidence: links);
    links.clear();
    expect(fact.evidence, isNotEmpty);
    expect(() => fact.evidence.clear(), throwsUnsupportedError);
    final facts = [fact];
    final arguments = [...seed.caseBrief.arguments];
    final brief = CaseBrief(caseId: 'c', facts: facts, arguments: arguments);
    facts.clear();
    arguments.clear();
    expect(brief.facts, hasLength(1));
    expect(brief.arguments, hasLength(2));
    expect(() => brief.facts.clear(), throwsUnsupportedError);
    expect(() => brief.arguments.clear(), throwsUnsupportedError);
  });
}
