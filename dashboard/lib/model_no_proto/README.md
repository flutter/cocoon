# Frontend Data Models

This directory contains a feature-compatible (but not API) variant of the
frontend data models in the [`lib/model`](../model/) directory. In order to
fix several design problems with the previous iteration, these models:

1. Are _deeply_ immutable (using `@immutable`, and unmodifiable collections)
1. Do not expose directly what backend store they were originally from
1. Use `@JsonSerializable` to define a mapping from JSON-based RPCs
