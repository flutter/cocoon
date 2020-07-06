#!/bin/bash

cd app 
flutter pub get
flutter pub run build_runner build --release --output build --delete-conflicting-outputs
