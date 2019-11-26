# Flutter (https://flutter.dev) for Linux
# ===============================================================
#
# This environment passes all Linux Flutter Doctor checks and is sufficient
# for building Android and Web applications and running Flutter tests.
#
# Note: This is based on the Docker image for https://github.com/flutter/flutter
FROM debian:stretch
MAINTAINER Flutter Developers <flutter-dev@googlegroups.com>

RUN apt-get update -y
RUN apt-get upgrade -y

# Install basics
RUN apt-get install -y --no-install-recommends \
  git \
  wget \
  curl \
  zip \
  unzip \
  apt-transport-https \
  ca-certificates \
  gnupg

# Add repo for chrome stable
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list

# Install the rest of the dependencies.
RUN apt-get install -y --no-install-recommends \
  locales \
  gcc \
  lib32stdc++6 \
  libstdc++6 \
  libglu1-mesa \
  build-essential \
  default-jdk-headless \
  google-chrome-stable

# Install the Android SDK Dependency.
ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip"
ENV ANDROID_TOOLS_ROOT="/opt/android_sdk"
RUN mkdir -p "${ANDROID_TOOLS_ROOT}"
RUN mkdir -p ~/.android
# Silence warning.
RUN touch ~/.android/repositories.cfg
ENV ANDROID_SDK_ARCHIVE="${ANDROID_TOOLS_ROOT}/archive"
RUN wget --progress=dot:giga "${ANDROID_SDK_URL}" -O "${ANDROID_SDK_ARCHIVE}"
RUN unzip -q -d "${ANDROID_TOOLS_ROOT}" "${ANDROID_SDK_ARCHIVE}"
# Suppressing output of sdkmanager to keep log size down
# (it prints install progress WAY too often).
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "tools" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "build-tools;28.0.3" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "platforms;android-28" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "platform-tools" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "extras;android;m2repository" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "extras;google;m2repository" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "patcher;v4" > /dev/null
RUN rm "${ANDROID_SDK_ARCHIVE}"
ENV PATH="${ANDROID_TOOLS_ROOT}/tools:${PATH}"
ENV PATH="${ANDROID_TOOLS_ROOT}/tools/bin:${PATH}"
# Silence warnings when accepting android licenses.
RUN mkdir -p ~/.android
RUN touch ~/.android/repositories.cfg

# Set locale to en_US
RUN locale-gen en_US "en_US.UTF-8" && dpkg-reconfigure locales
ENV LANG en_US.UTF-8

# Install Flutter
RUN wget https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_v1.9.1+hotfix.6-stable.tar.xz
RUN tar xf flutter_linux_v1.9.1+hotfix.6-stable.tar.xz -C /usr/bin/
ENV PATH="/usr/bin/flutter/bin:$PATH"