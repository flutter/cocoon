import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/validations/validation_filter.dart';

class FakeValidationFilter implements ValidationFilter {
  final Set<Validation> validations = {};

  void registerValidation(Validation newValidation) {
    validations.add(newValidation);
  }

  @override
  Set<Validation> getValidations() {
    return validations;
  }
}
