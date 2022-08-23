// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Enum to tell the auto-submit bot which action to take based on the label
/// found.
enum ProcessMethod {
  processAutosubmit,
  processRevert,
  doNotProcess,
}
