FROM cirrusci/flutter:latest-web

RUN sudo apt-get update -y
RUN sudo apt-get upgrade -y

# Add repo for chrome stable
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list

# Install the rest of the dependencies.
RUN sudo apt-get update -y
RUN sudo apt-get install -y --no-install-recommends google-chrome-stable