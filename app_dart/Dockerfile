FROM google/dart-runtime

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
ADD key.json /Users/tvolkert/project/flutter/cocoon/app_dart/key.json
ENV GCLOUD_KEY /Users/tvolkert/project/flutter/cocoon/app_dart/key.json
ENV GCLOUD_PROJECT tvolkert-test
