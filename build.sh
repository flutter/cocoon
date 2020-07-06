#!/bin/bash

cd app && pub run build_runner build --release --output build --delete-conflicting-outputs
