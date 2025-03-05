// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

typedef BrookCallback<T> = void Function(T event);

/// A source of events of type T.
///
/// This is a light-weight stream, hence the name of the class.
///
/// Listeners cannot be registered multiple times simultaneously.
class Brook<T> {
  Brook();

  final Set<BrookCallback<T>> _listeners = <BrookCallback<T>>{};

  void addListener(BrookCallback<T> listener) {
    assert(!_listeners.contains(listener));
    _listeners.add(listener);
  }

  void removeListener(BrookCallback<T> listener) {
    assert(_listeners.contains(listener));
    _listeners.remove(listener);
  }
}

/// A place to send events of type T.
///
/// Instances of this class can be given to consumers, as the type [Brook].
/// This allows consumers to register for events without being able to send
/// events.
class BrookSink<T> extends Brook<T> {
  BrookSink();

  void send(T event) {
    final frozenListeners = _listeners.toList();
    for (final listener in frozenListeners) {
      try {
        if (_listeners.contains(listener)) {
          listener(event);
        }
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'Flutter Dashboard',
            context: ErrorDescription('while sending event'),
            informationCollector: () sync* {
              yield DiagnosticsProperty<BrookSink<T>>(
                'The $runtimeType sending the event was',
                this,
                style: DiagnosticsTreeStyle.errorProperty,
              );
              yield DiagnosticsProperty<T>(
                'The $T event was',
                event,
                style: DiagnosticsTreeStyle.errorProperty,
              );
            },
          ),
        );
      }
    }
  }
}

class ErrorSink extends BrookSink<String> {
  ErrorSink();

  @override
  void send(String event) {
    // TODO(ianh): log errors to a service as well, https://github.com/flutter/flutter/issues/52697
    debugPrint(event); // to allow for copy/paste
    super.send(event);
  }
}
