import '../models/affidavit.dart';
import '../models/case_brief.dart';
import '../models/stipulation.dart';
import '../models/timing_rule.dart';
import '../models/trial_side.dart';

/// Fictional sample material for the alpha, not an imported competition packet.
abstract final class HarmonPacket {
  static const affidavits = [
    Affidavit(
      id: 'aff_reyes',
      caseId: 'case_harmon',
      witnessId: 'wit_reyes',
      title: 'Officer Dana Reyes',
      body:
          'I responded to the Riverside Print Shop after the 11:42 p.m. call '
          'on March 3. I observed damage around the rear service door. '
          'I secured the scene and recorded its layout. I did not see who '
          'started the fire. The scene diagram and rear door photograph '
          'document my observations.',
    ),
    Affidavit(
      id: 'aff_okafor',
      caseId: 'case_harmon',
      witnessId: 'wit_okafor',
      title: 'Mara Okafor',
      body:
          'I live near the Riverside Print Shop. On March 3, I noticed smoke '
          'and called 911 at 11:42 p.m. Earlier I saw a figure near the alley, '
          'but I could not identify the person. My call is recorded in Exhibit 4.',
    ),
    Affidavit(
      id: 'aff_ortiz',
      caseId: 'case_harmon',
      witnessId: 'wit_ortiz',
      title: 'Dr. Lena Ortiz',
      body:
          'I investigated the origin and cause of the print shop fire. '
          'My findings are documented in Exhibit 5. The burn pattern '
          'photographs and stockroom debris analysis are supporting materials. '
          'The origin-and-cause investigation does not identify a person '
          'who started the fire.',
    ),
    Affidavit(
      id: 'aff_harmon',
      caseId: 'case_harmon',
      witnessId: 'wit_harmon',
      title: 'Casey Harmon',
      body:
          'I owned the Riverside Print Shop. I deny setting the March 3 fire. '
          'The shop had an insurance policy renewed in January, and I received '
          'a lease termination letter dated February 10. Those documents '
          'describe the business circumstances; they do not establish who '
          'started the fire.',
    ),
    Affidavit(
      id: 'aff_lindqvist',
      caseId: 'case_harmon',
      witnessId: 'wit_lindqvist',
      title: 'Theo Lindqvist',
      body:
          'I worked at the print shop and am a defense alibi witness. '
          'My timecard for March 3 is Exhibit 12. The timecard records my '
          'work hours; by itself it does not record every movement Casey '
          'Harmon made that night.',
    ),
    Affidavit(
      id: 'aff_menon',
      caseId: 'case_harmon',
      witnessId: 'wit_menon',
      title: 'Dr. Ravi Menon',
      body:
          'I am the defense fire science expert. I reviewed the fire marshal '
          'report, burn pattern photographs, accelerant lab report, and weather '
          'report. I would test whether the physical evidence supports the '
          'proposed cause and consider alternative explanations. A burn pattern '
          'alone does not identify the person responsible.',
    ),
  ];

  static const stipulations = [
    Stipulation(
      id: 'stip_1',
      caseId: 'case_harmon',
      number: 1,
      text: 'The Riverside Print Shop was destroyed by fire on March 3.',
    ),
    Stipulation(
      id: 'stip_2',
      caseId: 'case_harmon',
      number: 2,
      text:
          'The packet exhibits are authentic copies. Authenticity alone does '
          'not resolve relevance, hearsay, or the weight of an exhibit.',
    ),
    Stipulation(
      id: 'stip_3',
      caseId: 'case_harmon',
      number: 3,
      text:
          'Witness testimony is limited to the sample affidavits and '
          'reasonable inferences from the sample case materials.',
    ),
  ];

  static const timingRules = [
    TimingRule(
      id: 'time_opening',
      caseId: 'case_harmon',
      phase: TrialPhase.opening,
      minutes: 5,
    ),
    TimingRule(
      id: 'time_direct',
      caseId: 'case_harmon',
      phase: TrialPhase.direct,
      minutes: 25,
      sharedAcrossWitnesses: true,
    ),
    TimingRule(
      id: 'time_cross',
      caseId: 'case_harmon',
      phase: TrialPhase.cross,
      minutes: 20,
      sharedAcrossWitnesses: true,
    ),
    TimingRule(
      id: 'time_closing',
      caseId: 'case_harmon',
      phase: TrialPhase.closing,
      minutes: 9,
    ),
  ];

  static CaseBrief get brief => CaseBrief(
    caseId: 'case_harmon',
    facts: [
      BriefFact(
        id: 'fact_call',
        text:
            'Mara Okafor called 911 at 11:42 p.m. '
            'after noticing smoke at the print shop.',
        evidence: const [
          EvidenceLink(
            kind: EvidenceKind.exhibit,
            sourceId: 'ex_4',
            note: 'The call transcript records the caller and time.',
          ),
          EvidenceLink(
            kind: EvidenceKind.affidavit,
            sourceId: 'aff_okafor',
            note: 'Okafor describes noticing smoke and making the call.',
          ),
        ],
      ),
      BriefFact(
        id: 'fact_door',
        text:
            'The rear service door showed damage; '
            'Officer Reyes did not witness the fire being started.',
        evidence: const [
          EvidenceLink(
            kind: EvidenceKind.exhibit,
            sourceId: 'ex_2',
            note: 'The rear door photograph documents pry marks.',
          ),
          EvidenceLink(
            kind: EvidenceKind.affidavit,
            sourceId: 'aff_reyes',
            note: 'Reyes describes the damaged door and the limits of the observation.',
          ),
        ],
      ),
      BriefFact(
        id: 'fact_identity',
        text:
            'A figure was near the alley, '
            'but Okafor could not identify that person.',
        evidence: const [
          EvidenceLink(
            kind: EvidenceKind.exhibit,
            sourceId: 'ex_6',
            note: 'The camera still places a figure near the alley at 11:31 p.m.; it does not name the person.',
          ),
          EvidenceLink(
            kind: EvidenceKind.affidavit,
            sourceId: 'aff_okafor',
            note: 'Okafor explicitly limits the identification.',
          ),
        ],
      ),
      BriefFact(
        id: 'fact_business',
        text:
            'The shop had insurance renewed '
            'in January and a lease termination notice dated February 10.',
        evidence: const [
          EvidenceLink(
            kind: EvidenceKind.exhibit,
            sourceId: 'ex_8',
            note: 'The policy documents the insurance coverage.',
          ),
          EvidenceLink(
            kind: EvidenceKind.exhibit,
            sourceId: 'ex_9',
            note: 'The landlord notice documents the lease termination.',
          ),
        ],
      ),
    ],
    arguments: const [
      BriefArgument(
        id: 'argument_motive',
        side: TrialSide.prosecution,
        argument:
            'The insurance and lease circumstances suggest a financial motive.',
        counter: 'Defense: distinguish a possible motive from proof that Harmon started the fire.',
      ),
      BriefArgument(
        id: 'argument_identity',
        side: TrialSide.defense,
        argument: 'The unidentified alley figure leaves a gap in the identification evidence.',
        counter: 'Prosecution: compare the camera timeline with the other evidence; do not claim the still identifies Harmon.',
      ),
    ],
  );
}
