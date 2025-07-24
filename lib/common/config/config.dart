/// Configuration constants for the application
class Config {
  // Private constructor to prevent instantiation
  Config._();

  static const bool DEBUG = true;
  static const int PAGE_SIZE = 20;

  /// API and authentication constants
  static const String API_TOKEN = "4d65e2a5626103f92a71867d7b49fea0";
  static const String TOKEN_KEY = "token";
  static const String USER_NAME_KEY = "user-name";
  static const String PW_KEY = "user-pw";
  static const String USER_BASIC_CODE = "user-basic-code";
  static const String USER_INFO = "user-info";
  
  /// Localization constants
  static const String LANGUAGE_SELECT = "language-select";
  static const String LANGUAGE_SELECT_NAME = "language-select-name";
  static const String REFRESH_LANGUAGE = "refreshLanguageApp";
  static const String LOCALE = "locale";
  
  /// Theme constants
  static const String THEME_COLOR = "theme-color";
}
