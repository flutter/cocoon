// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:device_doctor/src/ios_debug_symbol_doctor.dart';

import 'package:test/test.dart';

Future<void> main() async {
  test('surfaces "Fetching debug symbols" error messages', () {
    final Iterable<XCDevice> devices = XCDevice.parseJson(_jsonWithErrors);
    final Iterable<XCDevice> erroredDevices = devices.where((XCDevice device) {
      return device.hasError;
    });
    expect(erroredDevices, hasLength(1));
    final XCDevice erroredDevice = erroredDevices.single;
    expect(erroredDevice.error!['code'], -10);
    expect(erroredDevice.error!['failureReason'], isEmpty);
    expect(erroredDevice.error!['description'], 'iPhone is busy: Fetching debug symbols for iPhone');
    expect(erroredDevice.error!['recoverySuggestion'], 'Xcode will continue when iPhone is finished.');
    expect(erroredDevice.error!['domain'], 'com.apple.platform.iphoneos');
  });

  test('ignores "phone is locked" errors', () {
    final Iterable<XCDevice> devices = XCDevice.parseJson(_jsonWithNonFatalErrors);
    final Iterable<XCDevice> erroredDevices = devices.where((XCDevice device) {
      return device.hasError;
    });
    expect(erroredDevices, isEmpty);
  });
}

const String _jsonWithNonFatalErrors = '''
[
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone10,4",
    "identifier" : "0EB90BF2-5C9F-4064-89AF-145467A3CB16",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-8-2",
    "modelName" : "iPhone 8",
    "name" : "iPhone 8"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad6,4",
    "identifier" : "981D07BC-13D0-41F4-B050-86FAAE0D2E6E",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-pro-9point7-a1674-b9b7ba",
    "modelName" : "iPad Pro (9.7-inch)",
    "name" : "iPad Pro (9.7-inch)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "8.5 (19T241)",
    "available" : true,
    "platform" : "com.apple.platform.watchsimulator",
    "companionDevice" : {
      "simulator" : true,
      "operatingSystemVersion" : "15.4 (19E240)",
      "available" : true,
      "platform" : "com.apple.platform.iphonesimulator",
      "modelCode" : "iPhone13,3",
      "identifier" : "D70DFEA5-6205-4E79-B93F-D7FD306D355B",
      "architecture" : "x86_64",
      "modelUTI" : "com.apple.iphone-12-pro-1",
      "modelName" : "iPhone 12 Pro",
      "name" : "iPhone 12 Pro"
    },
    "modelCode" : "Watch5,3",
    "identifier" : "87271E4A-0F29-4668-BAB9-2B4DAFF475B7",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.watch-series5-1",
    "modelName" : "Apple Watch Series 5 - 40mm",
    "name" : "Apple Watch Series 5 - 40mm"
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "12.4 (21F79)",
    "interface" : "usb",
    "available" : true,
    "platform" : "com.apple.platform.macosx",
    "modelCode" : "MacBookPro15,1",
    "identifier" : "81C75766-84F9-53FD-88EF-E71B7594BD63",
    "architecture" : "x86_64h",
    "modelUTI" : "com.apple.macbookpro-15-retina-touchid-2018",
    "modelName" : "MacBook Pro",
    "name" : "My Mac"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone12,5",
    "identifier" : "7B3FBE40-3C8B-42E6-85AA-A7E1BCB3E6EC",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-11-pro-max-1",
    "modelName" : "iPhone 11 Pro Max",
    "name" : "iPhone 11 Pro Max"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "8.5 (19T241)",
    "available" : true,
    "platform" : "com.apple.platform.watchsimulator",
    "companionDevice" : {
      "simulator" : true,
      "operatingSystemVersion" : "15.4 (19E240)",
      "available" : true,
      "platform" : "com.apple.platform.iphonesimulator",
      "modelCode" : "iPhone14,4",
      "identifier" : "64E2D17D-91FD-432A-B27A-88636C40003A",
      "architecture" : "x86_64",
      "modelUTI" : "com.apple.iphone-13-mini-1",
      "modelName" : "iPhone 13 mini",
      "name" : "iPhone 13 mini"
    },
    "modelCode" : "Watch6,6",
    "identifier" : "DCB1D78B-7E4A-4685-81CF-B77EDC5E2EE0",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.watch-series7-1",
    "modelName" : "Apple Watch Series 7 - 41mm",
    "name" : "Apple Watch Series 7 - 41mm"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,3",
    "identifier" : "3475BAD8-4D10-4C4B-A915-D9ECF076C0DC",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-13-pro-max-1",
    "modelName" : "iPhone 13 Pro Max",
    "name" : "iPhone 13 Pro Max"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "8.5 (19T241)",
    "available" : true,
    "platform" : "com.apple.platform.watchsimulator",
    "companionDevice" : {
      "simulator" : true,
      "operatingSystemVersion" : "15.4 (19E240)",
      "available" : true,
      "platform" : "com.apple.platform.iphonesimulator",
      "modelCode" : "iPhone14,3",
      "identifier" : "3475BAD8-4D10-4C4B-A915-D9ECF076C0DC",
      "architecture" : "x86_64",
      "modelUTI" : "com.apple.iphone-13-pro-max-1",
      "modelName" : "iPhone 13 Pro Max",
      "name" : "iPhone 13 Pro Max"
    },
    "modelCode" : "Watch6,2",
    "identifier" : "DB4C5E55-6B6E-4077-8478-FBFF52A0AC66",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.watch-series6-1",
    "modelName" : "Apple Watch Series 6 - 44mm",
    "name" : "Apple Watch Series 6 - 44mm"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,6",
    "identifier" : "5D79285F-D8FD-4BF9-AEE5-088A1CE5FAE6",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-se3-1",
    "modelName" : "iPhone SE (3rd generation)",
    "name" : "iPhone SE (3rd generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPod9,1",
    "identifier" : "21DC2659-BA99-4F9E-9D60-7981BDC61C89",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipod-touch-7-2",
    "modelName" : "iPod touch (7th generation)",
    "name" : "iPod touch (7th generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad14,1",
    "identifier" : "0DCA123D-464C-4732-8650-3F475B908B8B",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-mini6-1",
    "modelName" : "iPad mini (6th generation)",
    "name" : "iPad mini (6th generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "8.5 (19T241)",
    "available" : true,
    "platform" : "com.apple.platform.watchsimulator",
    "companionDevice" : {
      "simulator" : true,
      "operatingSystemVersion" : "15.4 (19E240)",
      "available" : true,
      "platform" : "com.apple.platform.iphonesimulator",
      "modelCode" : "iPhone14,5",
      "identifier" : "91D351F9-0432-4D29-85BF-317B30D3C8C8",
      "architecture" : "x86_64",
      "modelUTI" : "com.apple.iphone-13-1",
      "modelName" : "iPhone 13",
      "name" : "iPhone 13"
    },
    "modelCode" : "Watch6,9",
    "identifier" : "1794F5C1-4901-45D7-B2C8-2AAFDF161AB4",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.watch-series7-1",
    "modelName" : "Apple Watch Series 7 - 45mm",
    "name" : "Apple Watch Series 7 - 45mm"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone10,5",
    "identifier" : "E4F85B31-09E5-430E-A31C-4302DA03A281",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-8-plus-2",
    "modelName" : "iPhone 8 Plus",
    "name" : "iPhone 8 Plus"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,5",
    "identifier" : "91D351F9-0432-4D29-85BF-317B30D3C8C8",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-13-1",
    "modelName" : "iPhone 13",
    "name" : "iPhone 13"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19L439)",
    "available" : true,
    "platform" : "com.apple.platform.appletvsimulator",
    "modelCode" : "AppleTV5,3",
    "identifier" : "BA24DF85-686E-4B6E-A8E9-F0128834A33F",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.apple-tv-4",
    "modelName" : "Apple TV",
    "name" : "Apple TV"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad13,5",
    "identifier" : "BC53B6C6-F7F3-4E2F-9B78-F6D6EA96B0C4",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-pro-11-3rd-1",
    "modelName" : "iPad Pro (11-inch) (3rd generation)",
    "name" : "iPad Pro (11-inch) (3rd generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad12,2",
    "identifier" : "F40D5350-EA1E-4769-BAC1-2F01FECEAB1C",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-9-wwan-1",
    "modelName" : "iPad (9th generation)",
    "name" : "iPad (9th generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone13,2",
    "identifier" : "86A75E23-AF17-4C20-B76F-E1B1B389311A",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-12-1",
    "modelName" : "iPhone 12",
    "name" : "iPhone 12"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,4",
    "identifier" : "64E2D17D-91FD-432A-B27A-88636C40003A",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-13-mini-1",
    "modelName" : "iPhone 13 mini",
    "name" : "iPhone 13 mini"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,2",
    "identifier" : "60256907-C7E1-4184-9328-488916AA8986",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-13-pro-1",
    "modelName" : "iPhone 13 Pro",
    "name" : "iPhone 13 Pro"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "8.5 (19T241)",
    "available" : true,
    "platform" : "com.apple.platform.watchsimulator",
    "companionDevice" : {
      "simulator" : true,
      "operatingSystemVersion" : "15.4 (19E240)",
      "available" : true,
      "platform" : "com.apple.platform.iphonesimulator",
      "modelCode" : "iPhone14,2",
      "identifier" : "60256907-C7E1-4184-9328-488916AA8986",
      "architecture" : "x86_64",
      "modelUTI" : "com.apple.iphone-13-pro-1",
      "modelName" : "iPhone 13 Pro",
      "name" : "iPhone 13 Pro"
    },
    "modelCode" : "Watch6,1",
    "identifier" : "F74601A7-54DC-4B30-BFDC-7DDA4B1B7335",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.watch-series6-1",
    "modelName" : "Apple Watch Series 6 - 40mm",
    "name" : "Apple Watch Series 6 - 40mm"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad13,17",
    "identifier" : "E6DC42D2-E5C0-4068-8403-DBC24B7EEB23",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-air5-1",
    "modelName" : "iPad Air (5th generation)",
    "name" : "iPad Air (5th generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone13,4",
    "identifier" : "7B12CAA7-D51E-4E95-9F0E-0E742538034E",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-12-pro-max-1",
    "modelName" : "iPhone 12 Pro Max",
    "name" : "iPhone 12 Pro Max"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone12,3",
    "identifier" : "F361E567-7A4C-4785-9539-30A1D3B5C8D6",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-11-pro-1",
    "modelName" : "iPhone 11 Pro",
    "name" : "iPhone 11 Pro"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "8.5 (19T241)",
    "available" : true,
    "platform" : "com.apple.platform.watchsimulator",
    "companionDevice" : {
      "simulator" : true,
      "operatingSystemVersion" : "15.4 (19E240)",
      "available" : true,
      "platform" : "com.apple.platform.iphonesimulator",
      "modelCode" : "iPhone13,4",
      "identifier" : "7B12CAA7-D51E-4E95-9F0E-0E742538034E",
      "architecture" : "x86_64",
      "modelUTI" : "com.apple.iphone-12-pro-max-1",
      "modelName" : "iPhone 12 Pro Max",
      "name" : "iPhone 12 Pro Max"
    },
    "modelCode" : "Watch5,4",
    "identifier" : "65F3F362-BCF1-4060-8620-E97F75E13C07",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.watch-series5-1",
    "modelName" : "Apple Watch Series 5 - 44mm",
    "name" : "Apple Watch Series 5 - 44mm"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad13,10",
    "identifier" : "4D361466-1365-44B4-A030-50339174EAE9",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-pro-12point9-5th-1",
    "modelName" : "iPad Pro (12.9-inch) (5th generation)",
    "name" : "iPad Pro (12.9-inch) (5th generation)"
  },
  {
    "modelCode" : "iPhone11,8",
    "simulator" : false,
    "modelName" : "iPhone XR",
    "error" : {
      "code" : -13,
      "failureReason" : "",
      "underlyingErrors" : [
        {
          "code" : 4,
          "failureReason" : "",
          "description" : "Flutter’s iPhone is locked.",
          "recoverySuggestion" : "To use Flutter’s iPhone with Xcode, unlock it.",
          "domain" : "DVTDeviceIneligibilityErrorDomain"
        }
      ],
      "description" : "Flutter’s iPhone is not connected",
      "recoverySuggestion" : "Xcode will continue when Flutter’s iPhone is connected.",
      "domain" : "com.apple.platform.iphoneos"
    },
    "operatingSystemVersion" : "15.4.1 (19E258)",
    "identifier" : "00008120-00017DA80CC1002E",
    "platform" : "com.apple.platform.iphoneos",
    "architecture" : "arm64e",
    "interface" : "usb",
    "available" : false,
    "name" : "Flutter’s iPhone",
    "modelUTI" : "com.apple.iphone-xr-9"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19L439)",
    "available" : true,
    "platform" : "com.apple.platform.appletvsimulator",
    "modelCode" : "AppleTV11,1",
    "identifier" : "58B32782-993B-449A-B610-B5116F76982A",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.apple-tv-4k-2nd",
    "modelName" : "Apple TV 4K (2nd generation)",
    "name" : "Apple TV 4K (2nd generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone13,3",
    "identifier" : "D70DFEA5-6205-4E79-B93F-D7FD306D355B",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-12-pro-1",
    "modelName" : "iPhone 12 Pro",
    "name" : "iPhone 12 Pro"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19L439)",
    "available" : true,
    "platform" : "com.apple.platform.appletvsimulator",
    "modelCode" : "AppleTV11,1",
    "identifier" : "953D73B7-BB7B-4403-90B3-6AB29401FBA4",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.apple-tv-4k-2nd",
    "modelName" : "Apple TV 4K (at 1080p) (2nd generation)",
    "name" : "Apple TV 4K (at 1080p) (2nd generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone13,1",
    "identifier" : "5F4F261E-3BEA-4531-96D5-0D29ECD421E7",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-12-mini-1",
    "modelName" : "iPhone 12 mini",
    "name" : "iPhone 12 mini"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.4 (19E240)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone12,1",
    "identifier" : "CD8F89ED-29BF-492C-8779-93C66E9E9E25",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-11-1",
    "modelName" : "iPhone 11",
    "name" : "iPhone 11"
  }
]''';

const String _jsonWithErrors = '''
[
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone12,5",
    "identifier" : "CB6911EC-B6CF-40FB-A422-F2557F21B6FD",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-11-pro-max-1",
    "modelName" : "iPhone 11 Pro Max",
    "name" : "iPhone 11 Pro Max"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone10,4",
    "identifier" : "1A89CB25-1DF3-4E44-95C8-A83ED65C8EAE",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-8-2",
    "modelName" : "iPhone 8",
    "name" : "iPhone 8"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,2",
    "identifier" : "0D287CD5-8F3B-4744-9153-CF65734ED54B",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-13-pro-1",
    "modelName" : "iPhone 13 Pro",
    "name" : "iPhone 13 Pro"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone12,3",
    "identifier" : "20072059-49CA-453E-8814-571BC6A10771",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-11-pro-1",
    "modelName" : "iPhone 11 Pro",
    "name" : "iPhone 11 Pro"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad13,5",
    "identifier" : "A453F8FF-8FE3-4ABA-B822-2DD1EAD78D57",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-pro-11-3rd-1",
    "modelName" : "iPad Pro (11-inch) (3rd generation)",
    "name" : "iPad Pro (11-inch) (3rd generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone13,1",
    "identifier" : "CB5C8261-9B24-467F-A684-1E56525D2863",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-12-mini-1",
    "modelName" : "iPhone 12 mini",
    "name" : "iPhone 12 mini"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPod9,1",
    "identifier" : "930C194B-19D0-47A0-ADFB-0D366B4226B2",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipod-touch-7-2",
    "modelName" : "iPod touch (7th generation)",
    "name" : "iPod touch (7th generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone12,1",
    "identifier" : "BFF8A2B0-F7F7-440D-A9C3-707C28B38258",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-11-1",
    "modelName" : "iPhone 11",
    "name" : "iPhone 11"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,4",
    "identifier" : "627F97FB-16BF-4669-B74A-44672E594CAA",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-13-mini-1",
    "modelName" : "iPhone 13 mini",
    "name" : "iPhone 13 mini"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,3",
    "identifier" : "1F351966-28B0-41A5-925A-204EBA04B6B4",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-13-pro-max-1",
    "modelName" : "iPhone 13 Pro Max",
    "name" : "iPhone 13 Pro Max"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone14,5",
    "identifier" : "3274DBB4-2AD3-444F-8A86-B8B2F4FBD7DA",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-13-1",
    "modelName" : "iPhone 13",
    "name" : "iPhone 13"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad6,4",
    "identifier" : "A8164C13-0B78-4407-B9AB-663D6C3CA87F",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-pro-9point7-a1674-b9b7ba",
    "modelName" : "iPad Pro (9.7-inch)",
    "name" : "iPad Pro (9.7-inch)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad13,2",
    "identifier" : "35EF8EEC-4E8D-4CFE-9D85-B646EF84E964",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-air4-1",
    "modelName" : "iPad Air (4th generation)",
    "name" : "iPad Air (4th generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone12,8",
    "identifier" : "8AF89624-D3EB-4968-899D-533AA4BC28C6",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-se-1",
    "modelName" : "iPhone SE (2nd generation)",
    "name" : "iPhone SE (2nd generation)"
  },
  {
    "modelCode" : "iPhone8,1",
    "simulator" : false,
    "modelName" : "iPhone 6s",
    "error" : {
      "code" : -10,
      "failureReason" : "",
      "description" : "iPhone is busy: Fetching debug symbols for iPhone",
      "recoverySuggestion" : "Xcode will continue when iPhone is finished.",
      "domain" : "com.apple.platform.iphoneos"
    },
    "operatingSystemVersion" : "15.1 (19B74)",
    "identifier" : "e3f3a0cf8005b8b34f14d16fa224b19017648353",
    "platform" : "com.apple.platform.iphoneos",
    "architecture" : "arm64",
    "interface" : "usb",
    "available" : false,
    "name" : "iPhone",
    "modelUTI" : "com.apple.iphone-6s-e1ccb7"
  },
  {
    "simulator" : false,
    "operatingSystemVersion" : "12.0.1 (21A559)",
    "interface" : "usb",
    "available" : true,
    "platform" : "com.apple.platform.macosx",
    "modelCode" : "Macmini8,1",
    "identifier" : "4AB5455B-6B1E-5FC2-A7FF-5F00B80210AA",
    "architecture" : "x86_64h",
    "modelUTI" : "com.apple.macmini-2018",
    "modelName" : "Mac mini",
    "name" : "My Mac"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad13,10",
    "identifier" : "E48194A0-497A-4DAA-922D-9F9227B6559A",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-pro-12point9-5th-1",
    "modelName" : "iPad Pro (12.9-inch) (5th generation)",
    "name" : "iPad Pro (12.9-inch) (5th generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone13,2",
    "identifier" : "7D576202-5E4D-4579-B802-09312B98A2CE",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-12-1",
    "modelName" : "iPhone 12",
    "name" : "iPhone 12"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone13,3",
    "identifier" : "3DCDF8F6-5B02-4D2D-A077-45BF8697C91A",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-12-pro-1",
    "modelName" : "iPhone 12 Pro",
    "name" : "iPhone 12 Pro"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad12,2",
    "identifier" : "D2B77A25-DDE9-4C4C-8EFC-175B5D05704F",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-9-wwan-1",
    "modelName" : "iPad (9th generation)",
    "name" : "iPad (9th generation)"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone13,4",
    "identifier" : "24FADBDC-395A-40CB-94AC-0D00CC3107B4",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-12-pro-max-1",
    "modelName" : "iPhone 12 Pro Max",
    "name" : "iPhone 12 Pro Max"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPhone10,5",
    "identifier" : "FDCF8239-0A14-4402-AE84-0B52C743826E",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.iphone-8-plus-2",
    "modelName" : "iPhone 8 Plus",
    "name" : "iPhone 8 Plus"
  },
  {
    "simulator" : true,
    "operatingSystemVersion" : "15.0 (19A339)",
    "available" : true,
    "platform" : "com.apple.platform.iphonesimulator",
    "modelCode" : "iPad14,1",
    "identifier" : "FB078A84-48E1-4AD9-AAE3-070019F65AB4",
    "architecture" : "x86_64",
    "modelUTI" : "com.apple.ipad-mini6-1",
    "modelName" : "iPad mini (6th generation)",
    "name" : "iPad mini (6th generation)"
  }
]
''';
