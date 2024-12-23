import 'dart:io';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:logger/logger.dart';
import '../../core/utils/image_utils.dart';

class ImageProcessor {
  final Logger _logger = Logger();

  Future<cv.Mat?> processAnswerSheet(File imageFile) async {
    try {
      cv.Mat? originalMat = await ImageUtils.fileToMat(imageFile);
      if (originalMat == null) {
        throw Exception('Failed to convert image file to Mat');
      }

      cv.Mat? processedMat = await ImageUtils.processImage(originalMat);
      if (processedMat == null) {
        throw Exception('Failed to process image');
      }

      List<cv.Point> corners = await ImageUtils.findCorners(processedMat);
      if (corners.length != 4) {
        throw Exception('Failed to detect answer sheet corners');
      }

      cv.Mat warpedMat = await _applyPerspectiveTransform(originalMat, corners);

      // Limpar memória
      originalMat.dispose();
      processedMat.dispose();

      return warpedMat;
    } catch (e) {
      _logger.e('Error in processAnswerSheet: $e');
      return null;
    }
  }

  Future<cv.Mat> _applyPerspectiveTransform(
      cv.Mat original, List<cv.Point> corners) async {
    const width = 700;
    const height = 900;

    cv.VecPoint dstPoints = cv.VecPoint.fromList([
      cv.Point(0, 0),
      cv.Point(width - 1, 0),
      cv.Point(width - 1, height - 1),
      cv.Point(0, height - 1),
    ]);

    cv.Mat perspectiveMat = await cv.getPerspectiveTransformAsync(
        cv.VecPoint.fromList(corners), dstPoints);
    return await cv
        .warpPerspectiveAsync(original, perspectiveMat, (width, height));
  }

  Future<List<int>> extractAnswers(
      cv.Mat processedMat, int numQuestions, int numOptions) async {
    try {
      cv.Mat grayMat = await cv.cvtColorAsync(processedMat, cv.COLOR_BGR2GRAY);
      cv.Mat blur = await cv.blurAsync(grayMat, (5, 5));
      var thresholdResult = await cv.thresholdAsync(
          blur, 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU);
      cv.Mat thresholdMat = thresholdResult.$2;

      List<List<int>> pixelValues =
          await _splitBoxes(thresholdMat, numQuestions, numOptions);

      List<int> answers = [];
      for (var row in pixelValues) {
        int maxIndex = row.indexOf(row.reduce((a, b) => a > b ? a : b));
        answers.add(maxIndex);
      }

      // Limpar memória
      grayMat.dispose();
      blur.dispose();
      thresholdMat.dispose();

      return answers;
    } catch (e) {
      _logger.e('Error in extractAnswers: $e');
      return [];
    }
  }

  Future<List<List<int>>> _splitBoxes(
      cv.Mat img, int questions, int choices) async {
    List<List<int>> pixelValues = List.generate(
      questions,
      (_) => List.filled(choices, 0),
    );

    int height = img.rows ~/ questions;
    int width = img.cols ~/ choices;

    for (int i = 0; i < questions; i++) {
      for (int j = 0; j < choices; j++) {
        cv.Rect roi = cv.Rect(
          j * width,
          i * height,
          width,
          height,
        );
        cv.Mat box = img.region(roi);
        int nonZero = cv.countNonZero(box);
        pixelValues[i][j] = nonZero;
        box.dispose();
      }
    }

    return pixelValues;
  }

  Future<cv.Mat> drawAnswers(
      cv.Mat image, List<int> userAnswers, List<int> correctAnswers) async {
    cv.Mat result = image.clone();
    int questions = userAnswers.length;
    int height = image.rows ~/ questions;
    int width = image.cols ~/ 5;

    for (int i = 0; i < questions; i++) {
      cv.Point center = cv.Point((userAnswers[i] * width) + (width ~/ 2),
          (i * height) + (height ~/ 2));

      cv.Scalar color = userAnswers[i] == correctAnswers[i]
          ? cv.Scalar(0, 255, 0) // Green for correct
          : cv.Scalar(0, 0, 255); // Red for wrong

      cv.circle(result, center, 10, color, thickness: 2, lineType: cv.LINE_AA);
    }

    return result;
  }
}
