import 'dart:convert';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:translate/language_data.dart';
import 'apikeys.dart';
import 'package:flutter/material.dart';

import 'bluetooth_submit.dart';
import 'helpers/MainPage.dart';
import 'language_items.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  late Size screenSize;
  //Translate

  String _coachingLevel = 'Education Level';

  //SpeechToText
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String _lastTranslatedWords = '';

  //dropdown menu
  String? selectedValue_before;
  String? selectedValue_after;
  final TextEditingController textEditingController = TextEditingController();

  LanguageItems languageItems = LanguageItems();


  @override
  void initState() {

    List<String> languageNames = languageItems.getLanguageNames();
    selectedValue_before = languageNames.first;
    selectedValue_after = languageNames[2];
    _initSpeech();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    textEditingController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    screenSize = MediaQuery
        .of(context)
        .size;
    List<String> languageNames = languageItems.getLanguageNames();
    return Scaffold(
      appBar: AppBar(
        title: Text('TRANSLATE'),
      ),
      endDrawer: Drawer(
        width: screenSize.width / 1.7,
        child: ListView(
          children: [
            ListTile(
              leading:Icon(Icons.info_outline_rounded),
              title: Text("Information"),
            ),
            InkWell(
              onTap: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                  MainPage() ));
              },
              child: ListTile(
                leading:Icon(Icons.settings_bluetooth_sharp),
                title: Text("Bluetooth Setting"),
              ),
            ),
            ListTile(
              leading:Icon(Icons.settings),
              title: Text("Settings"),
            ),
          ],
        )
        //elevation: 20.0,
        //semanticLabel: 'endDrawer',
      ),
      body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _dropDownMenu_before(languageNames),
                Icon(Icons.switch_right_rounded),
                _dropDownMenu_after( languageNames),
              ]
            ),
            Column(
              children: [
                _divider(screenSize.width, 1, 0, 0),
                _translateFrame_before(),
                _divider(screenSize.width, 1, 0, 0),
                _translateFrame_after(),
                _divider(screenSize.width, 1, 0, 0),
                ElevatedButton(
                    onPressed: (){
                      _openBluetoothScreen();
                    },
                    child: Icon(Icons.add)
                )
              ],
            ),
          ]
      ),
      floatingActionButton: audioButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  ElevatedButton _translateBtn() {
    return ElevatedButton(
            onPressed: () {
              _textTranslate(context, _lastWords);
            },

            child: Text("번역")
        );
  }


  Widget _translateFrame_before()
  {
    return SizedBox(
      width: screenSize.width,
      height: screenSize.height/4,
      child: Column(
          children :
         [
           _recognizedText(),
           _speechDescText(),
         ]
      ),
    );
  }
  Widget _translateFrame_after() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height/4,
        child: Text('$_lastTranslatedWords',
          style: TextStyle(color: Colors.black, fontSize: 20),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }

  Widget audioButton() {
    return FloatingActionButton(
        onPressed:
        _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: '음성인식 하시려면 눌러주세요',
        child: Icon(_speechToText.isNotListening ? Icons.mic : Icons.pause),
    );
  }

  Widget _divider(double width, double height, double beforeGap, double afterGap) {
    return Column(
        children: [
          SizedBox(height: beforeGap,),
          Container(
            color: Colors.black12,
            width: width,
            height: height,
          ),
          SizedBox(height: afterGap,),
        ]
    );
  }

  Widget _recognizedText() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Align(alignment : Alignment.centerLeft, child : Text('$_lastWords', style: TextStyle(fontSize: 20),)),
    );
  }
  Widget _speechDescText() {
    return Text( _speechToText.isListening ? 'Tap the microphone to start listening...' : '', style: TextStyle(color: Colors.redAccent),);
  }


  //TRANSLATIONS
  Future<dynamic> getUsedLanguage(String content) async {
    String _client_id = apiKey;
    String _client_secret = apiSecret;
    String _content_type = "application/x-www-form-urlencoded; charset=UTF-8";
    String _url = "https://openapi.naver.com/v1/papago/detectLangs";

    http.Response lan = await http.post(Uri.parse(_url), headers: {
      // 'query': text,
      'Content-Type': _content_type,
      'X-Naver-Client-Id': _client_id,
      'X-Naver-Client-Secret': _client_secret
    }, body: {
      'query': content
    });
    if (lan.statusCode == 200) {
      var dataJson = jsonDecode(lan.body);
      //만약 성공적으로 언어를 받아왔다면 language 변수에 언어가 저장됩니다. (ex: eu, ko, etc..)
      var language = dataJson['langCode'];
      return language;
    } else {
      print(lan.statusCode);
      throw("언어감지 실패");
    }
  }



  Future<String> _translate(String content, String sourceCode, String targetCode) async {
    String _client_id = apiKey;
    String _client_secret = apiSecret;
    String _content_type = "application/x-www-form-urlencoded; charset=UTF-8";
    String _url = "https://openapi.naver.com/v1/papago/n2mt";

    http.Response trans = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': _content_type,
        'X-Naver-Client-Id': _client_id,
        'X-Naver-Client-Secret': _client_secret
      },
      body: {
        'source': sourceCode,//위에서 언어 판별 함수에서 사용한 language 변수
        'target': targetCode,//원하는 언어를 선택할 수 있다.
        'text': content,
      },
    );
    if (trans.statusCode == 200) {
      var dataJson = jsonDecode(trans.body);
      String result_papago = dataJson['message']['result']['translatedText'];
      print(result_papago);
      return result_papago;
    }
    else {
      print('error ${trans.statusCode}');
      return '';
    }
  }

  Widget _dropDownMenu_before(List<String> items)
  {
    return SizedBox(
      child: DropdownButton<String>(
        focusNode: FocusNode(descendantsAreFocusable: false),
        value: selectedValue_before,
        icon: const Icon(Icons.arrow_downward, size: 15,),
        elevation: 16,
        alignment: Alignment.center,
        style: const TextStyle(color: Colors.indigo, fontSize: 13),
        underline: Container(
          height: 1,
          color: Colors.indigoAccent,
        ),
        onChanged: (String? value) {
          // This is called when the user selects an item.
          setState(() {
            selectedValue_before = value!;
          });
        },
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
  Widget _dropDownMenu_after(List<String> items) {
    return SizedBox(
      child: DropdownButton<String>(
        focusNode: FocusNode(descendantsAreFocusable: false),
        value: selectedValue_after,
        icon: const Icon(Icons.arrow_downward, size: 15,),
        elevation: 16,
        alignment: Alignment.center,
        style: const TextStyle(color: Colors.indigo, fontSize: 13),
        underline: Container(
          height: 1,
          color: Colors.indigoAccent,
        ),
        onChanged: (String? value) {
          // This is called when the user selects an item.
          setState(() {
            selectedValue_after = value!;
          });
        },
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    _lastWords = '';
    _lastTranslatedWords = '';


    setState(() {
    });
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    if(!Platform.isAndroid) {
      await _textTranslate(context, _lastWords);
    }
    setState(() {
      print("stop listening");
    });
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) async{
    _lastWords = result.recognizedWords;
    if(Platform.isAndroid) {
      await _textTranslate(context, _lastWords);
    }
    setState(() {
    });
  }

  Future<void> _textTranslate(BuildContext context, String str) async
  {
    LanguageItems languageItems = LanguageItems();
    LanguageData? languageDataSourceBefore = languageItems.getLanguageData(selectedValue_before!);
    LanguageData? languageDataSourceAfter = languageItems.getLanguageData(selectedValue_after!);
    if(languageDataSourceBefore == null || languageDataSourceAfter == null)
    {
      throw("도착 언어가 선택되지 않음");
    }
    String translatedStr = await _translate(_lastWords, languageDataSourceBefore.languageCode , languageDataSourceAfter.languageCode);
    _lastTranslatedWords = translatedStr;
  }

  _openBluetoothScreen() async {

    if(await checkIfPermisionGranted(context))
    {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return MainPage();
      }));
    }
    else{
      SnackBar snackBar = SnackBar(
        content: Text('권한 허용 해주셔야 사용 가능합니다.'), //snack bar의 내용. icon, button같은것도 가능하다.
        action: SnackBarAction( //추가로 작업을 넣기. 버튼넣기라 생각하면 편하다.
          label: 'OK', //버튼이름
          onPressed: (){
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            AppSettings.openAppSettings();
          }, //버튼 눌렀을때.
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

  }

  Future<bool> checkIfPermisionGranted(BuildContext context) async
  {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.speech,
      Permission.bluetooth,
      Permission.location,
    ].request();
    bool permitted = true;
    statuses.forEach((permission, permissionStatus){
      if(!permissionStatus.isGranted){
        permitted = false;
      }
    });
    print("어디서에러8");
    print(permitted);
    return permitted;
  }
}



