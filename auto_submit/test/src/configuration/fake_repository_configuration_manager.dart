import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/configuration/repository_configuration_manager.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:neat_cache/neat_cache.dart';

class FakeRepositoryConfigurationManager implements RepositoryConfigurationManager {
  FakeRepositoryConfigurationManager(this.cache);

  @override
  final Cache cache;

  @override
  Future<RepositoryConfiguration> readRepositoryConfiguration(GithubService githubService, RepositorySlug slug) {
    // TODO: implement readRepositoryConfiguration
    throw UnimplementedError();
  }

  @override
  Future<List<int>> getConfiguration(GithubService githubService, RepositorySlug slug) {
    // TODO: implement getConfiguration
    throw UnimplementedError();
  }
}
