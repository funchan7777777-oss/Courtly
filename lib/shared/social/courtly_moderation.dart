import 'dart:async';

import 'package:courtly/atelier/theme/courtly_font_families.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:flutter/cupertino.dart';

enum CourtlyModerationAction { report, block }

class CourtlyModerationResult {
  const CourtlyModerationResult({
    required this.action,
    required this.targetId,
    this.userId,
  });

  final CourtlyModerationAction action;
  final String targetId;
  final String? userId;
}

Future<CourtlyModerationResult?> showCourtlyModerationSheet({
  required BuildContext context,
  required String targetId,
  required String targetType,
  required String title,
  String? userId,
  String? summary,
  String? avatarAsset,
  bool allowBlock = true,
}) async {
  return showCupertinoModalPopup<CourtlyModerationResult>(
    context: context,
    barrierColor: CupertinoColors.black.withValues(alpha: 0.54),
    builder: (_) {
      return _CourtlyModerationSheet(
        targetId: targetId,
        targetType: targetType,
        title: title,
        userId: userId,
        summary: summary,
        avatarAsset: avatarAsset,
        allowBlock: allowBlock && userId != null,
      );
    },
  );
}

Future<void> showCourtlyReviewDialog(
  BuildContext context, {
  String contentLabel = 'court moment',
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _CourtlyStatusDialog(
        icon: CupertinoIcons.shield_lefthalf_fill,
        eyebrow: 'Courtly review',
        title: 'Submitted for review',
        message:
            'Your $contentLabel is hidden while the review team checks it. Once approved, it will appear in the feed automatically.',
        badges: const ['Hidden now', 'Appears after approval'],
        primaryLabel: 'I understand',
      );
    },
  );
}

Future<void> showCourtlyActionSuccess({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return _CourtlyStatusDialog(
        icon: CupertinoIcons.check_mark_circled_solid,
        title: title,
        message: message,
        primaryLabel: 'Done',
      );
    },
  );
}

Future<void> showCourtlyAccessDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return _CourtlyStatusDialog(
        icon: CupertinoIcons.lock_shield_fill,
        title: title,
        message: message,
        primaryLabel: 'OK',
      );
    },
  );
}

class _CourtlyModerationSheet extends StatefulWidget {
  const _CourtlyModerationSheet({
    required this.targetId,
    required this.targetType,
    required this.title,
    required this.allowBlock,
    this.userId,
    this.summary,
    this.avatarAsset,
  });

  final String targetId;
  final String targetType;
  final String title;
  final String? userId;
  final String? summary;
  final String? avatarAsset;
  final bool allowBlock;

  @override
  State<_CourtlyModerationSheet> createState() =>
      _CourtlyModerationSheetState();
}

class _CourtlyModerationSheetState extends State<_CourtlyModerationSheet> {
  late CourtlyModerationAction _selectedAction;
  String _reason = _reasons.first;
  bool _choosingReason = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAction = widget.allowBlock
        ? CourtlyModerationAction.block
        : CourtlyModerationAction.report;
  }

  @override
  Widget build(BuildContext context) {
    final sheetWidth = (MediaQuery.sizeOf(context).width - 54)
        .clamp(280.0, 378.0)
        .toDouble();
    final sheetHeight = sheetWidth / _artworkAspectRatio;
    final horizontalInset = (sheetWidth * 0.07).clamp(20.0, 28.0).toDouble();
    final topInset = (sheetHeight * 0.34).clamp(118.0, 162.0).toDouble();
    final bottomInset = (sheetWidth * 0.075).clamp(22.0, 30.0).toDouble();

    return Center(
      child: DefaultTextStyle(
        style: _sheetTextStyle(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: sheetWidth,
              height: sheetHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x77000000),
                    blurRadius: 30,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/Meetup.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalInset,
                          topInset,
                          horizontalInset,
                          bottomInset,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _choosingReason
                                ? _ReportReasonStep(
                                    key: const ValueKey<String>('reason'),
                                    reason: _reason,
                                    sheetWidth: sheetWidth,
                                    submitting: _submitting,
                                    onReasonChanged: (reason) {
                                      setState(() => _reason = reason);
                                    },
                                    onBack: () {
                                      setState(() => _choosingReason = false);
                                    },
                                    onConfirm: _report,
                                  )
                                : _ModerationActionStep(
                                    key: const ValueKey<String>('action'),
                                    selectedAction: _selectedAction,
                                    sheetWidth: sheetWidth,
                                    allowBlock: widget.allowBlock,
                                    submitting: _submitting,
                                    onChanged: (action) {
                                      setState(() => _selectedAction = action);
                                    },
                                    onConfirm: _confirmAction,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _ModerationDismissButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction() {
    if (_selectedAction == CourtlyModerationAction.report) {
      setState(() => _choosingReason = true);
      return;
    }
    unawaited(_block());
  }

  Future<void> _report() async {
    setState(() => _submitting = true);
    await CourtlySocialStore.instance.reportContent(
      contentId: widget.targetId,
      type: widget.targetType,
      reason: _reason,
      userId: widget.userId,
      summary: widget.summary,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(
      CourtlyModerationResult(
        action: CourtlyModerationAction.report,
        targetId: widget.targetId,
        userId: widget.userId,
      ),
    );
  }

  Future<void> _block() async {
    final userId = widget.userId;
    if (userId == null) {
      return;
    }
    setState(() => _submitting = true);
    await CourtlySocialStore.instance.blockUser(
      userId,
      name: widget.title,
      avatarAsset: widget.avatarAsset,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(
      CourtlyModerationResult(
        action: CourtlyModerationAction.block,
        targetId: widget.targetId,
        userId: userId,
      ),
    );
  }

  static const List<String> _reasons = [
    'Harassment',
    'Spam',
    'Unsafe content',
    'Impersonation',
    'Other',
  ];
  static const double _artworkAspectRatio = 594 / 746;
}

class _ModerationActionStep extends StatelessWidget {
  const _ModerationActionStep({
    required this.selectedAction,
    required this.sheetWidth,
    required this.allowBlock,
    required this.submitting,
    required this.onChanged,
    required this.onConfirm,
    super.key,
  });

  final CourtlyModerationAction selectedAction;
  final double sheetWidth;
  final bool allowBlock;
  final bool submitting;
  final ValueChanged<CourtlyModerationAction> onChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final rowHeight = (sheetWidth * 0.18).clamp(50.0, 68.0).toDouble();
    final rowGap = (sheetWidth * 0.06).clamp(16.0, 24.0).toDouble();
    final buttonGap = (sheetWidth * 0.08).clamp(24.0, 31.0).toDouble();
    final buttonWidth = (sheetWidth * 0.73).clamp(214.0, 276.0).toDouble();

    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModerationChoiceRow(
          label: 'Report',
          icon: CupertinoIcons.exclamationmark_square_fill,
          height: rowHeight,
          selected: selectedAction == CourtlyModerationAction.report,
          onPressed: () => onChanged(CourtlyModerationAction.report),
        ),
        if (allowBlock) ...[
          SizedBox(height: rowGap),
          _ModerationChoiceRow(
            label: 'Block',
            icon: CupertinoIcons.exclamationmark_circle_fill,
            height: rowHeight,
            selected: selectedAction == CourtlyModerationAction.block,
            onPressed: () => onChanged(CourtlyModerationAction.block),
          ),
        ],
        SizedBox(height: buttonGap),
        _SheetImageButton(
          width: buttonWidth,
          busy: submitting,
          onPressed: onConfirm,
        ),
      ],
    );
  }
}

class _ReportReasonStep extends StatelessWidget {
  const _ReportReasonStep({
    required this.reason,
    required this.sheetWidth,
    required this.submitting,
    required this.onReasonChanged,
    required this.onBack,
    required this.onConfirm,
    super.key,
  });

  final String reason;
  final double sheetWidth;
  final bool submitting;
  final ValueChanged<String> onReasonChanged;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final buttonWidth = (sheetWidth * 0.73).clamp(214.0, 276.0).toDouble();

    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onBack,
              child: const Icon(
                CupertinoIcons.chevron_left,
                color: CupertinoColors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Report type',
                style: _sheetTextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in _CourtlyModerationSheetState._reasons)
              _ReasonChip(
                label: value,
                selected: reason == value,
                onPressed: () => onReasonChanged(value),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: _SheetImageButton(
            width: buttonWidth,
            busy: submitting,
            onPressed: onConfirm,
          ),
        ),
      ],
    );
  }
}

class _ModerationChoiceRow extends StatelessWidget {
  const _ModerationChoiceRow({
    required this.label,
    required this.icon,
    required this.height,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final double height;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF59308B),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(icon, color: CupertinoColors.white, size: 23),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: _sheetTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle_fill,
              color: CupertinoColors.white.withValues(
                alpha: selected ? 1 : 0.1,
              ),
              size: 25,
            ),
            const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}

class _SheetImageButton extends StatelessWidget {
  const _SheetImageButton({
    required this.width,
    required this.busy,
    required this.onPressed,
  });

  final double width;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final height = (width * 98 / 428).clamp(45.0, 63.0).toDouble();

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: busy ? null : onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/Trophy.png', fit: BoxFit.fill),
            ),
            if (busy)
              const CupertinoActivityIndicator(color: CupertinoColors.white),
          ],
        ),
      ),
    );
  }
}

class _ModerationDismissButton extends StatelessWidget {
  const _ModerationDismissButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.xmark,
          color: Color(0xFF45454D),
          size: 20,
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF2DD2)
              : CupertinoColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF92EA)
                : CupertinoColors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          label,
          style: _sheetTextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: busy ? null : onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFF2DD2),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55FF2DD2),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: busy
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(
                  label,
                  style: _sheetTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SheetSecondaryButton extends StatelessWidget {
  const _SheetSecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: _sheetTextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _CourtlyStatusDialog extends StatelessWidget {
  const _CourtlyStatusDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.eyebrow,
    this.badges = const [],
  });

  final IconData icon;
  final String? eyebrow;
  final String title;
  final String message;
  final List<String> badges;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.sizeOf(context).width.clamp(0.0, 330.0).toDouble(),
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B0067), Color(0xFF1A004D), Color(0xFF080015)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.14),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: _sheetTextStyle(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2DD2).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.24),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66FF2DD2),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: const Color(0xFFFF2DD2), size: 34),
              ),
              if (eyebrow != null) ...[
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: CupertinoColors.white.withValues(alpha: 0.13),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      eyebrow!,
                      textAlign: TextAlign.center,
                      style: _sheetTextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: _sheetTextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _sheetTextStyle(
                  color: CupertinoColors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final badge in badges)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF2DD2,
                          ).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFFFF2DD2,
                            ).withValues(alpha: 0.34),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          child: Text(
                            badge,
                            style: _sheetTextStyle(
                              color: CupertinoColors.white,
                              fontSize: 11,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _SheetPrimaryButton(
                label: primaryLabel,
                busy: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _sheetTextStyle({
  Color color = CupertinoColors.white,
  double fontSize = 14,
  double height = 1.1,
  FontWeight fontWeight = FontWeight.w700,
}) {
  return TextStyle(
    color: color,
    fontFamily: CourtlyFontFamilies.ui,
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}
