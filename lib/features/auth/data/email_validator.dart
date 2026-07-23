class EmailValidator {
  static const String invalidMessage = 'Enter a valid email';

  static final RegExp _localPartPattern = RegExp(
    r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+$",
  );
  static final RegExp _domainLabelPattern = RegExp(
    r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
  );

  static String normalize(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  static String? validate(String? value, {required String emptyMessage}) {
    final email = normalize(value);

    if (email.isEmpty) {
      return emptyMessage;
    }

    if (email.length > 254 || RegExp(r'\s').hasMatch(email)) {
      return invalidMessage;
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return invalidMessage;
    }

    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.isEmpty ||
        domain.isEmpty ||
        localPart.length > 64 ||
        domain.length > 253 ||
        localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..') ||
        !_localPartPattern.hasMatch(localPart)) {
      return invalidMessage;
    }

    final labels = domain.split('.');
    final topLevelDomain = labels.last;
    if (labels.length < 2 ||
        topLevelDomain.length < 2 ||
        labels.any((label) => !_domainLabelPattern.hasMatch(label))) {
      return invalidMessage;
    }

    return null;
  }
}
