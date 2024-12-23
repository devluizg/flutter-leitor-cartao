import 'package:logger/logger.dart';

class ResultAnalyzer {
  static final Logger _logger = Logger();

  static double calculateScore(
      List<int> userAnswers, List<int> correctAnswers) {
    if (userAnswers.length != correctAnswers.length) {
      _logger.e('User answers and correct answers have different lengths');
      throw Exception('Arrays must have the same length');
    }

    int correct = 0;
    for (int i = 0; i < userAnswers.length; i++) {
      if (userAnswers[i] == correctAnswers[i]) {
        correct++;
      }
    }

    return (correct / userAnswers.length) * 100;
  }

  static Map<String, dynamic> generateReport(
    List<int> userAnswers,
    List<int> correctAnswers,
  ) {
    try {
      double score = calculateScore(userAnswers, correctAnswers);
      List<bool> correctnessMap = [];
      List<int> wrongQuestions = [];
      List<Map<String, dynamic>> detailedAnswers = [];

      for (int i = 0; i < userAnswers.length; i++) {
        bool isCorrect = userAnswers[i] == correctAnswers[i];
        correctnessMap.add(isCorrect);

        if (!isCorrect) {
          wrongQuestions.add(i + 1);
        }

        detailedAnswers.add({
          'questionNumber': i + 1,
          'userAnswer': _indexToLetter(userAnswers[i]),
          'correctAnswer': _indexToLetter(correctAnswers[i]),
          'isCorrect': isCorrect,
        });
      }

      return {
        'score': score,
        'totalQuestions': userAnswers.length,
        'correctAnswers': correctnessMap.where((e) => e).length,
        'wrongAnswers': wrongQuestions,
        'correctnessMap': correctnessMap,
        'detailedAnswers': detailedAnswers,
        'improvementSuggestions':
            _getImprovementSuggestions(score, wrongQuestions.length),
      };
    } catch (e) {
      _logger.e('Error generating report: $e');
      rethrow;
    }
  }

  static String _indexToLetter(int index) {
    return String.fromCharCode(65 + index); // A=0, B=1, C=2, etc.
  }

  static List<String> _getImprovementSuggestions(
      double score, int wrongAnswersCount) {
    List<String> suggestions = [];

    if (score < 50) {
      suggestions.add(
          'Considere revisar todo o conteúdo da matéria de forma abrangente.');
    } else if (score < 70) {
      suggestions.add(
          'Concentre-se nos tópicos relacionados às questões que você errou.');
    }

    if (wrongAnswersCount > 5) {
      suggestions
          .add('Pratique mais testes simulados para melhorar seu desempenho.');
    }

    if (score >= 90) {
      suggestions
          .add('Excelente desempenho! Continue mantendo o bom trabalho.');
    } else if (score >= 80) {
      suggestions.add(
          'Bom trabalho! Foque nas poucas áreas em que você cometeu erros para alcançar a excelência.');
    }

    suggestions.add(
        'Revise as questões que você errou e tente entender o motivo dos erros.');

    return suggestions;
  }
}
