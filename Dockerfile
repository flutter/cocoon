# Flutter (https://flutter.dev) Development Environment for Linux
# ===============================================================
#
# This environment passes all Linux Flutter Doctor checks and is sufficient
# for building Android applications and running Flutter tests.
#
# To build iOS applications, a Mac development environment is necessary.
#
# This includes applications and sdks that are needed only by the CI system
# for performing pushes to production, and so this image is quite a bit larger
# than strictly needed for just building Flutter apps.

# Note: updating past stretch (Debian 9) will bump Java past version 8,
# which will break the Android SDK.
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

# Add nodejs repository to apt sources and install it.
ENV NODEJS_INSTALL="/opt/nodejs_install"
RUN mkdir -p "${NODEJS_INSTALL}"
RUN wget -q https://deb.nodesource.com/setup_10.x -O "${NODEJS_INSTALL}/nodejs_install.sh"
RUN bash "${NODEJS_INSTALL}/nodejs_install.sh"

# Install the rest of the dependencies.
RUN apt-get install -y --no-install-recommends \
  locales \
  gcc \
  ruby \
  ruby-dev \
  nodejs \
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

# Setup gradle
ENV GRADLE_ROOT="/opt/gradle"
RUN mkdir -p "${GRADLE_ROOT}"
ENV GRADLE_ARCHIVE="${GRADLE_ROOT}/gradle.zip"
ENV GRADLE_URL="http://services.gradle.org/distributions/gradle-4.4-bin.zip"
RUN wget --progress=dot:giga "$GRADLE_URL" -O "${GRADLE_ARCHIVE}"
RUN unzip -q -d "${GRADLE_ROOT}" "${GRADLE_ARCHIVE}"
ENV PATH="$GRADLE_ROOT/bin:$PATH"

# Set locale to en_US
RUN locale-gen en_US "en_US.UTF-8" && dpkg-reconfigure locales
ENV LANG en_US.UTF-8

# Skip all the documentation (-N) since it's just on CI.
RUN gem install bundler -N

COPY Gemfile /Gemfile
COPY Gemfile.lock /Gemfile.lock

RUN bundle install --system