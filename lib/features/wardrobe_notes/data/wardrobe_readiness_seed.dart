import 'package:courtly/features/wardrobe_notes/domain/wardrobe_readiness.dart';

abstract final class WardrobeReadinessSeed {
  static const List<WardrobeReadiness> eveningSignals = [
    WardrobeReadiness(
      readinessName: 'Gallery dinner standard',
      inspectionFocus: 'Sharp lapel line and clean sleeve break',
      fabricCue: 'Wool blend, low sheen, holds shape indoors',
      accessoryAnchor: 'Brushed gold pin or dark silk pocket square',
      weatherTact: 'Light overcoat; no umbrella handoff expected',
      quietRisk: 'Glossy shoes may read too ceremonial for the room.',
      completionRatio: 0.78,
      readinessFlags: ['Pressed', 'Accent pending', 'Coat staged'],
    ),
    WardrobeReadiness(
      readinessName: 'Host greeting fallback',
      inspectionFocus: 'Comfortable standing fit through shoulders',
      fabricCue: 'Textured jacket with clean black base',
      accessoryAnchor: 'Minimal watch, no bright contrast tie',
      weatherTact: 'Works for terrace photos if temperature drops',
      quietRisk: 'Check cuff length before leaving.',
      completionRatio: 0.64,
      readinessFlags: ['Flexible', 'Weather aware', 'Needs cuff check'],
    ),
    WardrobeReadiness(
      readinessName: 'Late evening reset',
      inspectionFocus: 'Simple layer that still photographs well',
      fabricCue: 'Soft navy knit under structured outer layer',
      accessoryAnchor: 'Matte collar detail, no lapel ornament',
      weatherTact: 'Suited for departure line and car-side greetings',
      quietRisk: 'Too casual if used before dinner service.',
      completionRatio: 0.56,
      readinessFlags: ['After dinner', 'Low contrast', 'Reserved'],
    ),
  ];
}
