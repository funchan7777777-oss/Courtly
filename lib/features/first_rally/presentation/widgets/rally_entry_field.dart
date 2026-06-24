import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:flutter/cupertino.dart';

class RallyEntryField extends StatefulWidget {
  const RallyEntryField({
    required this.placeholder,
    required this.controller,
    this.keyboardType,
    this.isPrivatePhrase = false,
    this.maxLines = 1,
    super.key,
  });

  final String placeholder;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool isPrivatePhrase;
  final int maxLines;

  @override
  State<RallyEntryField> createState() => _RallyEntryFieldState();
}

class _RallyEntryFieldState extends State<RallyEntryField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.isPrivatePhrase;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6C42A0).withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(widget.maxLines > 1 ? 18 : 28),
      ),
      child: CupertinoTextField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: isPassword && _obscured,
        maxLines: widget.maxLines,
        minLines: widget.maxLines,
        cursorColor: CupertinoColors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: widget.maxLines > 1 ? 16 : 13,
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(
            isPassword ? CupertinoIcons.lock_fill : CupertinoIcons.person_fill,
            size: 16,
            color: CupertinoColors.white.withValues(alpha: 0.52),
          ),
        ),
        suffix: isPassword
            ? CupertinoButton(
                minSize: 0,
                padding: const EdgeInsets.only(right: 14),
                onPressed: () {
                  setState(() => _obscured = !_obscured);
                },
                child: Image.asset(
                  _obscured
                      ? RallyAssetLedger.hiddenServeGlyph
                      : RallyAssetLedger.visibleServeGlyph,
                  width: 20,
                  height: 20,
                ),
              )
            : null,
        placeholder: widget.placeholder,
        placeholderStyle: TextStyle(
          color: CupertinoColors.white.withValues(alpha: 0.42),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        decoration: const BoxDecoration(),
      ),
    );
  }
}
