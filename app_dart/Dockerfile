# Copyright 2022 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# Dart Docker official images can be found here: https://hub.docker.com/_/dart
FROM dart:beta@sha256:17d83a179e10ec76698b9580f6d367e13957fcd32135e9b265039b553e8547e6

WORKDIR /app

# Copy app source code (except anything in .dockerignore).
COPY . .
RUN dart pub get

# Start server.
EXPOSE 8080
CMD ["/usr/lib/dart/bin/dart", "/app/bin/gae_server.dart"]
