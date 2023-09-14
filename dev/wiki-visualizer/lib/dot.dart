// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String dotIdentifier(final String name) {
  // TODO(ianh): properly escape strings for dot syntax
  assert(!name.contains('"'), 'dotIdentifier does not yet implement proper escaping of quotes');
  return '"$name"';
}
