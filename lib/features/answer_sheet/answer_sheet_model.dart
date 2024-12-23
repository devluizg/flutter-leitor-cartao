import 'package:flutter/foundation.dart';

class AnswerSheetModel extends ChangeNotifier {
  List<int> _correctAnswers = [];
  List<int> _userAnswers = [];
  int _numQuestions = 0;
  int _numOptions = 5;
  double _score = 0.0;

  List<int> get correctAnswers => List.unmodifiable(_correctAnswers);
  List<int> get userAnswers => List.unmodifiable(_userAnswers);
  int get numQuestions => _numQuestions;
  int get numOptions => _numOptions;
  double get score => _score;

  void setCorrectAnswers(List<int> answers) {
    _correctAnswers = List.from(answers);
    _numQuestions = answers.length;
    _calculateScore();
    notifyListeners();
  }

  void setUserAnswers(List<int> answers) {
    _userAnswers = List.from(answers);
    _calculateScore();
    notifyListeners();
  }

  void setNumQuestions(int questions) {
    _numQuestions = questions;
    _correctAnswers = List.filled(questions, -1);
    _userAnswers = List.filled(questions, -1);
    _calculateScore();
    notifyListeners();
  }

  void setNumOptions(int options) {
    if (options > 0) {
      _numOptions = options;
      notifyListeners();
    }
  }

  void _calculateScore() {
    if (_correctAnswers.isEmpty || _userAnswers.isEmpty) {
      _score = 0.0;
      return;
    }

    int correct = 0;
    for (int i = 0;
        i < _correctAnswers.length && i < _userAnswers.length;
        i++) {
      if (_correctAnswers[i] == _userAnswers[i]) {
        correct++;
      }
    }

    _score = (correct / _correctAnswers.length) * 100;
  }

  List<bool> getGradingList() {
    if (_correctAnswers.isEmpty || _userAnswers.isEmpty) {
      return [];
    }

    return List.generate(
      _correctAnswers.length,
      (index) =>
          index < _userAnswers.length &&
          _correctAnswers[index] == _userAnswers[index],
    );
  }

  void reset() {
    _correctAnswers = [];
    _userAnswers = [];
    _numQuestions = 0;
    _score = 0.0;
    notifyListeners();
  }

  bool isComplete() {
    return _correctAnswers.length == _numQuestions &&
        _userAnswers.length == _numQuestions &&
        !_userAnswers.contains(-1);
  }

  void setUserAnswer(int questionIndex, int answerIndex) {
    if (questionIndex >= 0 &&
        questionIndex < _numQuestions &&
        answerIndex >= 0 &&
        answerIndex < _numOptions) {
      _userAnswers[questionIndex] = answerIndex;
      _calculateScore();
      notifyListeners();
    }
  }
}
