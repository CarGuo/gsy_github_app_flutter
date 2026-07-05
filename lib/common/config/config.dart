class Config {
  // Private constructor to prevent instantiation
  Config._();

  static bool? DEBUG = true;

  static const PAGE_SIZE = 20;

  /// //////////////////////////////////////常量////////////////////////////////////// ///
  static const API_TOKEN = "4d65e2a5626103f92a71867d7b49fea0";
  static const TOKEN_KEY = "token";
  static const USER_NAME_KEY = "user-name";
  static const PW_KEY = "user-pw";
  static const USER_BASIC_CODE = "user-basic-code";
  static const USER_INFO = "user-info";
  static const LANGUAGE_SELECT = "language-select";
  static const LANGUAGE_SELECT_NAME = "language-select-name";
  static const REFRESH_LANGUAGE = "refreshLanguageApp";
  static const THEME_COLOR = "theme-color";
  static const LOCALE = "locale";
  static const VIBRATION_ENABLE = "vibration-enable";

  /// 搜索历史（JSON 编码的 `List<String>`）
  static const SEARCH_HISTORY_KEY = "search-history";

  /// 搜索历史最大保留条数
  static const SEARCH_HISTORY_MAX = 10;
}
