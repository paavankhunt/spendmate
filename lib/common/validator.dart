bool validateEmail(String email) {
  // Regular expression for email validation
  final RegExp emailRegex = RegExp(
    r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$',
  );

  // Check if the email matches the regular expression
  if (!emailRegex.hasMatch(email)) {
    return false;
  }

  return true;
}
