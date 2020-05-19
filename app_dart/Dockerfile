################################################################################
#  Copyright (c) 2016 The Flutter Authors. All rights reserved.
#  Use of this source code is governed by a BSD-style license that can be
#  found in the LICENSE file.
################################################################################

# The VM service listens on port 8181

FROM google/dart-runtime

################################################################################
# For local development & testing, you need to create a service account
# and download a key JSON file to your local workstation by going to
# the Cloud Console at:
#
#   IAM & admin > Service accounts > Actions > Create key
#
# https://pub.dev/packages/appengine#creation-service-account
#
# Once that's done, and you have a `key.json` file located at
# `/path/to/key.json`, then un-comment the following lines:
################################################################################
#ADD key.json /path/to/key.json
#ENV GCLOUD_KEY /path/to/key.json
#ENV GCLOUD_PROJECT tvolkert-test


################################################################################
# Uncomment these lines to enable the Dart debugger on port 5858
################################################################################
#ENV DBG_ENABLE true
#ENV GAE_PARTITION dev


################################################################################
# Uncomment this (and modify the options as needed) to pass options to the
# Dart VM.
################################################################################
#ENV DART_VM_OPTIONS -DSILENT_OBSERVATORY=true
