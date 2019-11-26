FROM cirrusci/flutter:latest-web

RUN sudo apt-get update \
    && sudo apt-get install -y chromium-browser \
    && sudo rm -rf /var/lib/apt/lists/*