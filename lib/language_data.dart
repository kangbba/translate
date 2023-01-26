
import 'package:flutter/material.dart';
class LanguageData {

  String? _languageName;
  String? _languageCode;
  AssetImage? _img;

  String get languageName => _languageName!;
  String get languageCode => _languageCode!;
  AssetImage get img => _img!;

  LanguageData(String? languageName, String? languageCode, AssetImage? img)
  {
    _languageName = languageName;
    _languageCode = languageCode;
    _img = img;
  }
}
