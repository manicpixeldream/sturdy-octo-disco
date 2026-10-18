import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/keys.dart';
import '../../core/widgets/load_failure.dart';
import '../../state/session_controller.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/widgets/workspace_scroll_view.dart';
import '../../core/theme/spacing.dart';
import '../../data/models/case_brief.dart';
import '../../state/case_controller.dart';
import 'widgets/affidavits_section.dart';
import 'widgets/case_brief_section.dart';
import 'widgets/case_header_card.dart';
import 'widgets/evidence_dialog.dart';
import 'widgets/exhibits_section.dart';
import 'widgets/overview_section.dart';
import 'widgets/rules_section.dart';
import 'widgets/section_chips.dart';
import 'widgets/stipulations_section.dart';

class CasePage extends StatefulWidget {
  const CasePage({super.key, this.section, this.factId});
  final String? section;
  final String? factId;

  @override
  State<CasePage> createState() => _CasePageState();
}

class _CasePageState extends State<CasePage> {
  CaseSection _section = CaseSection.overview;
  final Map<String, GlobalKey> _factKeys = {};
  String? _focusedFact;

  @override
  void initState() {
    super.initState();
    _section =
        CaseSection.values.where((s) => s.name == widget.section).firstOrNull ??
        CaseSection.overview;
  }

  @override
  void didUpdateWidget(CasePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section != oldWidget.section ||
        widget.factId != oldWidget.factId) {
      _section =
          CaseSection.values
              .where((s) => s.name == widget.section)
              .firstOrNull ??
          _section;
      _focusedFact = null;
    }
  }

  String? _sourceLabel(CaseController controller, EvidenceLink link) =>
      switch (link.kind) {
        EvidenceKind.exhibit => switch (controller.exhibitById(link.sourceId)) {
          final exhibit? => '${exhibit.label} · ${exhibit.title}',
          null => null,
        },
        EvidenceKind.affidavit => switch (controller.affidavitById(
          link.sourceId,
        )) {
          final affidavit? => 'Affidavit · ${affidavit.title}',
          null => null,
        },
      };

  void _openEvidence(CaseController controller, EvidenceLink link) {
    if (link.kind == EvidenceKind.affidavit) {
      context.push(Routes.affidavit(link.sourceId));
      return;
    }
    final title = _sourceLabel(controller, link);
    if (title == null) return;
    final body = switch (link.kind) {
      EvidenceKind.exhibit =>
        controller.exhibitById(link.sourceId)!.description,
      EvidenceKind.affidavit => controller.affidavitById(link.sourceId)!.body,
    };
    showDialog<void>(
      context: context,
      builder: (_) => EvidenceDialog(title: title, body: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SessionController>();
    final controller = context.watch<CaseController>();
    final caseFile = controller.activeCase;
    for (final fact in controller.brief?.facts ?? []) {
      _factKeys.putIfAbsent(fact.id, () => GlobalKey());
    }
    final target = widget.factId;
    if (_section == CaseSection.brief &&
        target != null &&
        _focusedFact != target &&
        !controller.isBriefLoading &&
        (controller.brief?.facts.any((fact) => fact.id == target) ?? false)) {
      _focusedFact = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetContext = _factKeys[target]?.currentContext;
        if (mounted && targetContext != null) {
          Scrollable.ensureVisible(targetContext, alignment: 0.1);
        }
      });
    }
    return WorkspacePage(
      title: 'Case file',
      child: controller.loadFailed
          ? Center(
              child: LoadFailure(
                title: 'Could not load the case',
                onRetry: controller.load,
              ),
            )
          : caseFile == null
          ? const Center(
              child: CircularProgressIndicator(key: ValueKey('case_loading')),
            )
          : WorkspaceScrollView(
              storageKey: const PageStorageKey('case_scroll'),
              children: [
                CaseHeaderCard(
                  key: GavelKeys.caseHeader,
                  caseFile: caseFile,
                  daysUntilTrial: controller.daysUntilTrial,
                  exhibitCount: controller.exhibits.length,
                  witnessCount: controller.witnesses.length,
                  affidavitCount: controller.affidavits.length,
                ),
                const SizedBox(height: Spacing.sm),
                SectionChips(
                  selected: _section,
                  onSelected: (section) => setState(() => _section = section),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Demo case materials · schedule resets each launch',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.lg),
                KeyedSubtree(
                  key: GavelKeys.caseContent,
                  child: switch (_section) {
                    CaseSection.overview => OverviewSection(
                      caseFile: caseFile,
                      witnesses: controller.witnesses,
                    ),
                    CaseSection.brief => CaseBriefSection(
                      brief: controller.brief,
                      factKeys: _factKeys,
                      isLoading: controller.isBriefLoading,
                      failed: controller.briefFailed,
                      onRetry: controller.loadBrief,
                      sourceLabel: (link) => _sourceLabel(controller, link),
                      onOpenEvidence: (link) => _openEvidence(controller, link),
                    ),
                    CaseSection.affidavits => AffidavitsSection(
                      affidavits: controller.affidavits,
                      witnessById: controller.witnessById,
                      onOpen: (affidavit) =>
                          context.push(Routes.affidavit(affidavit.id)),
                    ),
                    CaseSection.exhibits => ExhibitsSection(
                      exhibits: controller.exhibits,
                    ),
                    CaseSection.stipulations => StipulationsSection(
                      stipulations: controller.stipulations,
                    ),
                    CaseSection.rules => RulesSection(
                      rules: controller.timingRules,
                    ),
                  },
                ),
              ],
            ),
    );
  }
}
