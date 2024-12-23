import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../answer_sheet/answer_sheet_model.dart';
import '../answer_sheet/answer_sheet_screen.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numQuestionsController = TextEditingController();
  final _numOptionsController = TextEditingController();
  final List<TextEditingController> _correctAnswersControllers = [];

  @override
  void initState() {
    super.initState();
    _numQuestionsController.text = '30'; // Valor padrão
    _numOptionsController.text = '5'; // Valor padrão
  }

  @override
  void dispose() {
    _numQuestionsController.dispose();
    _numOptionsController.dispose();
    for (var controller in _correctAnswersControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Configurar Correção'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _numQuestionsController,
                  decoration:
                      const InputDecoration(labelText: 'Número de Questões'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o número de questões';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Por favor, insira um número válido de questões';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numOptionsController,
                  decoration: const InputDecoration(
                      labelText: 'Número de Opções por Questão'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o número de opções';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 1) {
                      return 'Por favor, insira um número válido de opções';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                const Text('Respostas Corretas:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildCorrectAnswersFields(),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: _submitForm,
                  child: const Text('Iniciar Correção'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectAnswersFields() {
    int numQuestions = int.tryParse(_numQuestionsController.text) ?? 0;
    int numOptions = int.tryParse(_numOptionsController.text) ?? 0;

    // Ajusta o número de controllers conforme necessário
    while (_correctAnswersControllers.length < numQuestions) {
      _correctAnswersControllers.add(TextEditingController());
    }
    while (_correctAnswersControllers.length > numQuestions) {
      _correctAnswersControllers.removeLast().dispose();
    }

    return Column(
      children: List.generate(numQuestions, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller: _correctAnswersControllers[index],
            decoration: InputDecoration(labelText: 'Questão ${index + 1}'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a resposta correta';
              }
              if (value.length != 1 ||
                  !('ABCDE'
                      .substring(0, numOptions)
                      .contains(value.toUpperCase()))) {
                return 'Por favor, insira uma letra válida (A-${String.fromCharCode(64 + numOptions)})';
              }
              return null;
            },
          ),
        );
      }),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final model = context.read<AnswerSheetModel>();
      model.setNumQuestions(int.parse(_numQuestionsController.text));
      model.setNumOptions(int.parse(_numOptionsController.text));

      List<int> correctAnswers = _correctAnswersControllers
          .map((controller) => 'ABCDE'.indexOf(controller.text.toUpperCase()))
          .toList();
      model.setCorrectAnswers(correctAnswers);

      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const AnswerSheetScreen(),
      ));
    }
  }
}
