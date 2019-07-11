import 'package:gcloud/db.dart';
import 'package:github/server.dart' hide createGitHubClient;
import 'package:github/server.dart' as gh show createGitHubClient;
import 'package:meta/meta.dart';

@immutable
class Config {
  const Config(this._db) : assert(_db != null);

  final DatastoreDB _db;

  Future<String> _getSingleValue(String id) async {
    final CocoonConfig cocoonConfig = CocoonConfig()
      ..id = id
      ..parentKey = _db.emptyKey;
    final result = await _db.lookup<CocoonConfig>([cocoonConfig.key]);
    return result.single.value;
  }

  Future<String> get githubOAuthToken => _getSingleValue('GitHubPRToken');

  Future<String> get nonMasterPullRequestMessage => _getSingleValue('NonMasterPullRequestMessage');

  Future<String> get webhookKey => _getSingleValue('WebhookKey');

  Future<String> get missingTestsPullRequestMessage => _getSingleValue('MissingTestsPullRequestMessage');

  Future<GitHub> createGitHubClient() async {
    final String githubToken = await githubOAuthToken;
    return gh.createGitHubClient(
      auth: Authentication.withToken(githubToken),
    );
  }
}

@Kind(name: 'CocoonConfig', idType: IdType.String)
class CocoonConfig extends Model {
  @StringProperty(propertyName: 'ParameterValue')
  String value;
}
