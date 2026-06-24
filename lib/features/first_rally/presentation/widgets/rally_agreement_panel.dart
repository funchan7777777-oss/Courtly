import 'package:courtly/features/first_rally/data/rally_policy_links.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_policy_webview_page.dart';
import 'package:flutter/cupertino.dart';

class RallyAgreementPanel extends StatelessWidget {
  const RallyAgreementPanel({
    required this.isAccepted,
    required this.onChanged,
    super.key,
  });

  final bool isAccepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final baseStyle = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
      color: CupertinoColors.white.withValues(alpha: 0.78),
      fontSize: 11,
      height: 1.35,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF210A44).withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: () => onChanged(!isAccepted),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 21,
                  height: 21,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? const Color(0xFFFFB733)
                        : CupertinoColors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isAccepted
                          ? const Color(0xFFFFD46E)
                          : CupertinoColors.white.withValues(alpha: 0.36),
                    ),
                  ),
                  child: isAccepted
                      ? const Icon(
                          CupertinoIcons.checkmark,
                          color: Color(0xFF2D0A5A),
                          size: 15,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('I have read and agree to the ', style: baseStyle),
                    _PolicyLink(
                      label: 'Terms of Service',
                      uri: RallyPolicyLinks.serviceTerms,
                    ),
                    Text(' and ', style: baseStyle),
                    _PolicyLink(
                      label: 'Privacy Policy',
                      uri: RallyPolicyLinks.privacyNotice,
                    ),
                    Text(' before entering Courtly.', style: baseStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({required this.label, required this.uri});

  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: () {
        Navigator.of(context).push(
          CupertinoPageRoute<void>(
            builder: (_) =>
                RallyPolicyWebViewPage(title: label, policyUri: uri),
          ),
        );
      },
      child: Text(
        label,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          color: const Color(0xFFFFD46E),
          fontSize: 11,
          height: 1.35,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFFFFD46E),
        ),
      ),
    );
  }
}
