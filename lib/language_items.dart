
import 'language_data.dart';

/*
한국어(ko)
일본어(ja)
중국어 간체(zh-CN)
중국어 번체(zh-TW)
힌디어(hi)
영어(en)
스페인어(es)
프랑스어(fr)
독일어(de)
포르투갈어(pt)
베트남어(vi)
인도네시아어(id)
페르시아어(fa)
아랍어(ar)
미얀마어(mm)
태국어(th)
러시아어(ru)
이탈리아어(it)
* */
final List<LanguageData> languageItems = [
  LanguageData("한국어", "ko", "ko_KR", 1, null),
  LanguageData("일본어", "ja", "ja_JP", 2, null),
  LanguageData("영어", "en", "en_US", 0, null),
  LanguageData("스페인어", "es", "es_ES", 3, null),
  LanguageData("프랑스어", "fr", "fr_FR", 4, null),
  LanguageData("독일어", "de", "de_DE", 5, null),
  LanguageData("포르투갈어", "pt", "pt_PT", 6, null),
  LanguageData("이탈리아어", "it", "it_IT", 7, null),
  LanguageData("베트남어", "vi", "vi_VN", 8, null),
  LanguageData("태국어", "th", "th_TH", 9, null),
  LanguageData("러시아어", "ru", "ru_RU", 10, null)
];
// LanguageData("중국어 간체", "zh-CN", "en_US", 3, null),
// LanguageData("중국어 번체", "zh-TW", "en_US", 4, null),
//new LanguageData("인도네시아어", "id", null),
//  new LanguageData("페르시아어", "fa", null),
// new LanguageData("아랍어", "ar", null),
// new LanguageData("미얀마어", "mm", null),
// new LanguageData("힌디어", "hi", null),
class LanguageItems {

  List<String> getLanguageNames()
  {
    List<String> languageStrs = [];
    for(int i = 0 ; i < languageItems.length ; i++)
    {
      languageStrs.add(languageItems[i].languageName);
    }
    return languageStrs;
  }

  LanguageData? getLanguageDataByName(String? languageName) {
    for (int i = 0; i < languageItems.length; i++) {
      if (languageItems[i].languageName == languageName) {
        return languageItems[i];
      }
    }
    return null;
  }

  LanguageData? getLanguageDataByCode(String? languageCode) {
    for (int i = 0; i < languageItems.length; i++) {
      if (languageItems[i].languageCode == languageCode) {
        return languageItems[i];
      }
    }
    return null;
  }
}