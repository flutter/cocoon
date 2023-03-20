//go:build tools
// +build tools

package main

// This is used so that slsa-verifier can be automatically updated by dependabot
// or any other dependency update tool. Additional context can be found at:
// https://github.com/slsa-framework/slsa-verifier#option-1-install-via-go
import (
	_ "github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier"
)
