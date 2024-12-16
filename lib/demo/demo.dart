import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show Uint8List;
import 'package:example/demo/audio_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

// If someone update the following comment, please update also the Examples/README.md file and the code inside Examples/lib/demo/main.dart
/*
 * This is a Demo of what it is possible to do with Flutter Sound.
 * The code of this Demo app is not so simple and unfortunately not very clean :-( .
 *
 * Flutter Sound beginners : you probably should look to `[SimplePlayback]`  and `[SimpleRecorder]`
 *
 * The biggest interest of this Demo is that it shows most of the features of Flutter Sound :
 *
 * - Plays from various media with various codecs
 * - Records to various media with various codecs
 * - Pause and Resume control from recording or playback
 * - Shows how to use a Stream for getting the playback (or recoding) events
 * - Shows how to specify a callback function when a playback is terminated,
 * - Shows how to record to a Stream or playback from a stream
 * - Can show controls on the iOS or Android lock-screen
 * - ...
 *
 * This Demo does not make use of the Flutter Sound UI Widgets.
 *
 * It would be really great if someone rewrite this demo soon
 *
 */

///
const int tSAMPLERATE = 8000;

/// Sample rate used for Streams
const int tSTREAMSAMPLERATE = 44000; // 44100 does not work for recorder on iOS

///
const int tBLOCKSIZE = 4096;

class Demo extends StatefulWidget {
  const Demo({super.key});
  @override
  State<Demo> createState() => _MyAppState();
}

class _MyAppState extends State<Demo> {
  bool _isRecording = false;
  String? _path;

  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerSubscription;
  StreamSubscription? _recordingDataSubscription;

  FlutterSoundPlayer playerModule = FlutterSoundPlayer();
  FlutterSoundRecorder recorderModule = FlutterSoundRecorder();

  String _recorderTxt = '00:00';
  String _playerTxt = '00:00';

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;
  final Codec _codec = Codec.pcm16WAV;

  StreamController<Uint8List>? recordingDataController;
  IOSink? sink;

  Future<void> _initializeExample() async {
    await playerModule.closePlayer();
    await playerModule.openPlayer();
    await playerModule
        .setSubscriptionDuration(const Duration(milliseconds: 10));
    await recorderModule
        .setSubscriptionDuration(const Duration(milliseconds: 10));
    await initializeDateFormatting();
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await recorderModule.openRecorder();
  }

  Future<void> init() async {
    await openTheRecorder();
    await _initializeExample();

    // final session = await AudioSession.instance;
    // await session.configure(AudioSessionConfiguration(
    //   avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
    //   avAudioSessionCategoryOptions:
    //       AVAudioSessionCategoryOptions.allowBluetooth |
    //           AVAudioSessionCategoryOptions.defaultToSpeaker,
    //   avAudioSessionMode: AVAudioSessionMode.spokenAudio,
    //   avAudioSessionRouteSharingPolicy:
    //       AVAudioSessionRouteSharingPolicy.defaultPolicy,
    //   avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    //   androidAudioAttributes: const AndroidAudioAttributes(
    //     contentType: AndroidAudioContentType.speech,
    //     flags: AndroidAudioFlags.none,
    //     usage: AndroidAudioUsage.voiceCommunication,
    //   ),
    //   androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    //   androidWillPauseWhenDucked: true,
    // ));
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void cancelRecorderSubscriptions() {
    if (_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
  }

  void cancelRecordingDataSubscription() {
    if (_recordingDataSubscription != null) {
      _recordingDataSubscription!.cancel();
      _recordingDataSubscription = null;
    }
    recordingDataController = null;
    if (sink != null) {
      sink!.close();
      sink = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    cancelRecorderSubscriptions();
    cancelRecordingDataSubscription();
    releaseFlauto();
  }

  Future<void> releaseFlauto() async {
    try {
      await playerModule.closePlayer();
      await recorderModule.closeRecorder();
    } on Exception {
      playerModule.logger.e('Released unsuccessful');
    }
  }

  void startRecorder() async {
    try {
      // Request Microphone permission if needed
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
      var path = '';
      var tempDir = await getTemporaryDirectory();
      path = '${tempDir.path}/learnsic assessement ${ext[_codec.index]}';

      await recorderModule.startRecorder(
        toFile: path,
        // codec: _codec,
        bitRate: 8000,
        numChannels: 1,
        sampleRate: tSAMPLERATE,
      );
      recorderModule.logger.d('startRecorder');

      _recorderSubscription = recorderModule.onProgress!.listen((e) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            e.duration.inMilliseconds,
            isUtc: true);
        var txt = DateFormat('mm:ss', 'en_GB').format(date);

        setState(() {
          _recorderTxt = txt.substring(0, 5);
        });
      });

      setState(() {
        _isRecording = true;
        _path = path;
      });
    } on Exception catch (err) {
      recorderModule.logger.e('startRecorder error: $err');
      setState(() {
        stopRecorder();
        _isRecording = false;

        cancelRecordingDataSubscription();
        cancelRecorderSubscriptions();
      });
    }
  }

  void stopRecorder() async {
    try {
      await recorderModule.stopRecorder();
      recorderModule.logger.d('stopRecorder');
      cancelRecorderSubscriptions();
      cancelRecordingDataSubscription();
    } on Exception catch (err) {
      recorderModule.logger.d('stopRecorder error: $err');
    }
    setState(() {
      _isRecording = false;
    });
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  Future<void> seekToPlayer(int milliSecs) async {
    //playerModule.logger.d('-->seekToPlayer');
    try {
      if (playerModule.isPlaying) {
        await playerModule.seekToPlayer(Duration(milliseconds: milliSecs));
      }
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
    setState(() {});
    //playerModule.logger.d('<--seekToPlayer');
  }

  void startStopRecorder() {
    if (recorderModule.isRecording || recorderModule.isPaused) {
      stopRecorder();
    } else {
      startRecorder();
    }
  }

  void Function()? onStartRecorderPressed() {
    return startStopRecorder;
  }

  @override
  Widget build(BuildContext context) {
    Widget recorderSection = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _isRecording ? const Text("Recording") : Container(),
          Container(
            margin: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Text(
              _recorderTxt,
              style: const TextStyle(
                fontSize: 28.0,
                color: Colors.black,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                child: IconButton(
                  onPressed: onStartRecorderPressed(),
                  //padding: EdgeInsets.all(8.0),
                  icon: Icon(
                    recorderModule.isStopped ? Icons.mic : Icons.stop,
                    size: 35,
                  ),
                ),
              ),
            ],
          ),
        ]);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Sound Demo'),
      ),
      body: ListView(
        children: <Widget>[
          recorderSection,
          //ValueKey(_recorderSubscription.hashCode) fix that state not updating
          if (_path != null)
            AudioPlayerWidget(
              key: ValueKey(_recorderSubscription.hashCode),
              audioUrl: _path,
            ),
        ],
      ),
    );
  }
}
