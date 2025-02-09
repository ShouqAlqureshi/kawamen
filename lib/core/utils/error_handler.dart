class ErrorHandler {
  static String handleException(dynamic error) {
    if (error is Exception) {
      return error.toString();
    } else {
      return "An unknown error occurred";
    }
  }
}
