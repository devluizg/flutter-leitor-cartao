import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../core/utils/image_utils.dart';
import '../answer_sheet/answer_sheet_model.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../results/results_screen.dart';

class AnswerSheetScreen extends StatefulWidget {
  const AnswerSheetScreen({Key? key}) : super(key: key);

  @override
  State<AnswerSheetScreen> createState() => _AnswerSheetScreenState();
}

class _AnswerSheetScreenState extends State<AnswerSheetScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  Timer? _processingTimer;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
    if (mounted) {
      setState(() {});
      _startProcessingTimer();
    }
  }

  void _startProcessingTimer() {
    _processingTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isProcessing) {
        _processImage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _processingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Corrigir Cartão Resposta'),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                _buildOverlay(),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;

        double rectWidth = width * 0.55;
        double rectHeight = height * 0.55;

        return CustomPaint(
          size: Size.infinite,
          painter: OverlayPainter(
            rect: Rect.fromCenter(
              center: Offset(width / 2, height / 2),
              width: rectWidth,
              height: rectHeight,
            ),
          ),
        );
      },
    );
  }

  Future<void> _processImage() async {
    if (!mounted || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller.takePicture();
      final File imageFile = File(image.path);

      final mat = await ImageUtils.fileToMat(imageFile);
      if (mat != null) {
        final processedMat = await ImageUtils.processImage(mat);
        if (processedMat != null) {
          final corners = await ImageUtils.findCorners(processedMat);
          if (corners.isNotEmpty) {
            if (!mounted) return;
            final model = Provider.of<AnswerSheetModel>(context, listen: false);
            final results = await ImageUtils.processAnswers(
              processedMat,
              corners,
              model.numQuestions,
              model.numOptions,
            );
            model.setUserAnswers(results);
            if (mounted) {
              _navigateToResultsScreen();
            }
            return;
          }
        }
      }
    } catch (e) {
      _logger.e('Error processing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _navigateToResultsScreen() {
    _processingTimer?.cancel();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const ResultsScreen(),
    ));
  }
}

class OverlayPainter extends CustomPainter {
  final Rect rect;

  OverlayPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(rect, paint);

    final cornerSize = rect.width * 0.1;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Canto superior esquerdo
    canvas.drawLine(
        rect.topLeft, rect.topLeft.translate(cornerSize, 0), cornerPaint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft.translate(0, cornerSize), cornerPaint);

    // Canto superior direito
    canvas.drawLine(
        rect.topRight, rect.topRight.translate(-cornerSize, 0), cornerPaint);
    canvas.drawLine(
        rect.topRight, rect.topRight.translate(0, cornerSize), cornerPaint);

    // Canto inferior esquerdo
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft.translate(cornerSize, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -cornerSize),
        cornerPaint);

    // Canto inferior direito
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight.translate(-cornerSize, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight.translate(0, -cornerSize), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
