#!/bin/bash
for i in {1..100}; do flutter test --test-randomize-ordering-seed=random test/widgets/task_overlay_test.dart || break; done
