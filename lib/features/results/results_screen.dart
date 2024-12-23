import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../answer_sheet/answer_sheet_model.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Resultados'),
      body: Consumer<AnswerSheetModel>(
        builder: (context, model, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScoreCard(context, model),
                  const SizedBox(height: 24),
                  _buildAnswerList(context, model),
                  const SizedBox(height: 24),
                  CustomButton(
                    onPressed: () => _showAnalysisDialog(context, model),
                    child: const Text('Ver Análise Detalhada'),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    onPressed: () {
                      model.reset();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Voltar ao Início'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, AnswerSheetModel model) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Pontuação',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${model.score.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${model.userAnswers.where((a) => model.correctAnswers[model.userAnswers.indexOf(a)] == a).length} de ${model.numQuestions} corretas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerList(BuildContext context, AnswerSheetModel model) {
    return Card(
      elevation: 4,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: model.numQuestions,
        itemBuilder: (context, index) {
          final isCorrect =
              model.userAnswers[index] == model.correctAnswers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isCorrect ? Colors.green : Colors.red,
              child: Icon(
                isCorrect ? Icons.check : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text('Questão ${index + 1}'),
            subtitle: Text(
              'Sua resposta: ${_indexToLetter(model.userAnswers[index])} | Correta: ${_indexToLetter(model.correctAnswers[index])}',
            ),
          );
        },
      ),
    );
  }

  void _showAnalysisDialog(BuildContext context, AnswerSheetModel model) {
    final List<String> analysis = _generateAnalysis(model);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Análise Detalhada'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: analysis.map((item) => Text('• $item')).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  List<String> _generateAnalysis(AnswerSheetModel model) {
    final List<String> analysis = [];
    final int totalQuestions = model.numQuestions;
    final int correctAnswers = model.userAnswers
        .where((a) => model.correctAnswers[model.userAnswers.indexOf(a)] == a)
        .length;

    analysis.add('Você acertou $correctAnswers de $totalQuestions questões.');
    analysis.add('Sua pontuação foi de ${model.score.toStringAsFixed(1)}%.');

    if (model.score < 60) {
      analysis.add('Você precisa estudar mais para melhorar seu desempenho.');
    } else if (model.score < 80) {
      analysis
          .add('Bom trabalho! Continue estudando para alcançar a excelência.');
    } else {
      analysis.add('Excelente desempenho! Continue assim.');
    }

    // Adicione mais análises conforme necessário

    return analysis;
  }

  String _indexToLetter(int index) {
    return String.fromCharCode(65 + index); // A=0, B=1, C=2, etc.
  }
}
