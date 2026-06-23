/// Custom Ivra icons for bottle and refill operations.
///
/// Generated from FlutterIcon.com using custom SVG designs.
/// Font file: assets/fonts/MyFlutterApp.ttf
import 'package:flutter/widgets.dart';

/// Custom icon set for Ivra Refill app.
///
/// Icon naming convention:
/// - `fullBottleWithPump`    – A full bottle fitted with a pump dispenser
/// - `emptyBottleWithPump`   – An empty bottle fitted with a pump dispenser
/// - `fullBottleWithoutPump` – A full bottle without a pump (cap only)
/// - `emptyBottleWithoutPump`– An empty bottle without a pump (cap only)
/// - `fullRefillBottle`      – A full refill bottle (bouteille de recharge)
/// - `emptyRefillBottle`     – An empty refill bottle
/// - `refillAction`          – Icon representing the refill action
/// - `replaceAction`         – Icon representing the replace-bottle action
/// - `bottleVolume`          – Icon representing bottle volume/capacity
/// - `refillBottleVolume`    – Icon representing refill-bottle volume/capacity
class IvraIcons {
  IvraIcons._();

  static const _kFontFam = 'MyFlutterApp';
  static const String? _kFontPkg = null;

  /// Full bottle with pump (bouteilles avec pompe pleine)
  static const IconData fullBottleWithPump =
      IconData(0xe808, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Empty bottle with pump (bouteilles avec pompe vide)
  static const IconData emptyBottleWithPump =
      IconData(0xe805, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Full bottle without pump (bouteilles sans pompe pleine)
  static const IconData fullBottleWithoutPump =
      IconData(0xe807, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Empty bottle without pump (bouteilles sans pompe vide)
  static const IconData emptyBottleWithoutPump =
      IconData(0xe804, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Full refill bottle (bouteilles de recharge pleines)
  static const IconData fullRefillBottle =
      IconData(0xe806, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Empty refill bottle (bouteilles de recharge vide)
  static const IconData emptyRefillBottle =
      IconData(0xe803, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Refill action (recharger bouteilles)
  static const IconData refillAction =
      IconData(0xe802, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Replace bottle action (remplacer la bouteille)
  static const IconData replaceAction =
      IconData(0xe801, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Bottle volume indicator (volume de la bouteille)
  static const IconData bottleVolume =
      IconData(0xe800, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  /// Refill bottle volume indicator (volume de la bouteille de recharge)
  static const IconData refillBottleVolume =
      IconData(0xe809, fontFamily: _kFontFam, fontPackage: _kFontPkg);
}
