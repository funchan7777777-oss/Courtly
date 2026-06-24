import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RallyPolicyWebViewPage extends StatefulWidget {
  const RallyPolicyWebViewPage({
    required this.title,
    required this.policyUri,
    super.key,
  });

  final String title;
  final Uri policyUri;

  @override
  State<RallyPolicyWebViewPage> createState() => _RallyPolicyWebViewPageState();
}

class _RallyPolicyWebViewPageState extends State<RallyPolicyWebViewPage> {
  late final WebViewController _controller;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
        ),
      )
      ..loadRequest(widget.policyUri);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: RallyBackdropLayer(
        backdropPath: RallyBackdrop.profileForm,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              top: courtlySafeTop(context, 58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: courtlySafeTop(context, 8),
              child: CupertinoButton(
                minimumSize: Size.zero,
                padding: const EdgeInsets.all(8),
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: CupertinoColors.white,
                  size: 22,
                ),
              ),
            ),
            Positioned(
              top: courtlySafeTop(context, 18),
              left: 58,
              right: 58,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            if (_progress < 100)
              Positioned(
                left: 24,
                right: 24,
                top: courtlySafeTop(context, 54),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 3,
                    child: ColoredBox(
                      color: CupertinoColors.white.withValues(alpha: 0.18),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (_progress / 100)
                            .clamp(0.04, 1)
                            .toDouble(),
                        child: const ColoredBox(color: Color(0xFFFFB733)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
