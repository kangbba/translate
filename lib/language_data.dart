
import 'package:flutter/material.dart';
class LanguageData {

  String? _languageName;
  String? _languageCode;
  String? _speechLocaleId;
  int? _arduinoUniqueId;
  AssetImage? _img;

  String get languageName => _languageName!;
  String get languageCode => _languageCode!;
  String get speechLocaleId => _speechLocaleId!;
  int get arduinoUniqueId => _arduinoUniqueId!;
  AssetImage get img => _img!;

  LanguageData(String? languageName, String? languageCode, String? speechLocaleId, int? arduinoUniqueId, AssetImage? img)
  {
    _languageName = languageName;
    _languageCode = languageCode;
    _speechLocaleId = speechLocaleId;
    _arduinoUniqueId = arduinoUniqueId;
    _img = img;
  }
}
