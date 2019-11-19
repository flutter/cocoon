// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class Downloader {
  Future<bool> download(String href, String fileName, String idToken);
}
