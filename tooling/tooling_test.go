// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used so that slsa-verifier can be updated by dependabot.
// Additional context can be found at:
// https://github.com/slsa-framework/slsa-verifier#option-1-install-via-go

//go:build tools
// +build tools

package main

import (
	_ "github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier"
)
