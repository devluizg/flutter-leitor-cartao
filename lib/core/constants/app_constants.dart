class AppConstants {
  // App Info
  static const String appName = 'Cartão Resposta App';
  static const String appVersion = '1.0.0';

  // API Endpoints (se necessário no futuro)
  static const String baseUrl = 'https://api.example.com';

  // Image Processing
  static const int defaultImageWidth = 700;
  static const int defaultImageHeight = 900;
  static const int maxQuestions = 90;
  static const int maxAlternatives = 5;

  // Storage Keys
  static const String answersKey = 'saved_answers';
  static const String settingsKey = 'app_settings';

  // Error Messages
  static const String errorCamera = 'Erro ao acessar a câmera';
  static const String errorProcessing = 'Erro ao processar a imagem';
  static const String errorPermission = 'Permissões necessárias não concedidas';

  // Success Messages
  static const String successProcessing = 'Imagem processada com sucesso';
  static const String successSaving = 'Dados salvos com sucesso';
}
