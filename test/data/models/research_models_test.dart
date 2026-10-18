import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_research_service.dart';
import 'package:gavel/data/models/citation.dart';
import 'package:gavel/data/models/research_message.dart';
import 'package:gavel/data/models/research_source.dart';

void main() {
  Map<String, Object?> jsonMap(Map<String, Object?> map) =>
      Map<String, Object?>.from(jsonDecode(jsonEncode(map)) as Map);
  test('research sources, messages, nested points, and citations survive JSON round trips', () {
    for (final source in MockResearchService.referenceSources) {
      final copy = ResearchSource.fromMap(jsonMap(source.toMap()));
      expect(copy, source);
      expect(copy.hashCode, source.hashCode);
      expect(source.copyWith(content: 'New excerpt').id, source.id);
    }
    final point = ResearchAnswerPoint(
      text: 'Evidence claim',
      sourceIds: ['ex_4'],
    );
    final message = ResearchMessage(
      id: 'm1',
      role: ResearchRole.assistant,
      text: 'Response',
      points: [point],
    );
    final copy = ResearchMessage.fromMap(jsonMap(message.toMap()));
    expect(copy, message);
    expect(copy.hashCode, message.hashCode);
    expect(copy.copyWith(text: 'New heading').points, message.points);
    final reply = ResearchReply(title: 'Answer', points: [point]);
    expect(ResearchReply.fromMap(jsonMap(reply.toMap())), reply);
    expect(reply.copyWith(title: 'Updated').points, reply.points);
    const citation = Citation(
      sourceId: 'ex_4',
      location: CitationLocation.caseBrief,
      referenceId: 'fact_call',
      label: 'Call time',
    );
    expect(Citation.fromMap(jsonMap(citation.toMap())), citation);
    expect(citation.copyWith(label: 'New label').id, citation.id);
    expect(() => copy.points.clear(), throwsUnsupportedError);
    expect(() => copy.points.first.sourceIds.clear(), throwsUnsupportedError);
  });
}
