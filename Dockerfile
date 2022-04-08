# Copyright 2022 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Flutter (https://flutter.io) Developement Environment for Linux
# ===============================================================
#
# This environment passes all Linux Flutter Doctor checks and is sufficient
# for building Android applications and running Flutter tests.
#
# To build iOS applications, a Mac development environment is necessary.
#

FROM debian:bullseye-slim@sha256:82da53aa627b9d5032a1e57903356b8f34d613a5bc1e07ae5e9149bd88fa3128

# Install Dependencies.
RUN apt update -y
RUN apt install -y \
  curl \
  git \
  unzip
  
# Install Flutter.
ENV FLUTTER_ROOT="/opt/flutter"
RUN git clone https://github.com/flutter/flutter "${FLUTTER_ROOT}"
ENV PATH="${FLUTTER_ROOT}/bin:${PATH}"

# Switch to master channel
RUN flutter channel master

# Disable analytics and crash reporting on the builder.
RUN flutter config  --no-analytics

# Perform an artifact precache so that no extra assets need to be downloaded on demand.
RUN flutter precache

# Perform a doctor run.
RUN flutter doctor -v

# Perform a flutter upgrade
RUN flutter upgrade

ENTRYPOINT [ "flutter" ]
