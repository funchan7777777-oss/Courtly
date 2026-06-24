import 'dart:async';

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
        allowBlock: allowBlock && userId != null,
      );
    },
  );
}

Future<void> showCourtlyReviewDialog(BuildContext context) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return const _CourtlyStatusDialog(
        icon: CupertinoIcons.sparkles,
        title: 'Released for review',
        message:
            'Your court moment was received. It will appear after background review approves it.',
        primaryLabel: 'Got it',
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
  });

  final String targetId;
  final String targetType;
  final String title;
  final String? userId;
  final String? summary;
  final bool allowBlock;

  @override
  State<_CourtlyModerationSheet> createState() =>
      _CourtlyModerationSheetState();
}

class _CourtlyModerationSheetState extends State<_CourtlyModerationSheet> {
  CourtlyModerationAction _selectedAction = CourtlyModerationAction.block;
  String _reason = _reasons.first;
  bool _choosingReason = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 54)
        .clamp(280.0, 336.0)
        .toDouble();

    return Center(
      child: DefaultTextStyle(
        style: _sheetTextStyle(),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFF2A005F),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/Meetup.png',
                  height: 126,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _choosingReason
                        ? _ReportReasonStep(
                            key: const ValueKey<String>('reason'),
                            reason: _reason,
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
                            allowBlock: widget.allowBlock,
                            submitting: _submitting,
                            onChanged: (action) {
                              setState(() => _selectedAction = action);
                            },
                            onConfirm: _confirmAction,
                          ),
                  ),
                ),
              ],
            ),
          ),
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
    await CourtlySocialStore.instance.blockUser(userId);
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
}

class _ModerationActionStep extends StatelessWidget {
  const _ModerationActionStep({
    required this.selectedAction,
    required this.allowBlock,
    required this.submitting,
    required this.onChanged,
    required this.onConfirm,
    super.key,
  });

  final CourtlyModerationAction selectedAction;
  final bool allowBlock;
  final bool submitting;
  final ValueChanged<CourtlyModerationAction> onChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModerationChoiceRow(
          label: 'Report',
          icon: CupertinoIcons.exclamationmark_square_fill,
          selected: selectedAction == CourtlyModerationAction.report,
          onPressed: () => onChanged(CourtlyModerationAction.report),
        ),
        if (allowBlock) ...[
          const SizedBox(height: 18),
          _ModerationChoiceRow(
            label: 'Block',
            icon: CupertinoIcons.exclamationmark_circle_fill,
            selected: selectedAction == CourtlyModerationAction.block,
            onPressed: () => onChanged(CourtlyModerationAction.block),
          ),
        ],
        const SizedBox(height: 28),
        _SheetImageButton(busy: submitting, onPressed: onConfirm),
      ],
    );
  }
}

class _ReportReasonStep extends StatelessWidget {
  const _ReportReasonStep({
    required this.reason,
    required this.submitting,
    required this.onReasonChanged,
    required this.onBack,
    required this.onConfirm,
    super.key,
  });

  final String reason;
  final bool submitting;
  final ValueChanged<String> onReasonChanged;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Report type',
              style: _sheetTextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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
        _SheetImageButton(busy: submitting, onPressed: onConfirm),
      ],
    );
  }
}

class _ModerationChoiceRow extends StatelessWidget {
  const _ModerationChoiceRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 54,
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
  const _SheetImageButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: busy ? null : onPressed,
      child: SizedBox(
        width: 242,
        height: 55,
        child: busy
            ? const Center(
                child: CupertinoActivityIndicator(color: CupertinoColors.white),
              )
            : Image.asset('assets/images/Trophy.png', fit: BoxFit.fill),
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
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.sizeOf(context).width.clamp(0.0, 330.0).toDouble(),
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A004D),
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
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2DD2).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF2DD2)),
                ),
                child: Icon(icon, color: const Color(0xFFFF2DD2), size: 34),
              ),
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
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}
