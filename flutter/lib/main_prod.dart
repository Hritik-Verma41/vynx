import 'package:vynx/config/env_config.dart';
import 'package:vynx/main.dart';

void main() async {
  EnvConfig.init(env: Environment.prod);
  await startApp();
}
