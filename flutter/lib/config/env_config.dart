import 'dart:io';

enum Environment { dev, prod }

class EnvConfig {
  final String baseUrl;
  final Environment environment;

  EnvConfig({required this.baseUrl, required this.environment});

  static late EnvConfig instance;

  static void init({required Environment env}) {
    if (env == Environment.dev) {
      instance = EnvConfig(
        baseUrl: getServerBaseUrl(env),
        environment: Environment.dev,
      );
    } else {
      instance = EnvConfig(
        baseUrl: getServerBaseUrl(env),
        environment: Environment.prod,
      );
    }
  }

  static String getServerBaseUrl(Environment env) {
    if (env == Environment.dev) {
      if (Platform.isAndroid) {
        return "http://10.0.2.2:8000/api";
      }
      return "http://localhost:8000/api";
    } else {
      return "http://80.225.234.142/vynx-api/api";
    }
  }
}
