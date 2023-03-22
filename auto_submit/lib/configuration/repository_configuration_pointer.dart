import 'package:auto_submit/exception/configuration_exception.dart';
import 'package:yaml/yaml.dart';

class RepositoryConfigurationPointerBuilder {
  late String _filePath;

  set filePath(String value) => _filePath = value;
}

class RepositoryConfigurationPointer {
  static const String CONFIG_PATH_KEY = 'config_path';

  RepositoryConfigurationPointer(RepositoryConfigurationPointerBuilder builder) : _filePath = builder._filePath;

  final String _filePath;

  String get filePath => _filePath;

  static RepositoryConfigurationPointer fromYaml(String yaml) {
    final RepositoryConfigurationPointerBuilder builder = RepositoryConfigurationPointerBuilder();
    final dynamic yamlDoc = loadYaml(yaml);

    if (yamlDoc[CONFIG_PATH_KEY] == null) {
      throw ConfigurationException('$CONFIG_PATH_KEY not found in local configuration.');
    }

    builder.filePath = yamlDoc[CONFIG_PATH_KEY];

    return RepositoryConfigurationPointer(builder);
  }
}
