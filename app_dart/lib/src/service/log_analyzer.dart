// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';

/// Interface for analyzing logs.
abstract class LogAnalyzer {
  Future<String> analyze({required String prompt});
}

/// Implementation of [LogAnalyzer] using Genkit.
class GenkitLogAnalyzer implements LogAnalyzer {
  GenkitLogAnalyzer(this.ai, {required this.modelName});

  final Genkit ai;
  final String modelName;

  @override
  Future<String> analyze({required String prompt}) async {
    final response = await ai.generate<dynamic, String>(
      model: googleAI.gemini(modelName),
      prompt: prompt,
    );
    return response.text;
  }
}

/// Fake implementation of [LogAnalyzer] for tests and local server.
class FakeLogAnalyzer implements LogAnalyzer {
  FakeLogAnalyzer([this.reply = 'Fake analysis result']);

  final String reply;

  @override
  Future<String> analyze({required String prompt}) async {
    return reply;
  }
}
