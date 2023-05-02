# Copyright 2022 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# Dart Docker official images can be found here: https://hub.docker.com/_/dart
FROM dart:beta@sha256:49e9c13a343ebddece7aba895b36e2664090600446438515a5540012c86fdd1c

WORKDIR /app

# Copy app source code (except anything in .dockerignore).
COPY . .
RUN dart pub get

# Start server.
EXPOSE 8080
CMD ["/usr/lib/dart/bin/dart", "/app/bin/server.dart"]
