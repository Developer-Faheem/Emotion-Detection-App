import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = "";

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  loadCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await cameraController!.initialize();
      if (mounted) {
        setState(() {
          cameraController!.startImageStream((imageStream) {
            cameraImage = imageStream;
            runModel();
          });
        });
      }
    }
  }

  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 137.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      if (predictions != null && predictions.isNotEmpty) {
        setState(() {
          output = predictions[0]['label'] ?? '';
        });
      }
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    super.dispose();
    cameraController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.teal,
            title: const Text(
              "Emotion Detection App",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width,
                  child: cameraController != null &&
                          cameraController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: cameraController!.value.aspectRatio,
                          child: CameraPreview(cameraController!),
                        )
                      : Container(),
                ),
              ),
              Text(
                output,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
