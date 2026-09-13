class ApiEndpoints {
  ApiEndpoints._();

  // Android emulator -> host machine's localhost is 10.0.2.2, NOT 127.0.0.1/localhost.
  // iOS simulator can use localhost directly. A physical device needs your machine's
  // LAN IP instead. Swap this to your Render/Railway URL once deployed.
  // static const String baseUrl = 'http://localhost:8080';
  static const String baseUrl = 'http://10.78.213.86:8080';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
}
