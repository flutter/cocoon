import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:test/test.dart';

void main() {
  test('IntegrationServer starts', () async {
    final server = IntegrationServer();
    expect(server.server, isNotNull);
    expect(server.config, isNotNull);
  });
}
