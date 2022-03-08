#!/bin/bash
for i in {1..100}; do dart test test/service/luci_build_service_test.dart --test-randomize-ordering-seed=random; done
