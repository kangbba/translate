
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
  LanguageData("한국어", "ko", null),
  LanguageData("일본어", "ja", null),
  LanguageData("영어", "en", null),
  LanguageData("중국어 간체", "zh-CN", null),
  LanguageData("중국어 번체", "zh-TW", null),
  LanguageData("스페인어", "es", null),
  LanguageData("프랑스어", "fr", null),
  LanguageData("독일어", "de", null),
  LanguageData("포르투갈어", "pt", null),
  LanguageData("이탈리아어", "it", null),
  LanguageData("베트남어", "vi", null),
  LanguageData("태국어", "th", null),
  LanguageData("러시아어", "ru", null)
];
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

  LanguageData? getLanguageData(String languageName) {
    for (int i = 0; i < languageItems.length; i++) {
      if (languageItems[i].languageName == languageName) {
        return languageItems[i];
      }
    }
    return null;
  }
}