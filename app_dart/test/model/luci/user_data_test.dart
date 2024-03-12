import 'package:cocoon_service/src/model/luci/user_data.dart';
import 'package:test/test.dart';

void main() {
  test('encode and decode', () {
    final Map<String, dynamic> userDataMap = {};
    userDataMap['test'] = 'value';

    final List<int>? userDataBytes = UserData.encodeUserDataToBytes(userDataMap);
    final String? userDataString = UserData.encodeUserDataToString(userDataMap);
    print(userDataString);
    final returnUserDataMap = UserData.decodeUserDataBytes(userDataBytes!);
    print(returnUserDataMap);
  });
}