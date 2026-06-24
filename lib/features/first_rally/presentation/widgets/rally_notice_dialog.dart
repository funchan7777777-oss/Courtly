import 'package:flutter/cupertino.dart';

class RallyNoticeDialog extends StatelessWidget {
  const RallyNoticeDialog({
    required this.title,
    required this.message,
    this.actionLabel = 'Got it',
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'Got it',
  }) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (_) => RallyNoticeDialog(
        title: title,
        message: message,
        actionLabel: actionLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF2C0B59),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFB733), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 34,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB733).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.exclamationmark_shield_fill,
                    color: Color(0xFFFFD46E),
                    size: 25,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        decoration: TextDecoration.none,
                      ),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        color: CupertinoColors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                        decoration: TextDecoration.none,
                      ),
                ),
                const SizedBox(height: 18),
                CupertinoButton(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      actionLabel,
                      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            color: const Color(0xFF2C0B59),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            decoration: TextDecoration.none,
                          ),
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
}
