class ApiEndPoints {
  ApiEndPoints._();

  static const String baseUrl =
      "https://sequences-diana-wholesale-adds.trycloudflare.com/api/v1/";

  // Auth Endpoints
  static const String login = "auth/login";
  static const String loginWithPin = "auth/login/pin";
  static const String logout = "auth/logout";
  static const String refreshToken = "auth/refresh";
  static const String profile = "auth/profile";
}
