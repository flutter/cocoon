# Copyright 2022 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# Dart Docker official images can be found here: https://hub.docker.com/_/dart
FROM dart:beta@sha256:8e874099070282e3bb56f7d14c1d79ddf9df7c5776b9fdb6e1c5c6dffc1c7b43

WORKDIR /app

# Copy app source code (except anything in .dockerignore).
COPY . .
RUN dart pub get

# Start server.
EXPOSE 8080
CMD ["/usr/lib/dart/bin/dart", "/app/bin/server.dart"]
