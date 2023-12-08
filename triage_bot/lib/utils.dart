// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');

String s(int n) => n == 1 ? '' : 's';
