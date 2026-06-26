enum CourtlyContentSurface {
  moment,
  clip,
  momentReply,
  clipReply,
  chatMessage,
  profile,
}

class CourtlyContentSafetyResult {
  const CourtlyContentSafetyResult._({
    required this.allowed,
    required this.title,
    required this.message,
  });

  const CourtlyContentSafetyResult.allowed()
    : this._(allowed: true, title: '', message: '');

  const CourtlyContentSafetyResult.blocked({
    required String title,
    required String message,
  }) : this._(allowed: false, title: title, message: message);

  final bool allowed;
  final String title;
  final String message;
}

abstract final class CourtlyContentSafety {
  static const supportEmail = 'support@courtly.app';
  static const responseWindow = '24 hours';

  static CourtlyContentSafetyResult validateText(
    String value, {
    required CourtlyContentSurface surface,
  }) {
    final text = value.trim();
    if (text.isEmpty) {
      return const CourtlyContentSafetyResult.allowed();
    }

    final context = _TextScanContext(text);
    for (final rule in _rules) {
      if (rule.matches(context)) {
        return CourtlyContentSafetyResult.blocked(
          title: rule.title,
          message:
              'Please revise this ${surface.label}. Courtly blocks ${rule.guidance} before it can be shared so the community stays focused on safe tennis moments.',
        );
      }
    }

    return const CourtlyContentSafetyResult.allowed();
  }

  static bool isTextAllowed(
    String value, {
    required CourtlyContentSurface surface,
  }) {
    return validateText(value, surface: surface).allowed;
  }

  static const List<_SafetyRule> _rules = [
    _SafetyRule(
      title: 'Mature content blocked',
      guidance: 'mature or exploitative material that does not belong here',
      wordPattern:
          r'\b(porn|porno|xxx|nude|nudes|nudity|onlyfans|escort|prostitut(?:e|ion)|hookup|hook\s*up|erotic|fetish|blowjob|handjob|orgasm|pussy|dick|cock|penis|vagina|boobs|breasts?)\b',
      compactPattern:
          r'(色情|黄色|裸照|裸体|露点|约炮|援交|卖淫|嫖娼|招嫖|性交易|开房|成人影片|黄图|黄站|外围|人贩|人口贩卖)',
    ),
    _SafetyRule(
      title: 'Harassment blocked',
      guidance: 'targeted abuse, degrading attacks, or identity-based insults',
      wordPattern:
          r'\b(kys|kill\s+yourself|go\s+die|slut|whore|bitch|retard|fag|nigger|chink)\b',
      compactPattern: r'(去死|傻逼|煞笔|贱人|婊子|废物|垃圾人|滚蛋|辱骂|霸凌|网暴)',
    ),
    _SafetyRule(
      title: 'Threat blocked',
      guidance: 'threatening, intimidating, or dangerous material',
      wordPattern:
          r'\b(?:i\s*(?:will|ll)|gonna|going\s+to)\s+(?:kill|hurt|beat|stab|shoot)\b|\b(?:kill|stab|shoot|bomb|murder)\s+(?:you|him|her|them)\b|\bgun\s+for\s+sale\b',
      compactPattern: r'(杀了你|弄死你|打死你|砍死|捅死|枪杀|炸死|威胁你|恐吓|危险挑战)',
    ),
    _SafetyRule(
      title: 'Wellbeing safety notice',
      guidance: 'wellbeing risks or harmful instructions',
      wordPattern:
          r'\b(suicide|self[-\s]?harm|cut\s+myself|kill\s+myself|end\s+my\s+life)\b',
      compactPattern: r'(自杀|自残|割腕|轻生|结束生命)',
    ),
    _SafetyRule(
      title: 'Lawful use notice',
      guidance: 'unlawful offers, risky promotions, or fraud solicitation',
      wordPattern:
          r'\b(cocaine|heroin|meth|buy\s+drugs|weed\s+for\s+sale|weapon\s+for\s+sale|scam|phishing|cashapp|venmo|crypto\s+guaranteed|betting\s+tip)\b',
      compactPattern: r'(毒品|冰毒|海洛因|大麻出售|买枪|卖枪|诈骗|钓鱼链接|赌博|博彩|洗钱)',
    ),
    _SafetyRule(
      title: 'Private contact blocked',
      guidance:
          'public contact details, external links, payment handles, or private personal information',
      wordPattern:
          r'https?://|www\.|\b[\w.+-]+@[\w-]+\.[\w.-]+\b|\b(?:\+?\d[\d\s().-]{8,}\d)\b|\b(?:ssn|passport|id\s*card|home\s+address)\b',
      compactPattern: r'(身份证|护照号|家庭住址|开户地址|手机号|微信号|付款码|收款码)',
    ),
  ];
}

extension CourtlyContentSurfaceLabel on CourtlyContentSurface {
  String get label {
    return switch (this) {
      CourtlyContentSurface.moment => 'court moment',
      CourtlyContentSurface.clip => 'practice clip note',
      CourtlyContentSurface.momentReply => 'moment reply',
      CourtlyContentSurface.clipReply => 'clip reply',
      CourtlyContentSurface.chatMessage => 'rally message',
      CourtlyContentSurface.profile => 'player card text',
    };
  }
}

class _TextScanContext {
  _TextScanContext(String text)
    : lower = text.toLowerCase(),
      compact = text.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9\u4e00-\u9fff]+'),
        '',
      );

  final String lower;
  final String compact;
}

class _SafetyRule {
  const _SafetyRule({
    required this.title,
    required this.guidance,
    required this.wordPattern,
    required this.compactPattern,
  });

  final String title;
  final String guidance;
  final String wordPattern;
  final String compactPattern;

  bool matches(_TextScanContext context) {
    return RegExp(wordPattern, caseSensitive: false).hasMatch(context.lower) ||
        RegExp(compactPattern, caseSensitive: false).hasMatch(context.compact);
  }
}
