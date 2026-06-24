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
  State<_CourtlyModerationSheet> createState() => _CourtlyModerationSheetState();
}

class _CourtlyModerationSheetState extends State<_CourtlyModerationSheet> {
  String _reason = _reasons.first;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomPadding == 0 ? 12 : bottomPadding),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 390),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: const BoxDecoration(
          color: Color(0xFF1A004D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 28,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: _sheetTextStyle(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_shield_fill,
                    color: Color(0xFFFF2DD2),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _sheetTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Choose a report reason',
                style: _sheetTextStyle(
                  color: CupertinoColors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in _reasons)
                    _ReasonChip(
                      label: reason,
                      selected: _reason == reason,
                      onPressed: () => setState(() => _reason = reason),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _SheetPrimaryButton(
                label: 'Report',
                busy: _submitting,
                onPressed: _report,
              ),
              if (widget.allowBlock) ...[
                const SizedBox(height: 10),
                _SheetSecondaryButton(label: 'Block user', onPressed: _block),
              ],
            ],
          ),
        ),
      ),
    );
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
          border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.16)),
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
          border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.14)),
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
                style: _sheetTextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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

