import 'package:flutter/cupertino.dart';

class RallyGlassActionButton extends StatelessWidget {
  const RallyGlassActionButton({
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    this.isEmphasized = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final buttonWidth = (screenWidth * 0.74).clamp(250.0, 310.0).toDouble();

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: isBusy ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: buttonWidth,
        height: 58,
        decoration: BoxDecoration(
          color: isEmphasized
              ? CupertinoColors.white
              : const Color(0xFF5A3291).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isBusy
            ? const CupertinoActivityIndicator(radius: 11)
            : Text(
                label,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: isEmphasized
                      ? const Color(0xFF2F2B36)
                      : CupertinoColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }
}
