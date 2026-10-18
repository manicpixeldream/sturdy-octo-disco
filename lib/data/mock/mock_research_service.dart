import '../models/case_brief.dart';
import '../models/research_message.dart';
import '../models/research_source.dart';
import '../repositories/case_repository.dart';
import '../services/research_service.dart';

/// Prepared, source-linked training responses. No network calls or live LLM.
class MockResearchService implements ResearchService {
  const MockResearchService({
    required this.caseRepository,
    this.delay = const Duration(milliseconds: 250),
  });
  final CaseRepository caseRepository;
  final Duration delay;

  static const referenceSources = [
    ResearchSource(
      id: 'source_daubert',
      title: 'Daubert v. Merrell Dow Pharmaceuticals',
      kind: ResearchSourceKind.precedent,
      citation: '509 U.S. 579, 589–595 (1993)',
      content: 'The Supreme Court described a federal trial judge’s role in assessing the reliability and relevance of scientific expert testimony. The opinion discusses testing, peer review, error rates, standards, and acceptance as considerations in a flexible inquiry focused on methodology.',
      context: 'Federal precedent · historical opinion summary. Not a ruling in State v. Harmon; check current rules and competition requirements.',
      url: 'https://www.govinfo.gov/content/pkg/USREPORTS-509/pdf/USREPORTS-509-579.pdf',
    ),
    ResearchSource(
      id: 'source_relevance',
      title: 'Relevance',
      kind: ResearchSourceKind.definition,
      citation: 'Federal Rule of Evidence 401 · December 1, 2024 compilation',
      content: 'Under Rule 401, evidence is relevant when it tends to make a fact more or less probable and that fact matters to deciding the action. Relevance alone does not establish that evidence is admissible under every other applicable rule.',
      context: 'Federal evidence rule · training definition, not an assumed rule of this fictional state case. Verify your competition’s rulebook.',
      url: 'https://www.uscourts.gov/sites/default/files/2025-02/federal-rules-of-evidence-dec-1-2024_0.pdf',
    ),
    ResearchSource(
      id: 'source_eyewitness',
      title: 'Making eyewitness identification more reliable',
      kind: ResearchSourceKind.article,
      citation:
          'Beth Schuster, National Institute of Justice · October 1, 2007',
      content: 'This NIJ article discusses eyewitness identification procedures and research on lineup reliability. It describes issues surrounding sequential and simultaneous lineups and double-blind administration. It is background reading about procedures, not evidence that an identification occurred in the Harmon case.',
      context: 'Archived research article · historical background, not a legal holding or case-packet fact.',
      url: 'https://nij.ojp.gov/topics/articles/police-lineups-making-eyewitness-identification-more-reliable',
    ),
  ];

  @override
  Future<List<ResearchSource>> fetchSources(String caseId) async {
    final (exhibits, affidavits) = await (
      caseRepository.fetchExhibits(caseId),
      caseRepository.fetchAffidavits(caseId),
    ).wait;
    return List.unmodifiable([
      ...referenceSources,
      for (final exhibit in exhibits.where((e) => e.caseId == caseId))
        ResearchSource(
          id: exhibit.id,
          title: exhibit.title,
          kind: ResearchSourceKind.caseMaterial,
          citation: '${exhibit.label} · Sample case packet',
          content: exhibit.description,
          context: 'Fictional demo exhibit description. No original document or image is attached.',
          caseId: caseId,
          evidenceKind: EvidenceKind.exhibit,
        ),
      for (final affidavit in affidavits.where((a) => a.caseId == caseId))
        ResearchSource(
          id: affidavit.id,
          title: '${affidavit.title} affidavit',
          kind: ResearchSourceKind.caseMaterial,
          citation: 'Affidavit · ${affidavit.title}',
          content: affidavit.body,
          context: 'Fictional demo witness statement, reproduced from the case packet.',
          caseId: caseId,
          evidenceKind: EvidenceKind.affidavit,
        ),
    ]);
  }

  @override
  Future<ResearchReply> ask({
    required String caseId,
    required String question,
    required List<ResearchMessage> history,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final sources = await fetchSources(caseId);
    final ids = sources.map((s) => s.id).toSet();
    final text = question.toLowerCase();
    bool has(String pattern) =>
        RegExp(pattern, caseSensitive: false).hasMatch(text);
    ResearchAnswerPoint point(String text, List<String> sourceIds) =>
        ResearchAnswerPoint(text: text, sourceIds: sourceIds);
    if (caseId != 'case_harmon' ||
        !ids.containsAll([
          'aff_okafor',
          'ex_4',
          'ex_6',
          'ex_8',
          'ex_9',
          'aff_ortiz',
          'aff_menon',
        ])) {
      return ResearchReply(
        title: 'Start with the available sources',
        points: [
          point(
            'This demo has no prepared case analysis for that packet. The relevance definition is available as a federal-law training reference; verify your own competition rules before applying it.',
            ['source_relevance'],
          ),
        ],
      );
    }
    if (has(r'\b(timeline|911|call|facts|brief|summary|time)\b')) {
      return ResearchReply(
        title: 'Build the timeline from the packet',
        points: [
          point(
            'The 911 transcript records Mara Okafor’s call at 11:42 p.m. Her affidavit explains that she noticed smoke and made the call.',
            ['ex_4', 'aff_okafor'],
          ),
          point(
            'The camera description places a figure near the alley at 11:31 p.m. Treat those times as separate observations, not proof of the exact time the fire began.',
            ['ex_6', 'ex_4'],
          ),
        ],
      );
    }
    if (has(
      r'\b(expert|daubert|scientific|science|marshal|ortiz|menon|fire)\b',
    )) {
      return ResearchReply(
        title: 'Separate the science from identification',
        points: [
          point(
            'Ortiz describes an origin-and-cause investigation; Menon proposes checking the physical evidence and alternative explanations. Neither statement, by itself, identifies who started the fire.',
            ['aff_ortiz', 'aff_menon'],
          ),
          point(
            'For a federal-law practice comparison, Daubert discusses reliability and relevance of scientific expert testimony. This does not establish which rule governs your mock trial.',
            ['source_daubert'],
          ),
        ],
      );
    }
    if (has(
      r'\b(witness|eyewitness|identity|identify|identification|okafor|alley|camera)\b',
    )) {
      return ResearchReply(
        title: 'Keep the identification limits visible',
        points: [
          point(
            'Okafor says she could not identify the alley figure. Compare that limitation with the security still rather than treating the figure as a named person.',
            ['aff_okafor', 'ex_6'],
          ),
          point(
            'The archived NIJ article offers background on identification procedures. It is not proof that a lineup or identification took place in this packet.',
            ['source_eyewitness'],
          ),
        ],
      );
    }
    if (has(r'\b(relevan\w*|motive|insurance|lease|definition|401)\b')) {
      return ResearchReply(
        title: 'Connect each inference to its source',
        points: [
          point(
            'The insurance policy and lease notice describe business circumstances. A proposed financial motive is an inference; these descriptions do not establish who started the fire.',
            ['ex_8', 'ex_9'],
          ),
          point(
            'Rule 401 is a federal-law training reference for connecting evidence to a consequential fact. Check the competition rulebook before using that framework.',
            ['source_relevance'],
          ),
        ],
      );
    }
    return ResearchReply(
      title: 'Try a prepared research topic',
      points: [
        point(
          'This alpha uses prepared answers, so it cannot research that question freely. Ask about the timeline, identification limits, expert evidence, or relevance. Start by checking what Okafor actually observed.',
          ['aff_okafor'],
        ),
      ],
    );
  }
}
