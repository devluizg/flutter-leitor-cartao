import 'dart:io';
import 'dart:math' show atan2, pi;
import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:logger/logger.dart';

class ImageUtils {
  static final Logger _logger = Logger();

  static Future<File?> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      _logger.e('Error picking image: $e');
      return null;
    }
  }

  static Future<cv.Mat?> fileToMat(File file) async {
    try {
      return cv.imread(file.path);
    } catch (e) {
      _logger.e('Error converting file to Mat: $e');
      return null;
    }
  }

  static Future<cv.Mat?> processImage(cv.Mat image) async {
    try {
      cv.Mat resized = cv.resize(image, (700, 900));
      cv.Mat gray = cv.cvtColor(resized, cv.COLOR_BGR2GRAY);
      cv.Mat blur = cv.blur(gray, (5, 5));
      cv.Mat edges = cv.canny(blur, 75, 200);
      cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      cv.Mat dilated = cv.dilate(edges, kernel);

      resized.dispose();
      gray.dispose();
      blur.dispose();
      edges.dispose();
      kernel.dispose();

      return dilated;
    } catch (e) {
      _logger.e('Error processing image: $e');
      return null;
    }
  }

  static Future<List<cv.Point>> findCorners(cv.Mat image) async {
    try {
      final contoursResult = cv.findContours(
        image,
        cv.RETR_EXTERNAL,
        cv.CHAIN_APPROX_SIMPLE,
      );

      final contours = contoursResult.$1;
      cv.VecPoint maxContour = cv.VecPoint();
      double maxArea = 0;

      for (var contour in contours) {
        double area = cv.contourArea(contour);
        if (area > image.rows * image.cols * 0.1) {
          double peri = cv.arcLength(contour, true);
          var approx = cv.approxPolyDP(contour, 0.02 * peri, true);

          if (approx.length == 4 && _validateCornerAngles(approx.toList())) {
            if (area > maxArea) {
              maxArea = area;
              maxContour = approx;
            }
          }
        }
      }

      return _reorderCorners(maxContour.toList());
    } catch (e) {
      _logger.e('Error finding corners: $e');
      return [];
    }
  }

  static bool _validateCornerAngles(List<cv.Point> corners) {
    if (corners.length != 4) return false;

    for (int i = 0; i < 4; i++) {
      var p1 = corners[i];
      var p2 = corners[(i + 1) % 4];
      var p3 = corners[(i + 2) % 4];

      double angle = _calculateAngle(p1, p2, p3);
      if (angle < 80 || angle > 100) return false;
    }
    return true;
  }

  static double _calculateAngle(cv.Point p1, cv.Point p2, cv.Point p3) {
    int dx1 = p1.x - p2.x;
    int dy1 = p1.y - p2.y;
    int dx2 = p3.x - p2.x;
    int dy2 = p3.y - p2.y;

    double dot = (dx1 * dx2 + dy1 * dy2).toDouble();
    double cross = (dx1 * dy2 - dy1 * dx2).toDouble();

    return (180 / pi) * atan2(cross.abs(), dot);
  }

  static List<cv.Point> _reorderCorners(List<cv.Point> corners) {
    if (corners.isEmpty) return [];
    corners.sort((a, b) => a.y.compareTo(b.y));
    final top = corners.sublist(0, 2);
    final bottom = corners.sublist(2);
    top.sort((a, b) => a.x.compareTo(b.x));
    bottom.sort((a, b) => a.x.compareTo(b.x));
    return [top[0], top[1], bottom[1], bottom[0]];
  }

  static Future<List<int>> processAnswers(
    cv.Mat image,
    List<cv.Point> corners,
    int numQuestions,
    int numOptions,
  ) async {
    try {
      const width = 700;
      const height = 900;

      // 1. Transformação de perspectiva
      final dst = cv.VecPoint.fromList([
        cv.Point(0, 0),
        cv.Point(width - 1, 0),
        cv.Point(width - 1, height - 1),
        cv.Point(0, height - 1),
      ]);

      final matrix =
          cv.getPerspectiveTransform(cv.VecPoint.fromList(corners), dst);
      final warped = cv.warpPerspective(image, matrix, (width, height));

      // 2. Pré-processamento aprimorado
      final gray = cv.cvtColor(warped, cv.COLOR_BGR2GRAY);
      final blur =
          cv.blur(gray, (5, 5)); // Substituímos GaussianBlur por blur normal
      final thresh = cv.adaptiveThreshold(
        blur,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY_INV,
        11,
        2,
      );

      final List<int> answers = [];
      final questionHeight = height ~/ numQuestions;
      final optionWidth = width ~/ numOptions;

      // Margens para reduzir interferência
      const marginX = 10;
      const marginY = 5;

      for (int q = 0; q < numQuestions; q++) {
        List<double> optionScores = [];

        for (int opt = 0; opt < numOptions; opt++) {
          // ROI com margens
          final roi = thresh.region(cv.Rect(
            opt * optionWidth + marginX,
            q * questionHeight + marginY,
            optionWidth - (2 * marginX),
            questionHeight - (2 * marginY),
          ));

          // Análise multi-critério
          final nonZero = cv.countNonZero(roi);
          final total = roi.rows * roi.cols;
          final percentFilled = nonZero / total;

          // Análise de contornos
          final contours = cv
              .findContours(
                roi,
                cv.RETR_EXTERNAL,
                cv.CHAIN_APPROX_SIMPLE,
              )
              .$1;

          double circularityScore = 0;
          if (contours.isNotEmpty) {
            final largestContour = contours.reduce(
              (curr, next) =>
                  cv.contourArea(curr) > cv.contourArea(next) ? curr : next,
            );

            final area = cv.contourArea(largestContour);
            final perimeter = cv.arcLength(largestContour, true);

            if (perimeter > 0) {
              circularityScore = (4 * pi * area) / (perimeter * perimeter);
            }
          }

          // Pontuação combinada
          final score = percentFilled * 0.7 + circularityScore * 0.3;
          optionScores.add(score);

          roi.dispose();
        }

        // Determinação da resposta com limiar
        int maxIndex = -1;
        double maxScore = 0.15; // Limiar mínimo

        for (int i = 0; i < optionScores.length; i++) {
          if (optionScores[i] > maxScore) {
            maxScore = optionScores[i];
            maxIndex = i;
          }
        }

        answers.add(maxIndex);
      }

      // Limpeza de memória
      warped.dispose();
      gray.dispose();
      blur.dispose();
      thresh.dispose();

      return answers;
    } catch (e) {
      _logger.e('Error processing answers: $e');
      return List.filled(numQuestions, -1);
    }
  }
}
