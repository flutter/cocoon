import 'dart:convert';
import 'dart:typed_data';

class UserData {
  static Map<String, dynamic> decodeUserDataBytes(List<int> encodedBytes) {
    return decodeUserDataString(String.fromCharCodes(encodedBytes));
  }

  static Map<String, dynamic> decodeUserDataString(String encoded) {
    final Uint8List bytes = base64.decode(encoded);
    final String rawJson = String.fromCharCodes(bytes);
    if (rawJson.isEmpty) {
      return <String, dynamic>{};
    }
    return json.decode(rawJson) as Map<String, dynamic>;
  }

  static List<int>? encodeUserDataToBytes(Map<String, dynamic> userDataMap) {
    return base64Encode(json.encode(userDataMap).codeUnits).codeUnits;
  }

  static String? encodeUserDataToString(Map<String, dynamic> userDataMap) {
    return base64Encode(json.encode(userDataMap).codeUnits);
  }
}
