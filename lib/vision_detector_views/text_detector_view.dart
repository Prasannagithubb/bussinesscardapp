import 'dart:collection';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'detector_view.dart';
import 'painters/text_detector_painter.dart';

class TextRecognizerView extends StatefulWidget {
  @override
  State<TextRecognizerView> createState() => _TextRecognizerViewState();
}

class _TextRecognizerViewState extends State<TextRecognizerView> {
  var _script = TextRecognitionScript.latin;
  var _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  List<String> detectExt = [];
  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(),
      body: Stack(children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 350,
                width: 400,
                color: Colors.blueAccent,
                child: DetectorView(
                  title: 'Text Detector',
                  customPaint: _customPaint,
                  text: _text,
                  onImage: _processImage,
                  initialCameraLensDirection: _cameraLensDirection,
                  onCameraLensDirectionChanged: (value) =>
                      _cameraLensDirection = value,
                ),
              ),
              Container(
                height: 200,
                color: Colors.grey,
                width: double.infinity,
                child: detectExt.isEmpty
                    ? Center(child: Text('No data'))
                    : ListView.builder(
                        itemCount: detectExt.length,
                        itemBuilder: ((context, index) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Text('${detectExt[index]}'),
                                  IconButton(
                                      onPressed: () {
                                        Clipboard.setData(new ClipboardData(
                                            text: detectExt[index]));
                                      },
                                      icon: Icon(Icons.copy))
                                ],
                              ),
                            ),
                          );
                        })),
              ),
              Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [TextFormField(), TextFormField(), TextFormField()],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDropdown() => DropdownButton<TextRecognitionScript>(
        value: _script,
        icon: const Icon(Icons.arrow_downward),
        elevation: 16,
        style: const TextStyle(color: Colors.blue),
        underline: Container(
          height: 2,
          color: Colors.blue,
        ),
        onChanged: (TextRecognitionScript? script) {
          if (script != null) {
            setState(() {
              _script = script;
              _textRecognizer.close();
              _textRecognizer = TextRecognizer(script: _script);
            });
          }
        },
        items: TextRecognitionScript.values
            .map<DropdownMenuItem<TextRecognitionScript>>((script) {
          return DropdownMenuItem<TextRecognitionScript>(
            value: script,
            child: Text(script.name),
          );
        }).toList(),
      );

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    Size size = Size(600, 300);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = TextRecognizerPainter(
        recognizedText,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );

      recognizedText.blocks.forEach((element) {
        detectExt.add(element.text);
      });
      // detectExt.toSet().toList();
      List<String> result = LinkedHashSet<String>.from(detectExt).toList();
      detectExt = [];
      detectExt = result;
      _customPaint = CustomPaint(painter: painter, size: size);
      print("object1" + _customPaint.toString());
    } else {
      print("object2");

      _text = 'Recognized text:\n\n${recognizedText.text}';
      // recognizedText.blocks.forEach((element) {
      //   detectExt.add(element.text);
      // });
      detectExt.add(recognizedText.text);
      List<String> result = LinkedHashSet<String>.from(detectExt).toList();
      detectExt = [];
      detectExt = result;

      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }

    // if (detectExt.length < 2) {
    //   Future.delayed(Duration(seconds: 4)).then((value) {
    //     Navigator.pop(context);
    //   });
    // var date = new DateTime.now();

    // DateTime date2 = DateTime(date.year, date.month, date.day, date.second + 4);

    // DateTime temp = DateTime.now();
    // }
  }
}
