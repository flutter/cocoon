import 'package:logging/logging.dart';

class TestLogger implements Logger {
  @override
  final String name = 'test-logger';

  @override
  String get fullName => name;

  @override
  void clearListeners() => throw UnimplementedError('Unimplemented!');

  @override
  bool isLoggable(Level value) => throw UnimplementedError('Unimplemented!');

  @override
  Level get level => throw UnimplementedError('Unimplemented!');

  @override
  set level(Level? value) => throw UnimplementedError('Unimplemented!');

  @override
  Stream<LogRecord> get onRecord => throw UnimplementedError('Unimplemented!');

  @override
  final Logger? parent = null;

  @override
  final Map<String, Logger> children = const <String, Logger>{};

  final Map<Level, List<String>> logs = <Level, List<String>>{};

  @override
  void log(Level logLevel, Object? message, [Object? error, StackTrace? stackTrace, dynamic zone]) {
    logs[logLevel] ??= <String>[];
    logs[logLevel]!.add(message.toString());
  }

  @override
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINEST, message, error, stackTrace);

  @override
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) => log(Level.FINER, message, error, stackTrace);

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) => log(Level.FINE, message, error, stackTrace);

  @override
  void config(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.CONFIG, message, error, stackTrace);

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) => log(Level.INFO, message, error, stackTrace);

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.WARNING, message, error, stackTrace);

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SEVERE, message, error, stackTrace);

  @override
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) => log(Level.SHOUT, message, error, stackTrace);
}
