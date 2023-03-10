
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translate/language_data.dart';
import 'apikeys.dart';
import 'package:flutter/material.dart';
import 'helpers/ChatPage.dart';
import 'helpers/DiscoveryPage.dart';
import 'helpers/MainPage.dart';
import 'helpers/SelectBondedDevicePage.dart';
import 'language_items.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _MainScreenState extends State<MainScreen> {


  //Bluetooth and devices
  List<String> sendingMsgList = [];
  static final clientID = 0;
  late List<LocaleName> _speechToTextLocales;
  BluetoothDevice? currentBluetoothDevice;
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool deviceConnectTrying = false;

  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  //
  late Size screenSize;
  //Translate

  //SpeechToText
  late LocaleName currentLocaleName;
  SpeechToText _speechToText = SpeechToText();
  LocaleName? defaultLocaleName;
  bool _speechEnabled = false;
  String _lastSourceWords = '';
  String _lastTranslatedWords = '';
  LanguageData? _lastTranslatedLanguageData ;

  //dropdown menu
  String? currentSourceLanguageName;
  String? currentTargetLanguageName;
  final TextEditingController translateTextEditingController = TextEditingController();

  LanguageItems languageItems = LanguageItems();

  late Timer periodicSendMessageTimer;

  @override
  void initState() {
    List<String> languageNames = languageItems.getLanguageNames();
    currentSourceLanguageName = languageNames.first;
    currentTargetLanguageName = languageNames[1];
    _initSpeech();
    startSendMessageTimer();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement disposes
    translateTextEditingController.dispose();

    _disposeDeviceConnect();

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
              hoverColor: Colors.grey,
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
                _translateFrame_source(140),
                _divider(screenSize.width, 1, 0, 0),
                _translateFrame_target(100),
                _divider(screenSize.width, 1, 0, 0),
                _sendMessageButton(),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  findDeviceButton(),
                  connectDeviceButton(),
                  connectDeviceInfo(),
                ]
              ),
            )

          ]
      ),
      floatingActionButton: audioButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  SizedBox connectDeviceInfo() {
    return SizedBox(
      child: Column(
          children :
          [
            Row(
                children: [
                  Text("???????????? ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
                  Icon(Icons.circle, color: isConnected ? Colors.lightGreenAccent : Colors.red, size: 14,)
                ]
            ),
            Text('${currentBluetoothDevice?.name}', style: TextStyle(fontSize: 12),)
          ]
      ),
    );
  }

  _sendMessageButton()
  {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
            style: commonButtonStyle(6, 6),
            child:  deviceConnectTrying ?
            LoadingAnimationWidget.threeArchedCircle(color: Colors.indigoAccent, size: 20
            ) : Icon(Icons.send, size: 20,),
            onPressed: !isConnected? null : () async {
              _sendLastTraslatedWordsToDevice();
            }
        ),
      ),
    );
  }

  _sendLastTraslatedWordsToDevice() async
  {
    if(sendingMsgList.isEmpty || _lastTranslatedLanguageData == null || _lastTranslatedWords.isEmpty)
    {
      return;
    }
    else
    {
      if(sendingMsgList.last != recentSentSendingMsg)
      {
        await _sendMessage(sendingMsgList.last);

        print("???????????? ????????? ?????? ?????? ${sendingMsgList.last}");
        recentSentSendingMsg = sendingMsgList.last;
      }
      else{
      }
    }
  }
  int duiplicatedSendMsgCount = 0;
  String recentSentSendingMsg = '';


  Widget _translateFrame_source(double height)
  {
    return SizedBox(
      width: screenSize.width,
      height: height,
      child: Column(
          children :
         [
           _recognizedText(),
            Text( _speechToText.isListening ? 'Tap the microphone to start listening...' : '', style: TextStyle(color: Colors.redAccent),)
         ]
      ),
    );
  }
  Widget _translateFrame_target(double height) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: SizedBox(
        width: screenSize.width,
        height: height,
        child: Text('$_lastTranslatedWords',
          style: TextStyle(color: Colors.black, fontSize: 20),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }

  ButtonStyle commonButtonStyle(double horizontal, double vertical)
  {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.indigoAccent,
      padding:
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      textStyle:
      const TextStyle(fontSize: 30, fontWeight: FontWeight.bold));
  }

  Widget audioButton() {
    return FloatingActionButton(
        onPressed:
        _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: '???????????? ???????????? ???????????????',
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
      child: Align(alignment : Alignment.centerLeft, child : Text('$_lastSourceWords', style: TextStyle(fontSize: 20),)),
    );
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
      //?????? ??????????????? ????????? ??????????????? language ????????? ????????? ???????????????. (ex: eu, ko, etc..)
      var language = dataJson['langCode'];
      return language;
    } else {
      print(lan.statusCode);
      throw("???????????? ??????");
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
        'source': sourceCode,//????????? ?????? ?????? ???????????? ????????? language ??????
        'target': targetCode,//????????? ????????? ????????? ??? ??????.
        'text': content,
      },
    );
    if (trans.statusCode == 200) {
      var dataJson = jsonDecode(trans.body);
      String result_papago = dataJson['message']['result']['translatedText'];
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
        value: currentSourceLanguageName,
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
          setState((){
            currentSourceLanguageName = value!;

            LanguageData? currentLanguageData = LanguageItems().getLanguageDataByName(currentSourceLanguageName);

            LocaleName foundLocaleName = getLocaleNameFromList(currentLanguageData!.speechLocaleId);
            print("${currentLanguageData!.speechLocaleId} ??? ??????????????? ??? ???????????? ?????? ??? : ${_speechToTextLocales.length}");
            print(foundLocaleName.name + "/" + foundLocaleName!.localeId + "/" + currentLanguageData!.speechLocaleId) ;

            currentLocaleName = foundLocaleName;
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
        value: currentTargetLanguageName,
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
            currentTargetLanguageName = value!;
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
    _speechToTextLocales = await _speechToText.locales();
    defaultLocaleName = await _speechToText.systemLocale();
    currentLocaleName = defaultLocaleName!;
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    print("_startListening");
    _disposeMessageList();
    _lastSourceWords = '';
    _lastTranslatedWords = '';
    await _speechToText.listen(localeId: currentLocaleName.localeId, onResult: _onSpeechResult);
    setState(() {
    });
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    print("_stopListening");
    await _speechToText.stop();
    setState(() {
    });
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) async{
    print("_onSpeechResult");
    LanguageItems languageItems = LanguageItems();
    LanguageData? languageDataSourceBefore = languageItems.getLanguageDataByName(currentSourceLanguageName);
    LanguageData? languageDataSourceAfter = languageItems.getLanguageDataByName(currentTargetLanguageName);
    if(languageDataSourceBefore != null && languageDataSourceAfter != null)
    {
      _lastSourceWords = result.recognizedWords;
      _lastTranslatedWords = await _textTranslate(_lastSourceWords, languageDataSourceBefore.languageCode!, languageDataSourceAfter.languageCode!);
      _lastTranslatedLanguageData = languageDataSourceAfter;

      int arduinoUniqueId = _lastTranslatedLanguageData!.arduinoUniqueId;
      String fullMsg = "$arduinoUniqueId:$_lastTranslatedWords;";
      print("${sendingMsgList.length} : $fullMsg");
      sendingMsgList.add(fullMsg);
    }
    setState(() {
    });
  }


  Future<String> _textTranslate(String str, String sourceLanguageCode, String targetLanguageCode) async
  {
    String translatedStr = await _translate(_lastSourceWords, sourceLanguageCode, targetLanguageCode);
    return translatedStr;
  }


  Future<bool> checkIfPermisionGranted() async
  {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.speech,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.locationAlways
    ].request();
    bool permitted = true;
    statuses.forEach((permission, permissionStatus){
      if(!permissionStatus.isGranted){
        permitted = false;
      }
    });
    print(permitted);
    return permitted;
  }


  simpleSnackbar(BuildContext context, String content)
  {
    SnackBar snackBar = SnackBar(
      content: Text(content), //snack bar??? ??????. icon, button???????????? ????????????.
      action: SnackBarAction( //????????? ????????? ??????. ??????????????? ???????????? ?????????.
        label: 'OK', //????????????
        onPressed: (){
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }, //?????? ????????????.
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget findDeviceButton()
  {
    return SizedBox(
        child: ElevatedButton(
            onPressed: () async {
              if(await checkIfPermisionGranted())
              {
              }
              else{
                SnackBar snackBar = SnackBar(
                  content: Text('?????? ?????? ???????????? ?????? ???????????????.'), //snack bar??? ??????. icon, button???????????? ????????????.
                  action: SnackBarAction( //????????? ????????? ??????. ??????????????? ???????????? ?????????.
                    label: 'OK', //????????????
                    onPressed: (){
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      AppSettings.openAppSettings();
                    }, //?????? ????????????.
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
              final BluetoothDevice? selectedDevice =
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return DiscoveryPage();
                  },
                ),
              );
              if (selectedDevice != null) {
                print('Discovery -> selected ' + selectedDevice.address);
              } else {
                print('Discovery -> no device selected');
              }
            },
            child: Icon(Icons.find_in_page_outlined)
        )
    );
  }

  connectDeviceButton()
  {
    return SizedBox(
      child: ElevatedButton(
          onPressed: () async {
            if(await checkIfPermisionGranted())
            {
            }
            else{
              SnackBar snackBar = SnackBar(
                content: Text('?????? ?????? ???????????? ?????? ???????????????.'), //snack bar??? ??????. icon, button???????????? ????????????.
                action: SnackBarAction( //????????? ????????? ??????. ??????????????? ???????????? ?????????.
                  label: 'OK', //????????????
                  onPressed: (){
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    AppSettings.openAppSettings();
                  }, //?????? ????????????.
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
            final BluetoothDevice? selectedDevice =
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return SelectBondedDevicePage(checkAvailability: false);
                },
              ),
            );
            setState(() {
              if (selectedDevice != null) {
                print('Connect -> selected ' + selectedDevice.address);
                currentBluetoothDevice = selectedDevice;
                bluetoothDeviceConnect(selectedDevice!);
              }
              else {
                print('Connect -> no device selected');
              }
            });
          },
          child: Icon(Icons.bluetooth_searching)
      ),
    );
  }

  bluetoothDeviceConnect(BluetoothDevice bluetoothDevice)
  {
    _disposeDeviceConnect();
    setState(() {deviceConnectTrying = true;});
    BluetoothConnection.toAddress(bluetoothDevice.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        deviceConnectTrying = false;
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connectionflu
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {
            deviceConnectTrying = false;

          });

        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }
  }


  _sendMessage(String text) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });
        // Future.delayed(Duration(milliseconds: 333)).then((_) {
        //   listScrollController.animateTo(
        //       listScrollController.position.maxScrollExtent,
        //       duration: Duration(milliseconds: 333),
        //       curve: Curves.easeOut);
        // });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  void _disposeDeviceConnect() {
    if (isConnected) {
      currentBluetoothDevice = null;
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
  }

  LocaleName getLocaleNameFromList(String localeId)
  {
    for(int i = 0 ; i < _speechToTextLocales.length ; i++)
    {
      if(_speechToTextLocales[i].localeId.trim() == localeId.trim())
      {
        return _speechToTextLocales[i];
      }
    }
    return defaultLocaleName!;
  }

  startSendMessageTimer() {
    periodicSendMessageTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if(!isConnected || deviceConnectTrying ) {
      }
      else{
        _sendLastTraslatedWordsToDevice();
      }
    });
  }
  cancelSendMessageTimer() {
    periodicSendMessageTimer.cancel();
  }

  void _disposeMessageList() {
    sendingMsgList.clear();
    duiplicatedSendMsgCount = 0;
  }
}

