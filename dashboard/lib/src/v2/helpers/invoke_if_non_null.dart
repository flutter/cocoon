// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Wraps a possible null function [invoke] to be called if [T] is non-null.
///
/// If [invoke] is `null`, returns `null`.
///
/// Otherwise the returned function accepts a _nullable_ [T] (`T?`), and if the
/// value provided is non-null (at runtime), [invoke] is called, otherwise it is
/// not called.
///
/// Provides an easy reusable pattern for most selection widget implementations:
/// ```dart
/// final class MySelectWidget extends StatelessWidget {
///   const MySelectWidget({this.onSelected});
///
///   final void Function(String)? onSelected;
///
///   @override
///   Widget build(BuildContext context) {
///     return DropdownMenu(
///       // ...
///       onSelected: _invokeIfNonNull(onSelected),
///     );
///   }
/// }
/// ```
void Function(T?)? invokeIfNonNull<T>(void Function(T)? invoke) {
  if (invoke == null) {
    return null;
  }
  return (v) {
    if (v != null) {
      invoke(v);
    }
  };
}

/// Wraps a possible null function [invoke] to be called with [item].
///
/// If [invoke] is `null`, returns `null`.
///
/// Otherwise the returned function is a void callback that invokes [invoke].
///
/// Provides an easy reusable pattern for custom selection widgets:
/// ```dart
/// itemBuilder: (_, index) {
///   final item = _options[index];
///   return ListTile(
///     onTap: invokeWithItem(item, widget.onSelect),
///   );
/// }
/// ```
void Function()? invokeWithItem<T>(T item, void Function(T)? invoke) {
  if (invoke == null) {
    return null;
  }
  return () => invoke(item);
}
