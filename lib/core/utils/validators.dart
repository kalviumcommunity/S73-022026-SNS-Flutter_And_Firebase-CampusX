/// Comprehensive validation utilities for the app
class Validators {
  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  /// Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    return null;
  }

  /// Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  /// Date validation - must be in the future
  static String? validateFutureDate(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    final now = DateTime.now();
    // Compare only dates, ignore time
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(value.year, value.month, value.day);

    if (selectedDate.isBefore(today)) {
      return '$fieldName must be in the future';
    }

    return null;
  }

  /// Date validation - must be today or in the future
  static String? validateTodayOrFutureDate(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(value.year, value.month, value.day);

    if (selectedDate.isBefore(today)) {
      return '$fieldName cannot be in the past';
    }

    return null;
  }

  /// DateTime validation - must be in the future (includes time)
  static String? validateFutureDateTime(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    final now = DateTime.now();
    
    if (value.isBefore(now)) {
      return '$fieldName must be in the future';
    }

    return null;
  }

  /// Capacity validation - must be a positive number
  static String? validateCapacity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Capacity is required';
    }

    final capacity = int.tryParse(value);
    
    if (capacity == null) {
      return 'Capacity must be a valid number';
    }

    if (capacity <= 0) {
      return 'Capacity must be greater than 0';
    }

    if (capacity > 10000) {
      return 'Capacity cannot exceed 10,000';
    }

    return null;
  }

  /// Positive integer validation
  static String? validatePositiveInteger(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value);
    
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  /// Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Check if it's a valid length (10 digits for most countries)
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number (10-15 digits)';
    }

    return null;
  }

  /// URL validation
  static String? validateUrl(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'URL is required' : null;
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Bio/Description validation with character limit
  static String? validateBio(String? value, {int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return null; // Bio is optional
    }

    if (value.length > maxLength) {
      return 'Bio cannot exceed $maxLength characters';
    }

    return null;
  }

  /// Text length validation
  static String? validateLength(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    if (minLength != null && value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    return null;
  }

  /// Time validation - must be in the future
  static String? validateFutureTime(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    final now = DateTime.now();
    
    if (value.isBefore(now)) {
      return '$fieldName must be in the future';
    }

    // Check if it's too far in the future (e.g., more than 2 years)
    final twoYearsFromNow = now.add(const Duration(days: 730));
    if (value.isAfter(twoYearsFromNow)) {
      return '$fieldName cannot be more than 2 years in the future';
    }

    return null;
  }

  /// Validate that end date is after start date
  static String? validateDateRange(
    DateTime? startDate,
    DateTime? endDate,
    String fieldName,
  ) {
    if (endDate == null) {
      return '$fieldName is required';
    }

    if (startDate != null && endDate.isBefore(startDate)) {
      return '$fieldName must be after the start date';
    }

    return null;
  }

  /// Validate event capacity against current registrations
  static String? validateCapacityUpdate(
    String? value,
    int currentRegistrations,
  ) {
    if (value == null || value.isEmpty) {
      return 'Capacity is required';
    }

    final capacity = int.tryParse(value);
    
    if (capacity == null) {
      return 'Capacity must be a valid number';
    }

    if (capacity <= 0) {
      return 'Capacity must be greater than 0';
    }

    if (capacity < currentRegistrations) {
      return 'Capacity cannot be less than current registrations ($currentRegistrations)';
    }

    return null;
  }

  /// Validate interview schedule (at least 24 hours in advance)
  static String? validateInterviewSchedule(DateTime? value) {
    if (value == null) {
      return 'Interview date and time is required';
    }

    final now = DateTime.now();
    
    if (value.isBefore(now)) {
      return 'Interview cannot be scheduled in the past';
    }

    // Recommend scheduling at least 24 hours in advance
    final minAdvanceTime = now.add(const Duration(hours: 1));
    if (value.isBefore(minAdvanceTime)) {
      return 'Please schedule at least 1 hour in advance';
    }

    return null;
  }

  /// Validate registration deadline (must be before event date)
  static String? validateRegistrationDeadline(
    DateTime? deadline,
    DateTime? eventDate,
  ) {
    if (deadline == null) {
      return null; // Deadline is optional
    }

    if (eventDate != null && deadline.isAfter(eventDate)) {
      return 'Registration deadline must be before event date';
    }

    final now = DateTime.now();
    if (deadline.isBefore(now)) {
      return 'Registration deadline cannot be in the past';
    }

    return null;
  }
}
