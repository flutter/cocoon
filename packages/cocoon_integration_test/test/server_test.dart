import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:test/test.dart';

void main() {
  test('IntegrationServer starts', () async {
    final server = await IntegrationServer.start();
    expect(server.server, isNotNull);
    expect(server.config, isNotNull);
  });
}
