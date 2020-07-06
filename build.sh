#!/bin/bash

cd app && flutter pub run build_runner build --release --output build --delete-conflicting-outputs
