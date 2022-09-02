class BigQueryException implements Exception {
  BigQueryException(this.cause);
  final String cause;
}
