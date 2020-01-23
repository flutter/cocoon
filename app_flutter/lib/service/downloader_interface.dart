// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Utility service for agnostically downloading files locally onto a device.
class Downloader {
  Future<bool> download(String href, String fileName) async =>
      throw Exception('Download not implemented for this platform');
}
