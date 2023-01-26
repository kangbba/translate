import 'package:flutter/material.dart';
import 'package:google_cloud_translation/google_cloud_translation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late Translation _translation;

  TranslationModel _translated = TranslationModel(
      translatedText: 'en', detectedSourceLanguage: 'en');
  TranslationModel _detected = TranslationModel(
      translatedText: 'ru', detectedSourceLanguage: 'ru');

  //audio button
  late AnimationController _animationController;
  late Animation<Color?> _animateColor;
  late Animation<double> _animateIcon;
  Curve _curve = Curves.easeOut;
  late Size screenSize;

  //audio recognition
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _textTranslate(_lastWords);
      print("stop listening");
    });
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }


  @override
  void initState() {
    _translation = Translation(
      apiKey: 'AIzaSyCAPrLH8rFGJLoumRMZXUqQYAK7Q142t9E',
    );

    _animationController =
    AnimationController(vsync: this, duration: Duration(milliseconds: 500))
      ..addListener(() {
        setState(() {});
      });
    _animateIcon =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animateColor = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.00,
        1.00,
        curve: _curve,
      ),
    ));

    _initSpeech();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _animationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery
        .of(context)
        .size;
    return Scaffold(
      appBar: AppBar(
        title: Text('TRANSLATE'),
      ),
      body: Column(
        children: [

          _translateFrame_before(),
          _divider(screenSize.width, 1, 0, 0),
          _translateFrame_after(),
          _divider(screenSize.width, 1, 0, 0),
          _descriptionFrame(),
        ],
      ),
      floatingActionButton: audioButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  ElevatedButton _translateBtn() {
    return ElevatedButton(
            onPressed: () {
              _textTranslate(_lastWords);
            },

            child: Text("TRANSLATE")
        );
  }

  Widget _descriptionFrame()
  {
    return Positioned(
        bottom: 100,
        child: Column(
          children: [
            Text('Detected language - ${_translated.detectedSourceLanguage}',
                style: TextStyle(color: Colors.black26, )),
            Text('Language detected with detectLang - ${_detected.detectedSourceLanguage}',
                style: TextStyle(color: Colors.black26)
            )
          ],
        )
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
        child: Text(_translated.translatedText,
          style: TextStyle(color: Colors.black, fontSize: 20),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
  _textTranslate(String str) async
  {
    _translated = await _translation.translate(text: str, to: 'en');
    _detected = await _translation.detectLang(text: str);
    setState(() {});
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
}

