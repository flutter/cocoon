import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/configuration/repository_configuration_manager.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:neat_cache/neat_cache.dart';

class FakeRepositoryConfigurationManager implements RepositoryConfigurationManager {
  FakeRepositoryConfigurationManager(this.cache);

  String? yamlConfig;

  @override
  final Cache cache;

  late RepositoryConfiguration? repositoryConfigurationMock;

  @override
  Future<RepositoryConfiguration> readRepositoryConfiguration(GithubService githubService, RepositorySlug slug) async {
    return repositoryConfigurationMock!;
  }

  @override
  RepositorySlug get githubRepo => RepositorySlug('flutter', '.github');
}
