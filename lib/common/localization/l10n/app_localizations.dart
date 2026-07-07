import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome To Flutter'**
  String get welcomeMessage;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'GSYGithubApp'**
  String get app_name;

  /// No description provided for @app_ok.
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get app_ok;

  /// No description provided for @app_cancel.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get app_cancel;

  /// No description provided for @app_empty.
  ///
  /// In en, this message translates to:
  /// **'Empty(oﾟ▽ﾟ)o'**
  String get app_empty;

  /// No description provided for @app_licenses.
  ///
  /// In en, this message translates to:
  /// **'licenses'**
  String get app_licenses;

  /// No description provided for @app_close.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get app_close;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'version'**
  String get app_version;

  /// No description provided for @app_back_tip.
  ///
  /// In en, this message translates to:
  /// **'Exit？'**
  String get app_back_tip;

  /// No description provided for @app_not_new_version.
  ///
  /// In en, this message translates to:
  /// **'No new version.'**
  String get app_not_new_version;

  /// No description provided for @app_version_title.
  ///
  /// In en, this message translates to:
  /// **'Update Version'**
  String get app_version_title;

  /// No description provided for @nothing_now.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get nothing_now;

  /// No description provided for @loading_text.
  ///
  /// In en, this message translates to:
  /// **'Loading···'**
  String get loading_text;

  /// No description provided for @option_web.
  ///
  /// In en, this message translates to:
  /// **'browser'**
  String get option_web;

  /// No description provided for @option_copy.
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get option_copy;

  /// No description provided for @option_share.
  ///
  /// In en, this message translates to:
  /// **'share'**
  String get option_share;

  /// No description provided for @option_web_launcher_error.
  ///
  /// In en, this message translates to:
  /// **'url error'**
  String get option_web_launcher_error;

  /// No description provided for @option_share_title.
  ///
  /// In en, this message translates to:
  /// **'share form GSYGitHubFlutter： '**
  String get option_share_title;

  /// No description provided for @option_share_copy_success.
  ///
  /// In en, this message translates to:
  /// **'Copy Success'**
  String get option_share_copy_success;

  /// No description provided for @login_text.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_text;

  /// No description provided for @oauth_text.
  ///
  /// In en, this message translates to:
  /// **'OAuth'**
  String get oauth_text;

  /// No description provided for @login_out.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get login_out;

  /// No description provided for @login_deprecated.
  ///
  /// In en, this message translates to:
  /// **'The API via password authentication will remove on November 13, 2020 by Github'**
  String get login_deprecated;

  /// No description provided for @home_reply.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get home_reply;

  /// No description provided for @home_change_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get home_change_language;

  /// No description provided for @home_vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get home_vibration;

  /// No description provided for @home_change_grey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get home_change_grey;

  /// No description provided for @home_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get home_about;

  /// No description provided for @home_check_update.
  ///
  /// In en, this message translates to:
  /// **'Check Update'**
  String get home_check_update;

  /// No description provided for @home_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get home_history;

  /// No description provided for @home_user_info.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get home_user_info;

  /// No description provided for @home_change_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get home_change_theme;

  /// No description provided for @home_language_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get home_language_default;

  /// No description provided for @home_language_zh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get home_language_zh;

  /// No description provided for @home_language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get home_language_en;

  /// No description provided for @home_language_ko.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get home_language_ko;

  /// No description provided for @home_language_ja.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get home_language_ja;

  /// No description provided for @switch_language.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get switch_language;

  /// No description provided for @home_theme_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get home_theme_default;

  /// No description provided for @home_theme_1.
  ///
  /// In en, this message translates to:
  /// **'Theme 1'**
  String get home_theme_1;

  /// No description provided for @home_theme_2.
  ///
  /// In en, this message translates to:
  /// **'Theme 2'**
  String get home_theme_2;

  /// No description provided for @home_theme_3.
  ///
  /// In en, this message translates to:
  /// **'Theme 3'**
  String get home_theme_3;

  /// No description provided for @home_theme_4.
  ///
  /// In en, this message translates to:
  /// **'Theme 4'**
  String get home_theme_4;

  /// No description provided for @home_theme_5.
  ///
  /// In en, this message translates to:
  /// **'Theme 5'**
  String get home_theme_5;

  /// No description provided for @home_theme_6.
  ///
  /// In en, this message translates to:
  /// **'Theme 6'**
  String get home_theme_6;

  /// No description provided for @login_username_hint_text.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get login_username_hint_text;

  /// No description provided for @login_password_hint_text.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_password_hint_text;

  /// No description provided for @login_success.
  ///
  /// In en, this message translates to:
  /// **'Login Success'**
  String get login_success;

  /// No description provided for @network_error_401.
  ///
  /// In en, this message translates to:
  /// **'Http 401'**
  String get network_error_401;

  /// No description provided for @network_error_403.
  ///
  /// In en, this message translates to:
  /// **'Http 403'**
  String get network_error_403;

  /// No description provided for @network_error_404.
  ///
  /// In en, this message translates to:
  /// **'Http 404'**
  String get network_error_404;

  /// No description provided for @network_error_422.
  ///
  /// In en, this message translates to:
  /// **'Request Body Error, Please check Github ClientId or Account/PW'**
  String get network_error_422;

  /// No description provided for @network_error_timeout.
  ///
  /// In en, this message translates to:
  /// **'Http timeout'**
  String get network_error_timeout;

  /// No description provided for @network_error_unknown.
  ///
  /// In en, this message translates to:
  /// **'Http unknown error'**
  String get network_error_unknown;

  /// No description provided for @network_error.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get network_error;

  /// No description provided for @github_refused.
  ///
  /// In en, this message translates to:
  /// **'Github Api error[OS Error: Connection refused]. Please switch networks or try again later'**
  String get github_refused;

  /// No description provided for @load_more_not.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get load_more_not;

  /// No description provided for @load_more_text.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get load_more_text;

  /// No description provided for @home_dynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic'**
  String get home_dynamic;

  /// No description provided for @home_trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get home_trend;

  /// No description provided for @home_my.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get home_my;

  /// No description provided for @trend_user_title.
  ///
  /// In en, this message translates to:
  /// **'China User Trend'**
  String get trend_user_title;

  /// No description provided for @trend_day.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get trend_day;

  /// No description provided for @trend_week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get trend_week;

  /// No description provided for @trend_month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get trend_month;

  /// No description provided for @trend_all.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get trend_all;

  /// No description provided for @trend_all_languages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get trend_all_languages;

  /// No description provided for @user_tab_repos.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get user_tab_repos;

  /// No description provided for @user_tab_fans.
  ///
  /// In en, this message translates to:
  /// **'Follower'**
  String get user_tab_fans;

  /// No description provided for @user_tab_focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get user_tab_focus;

  /// No description provided for @user_tab_star.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get user_tab_star;

  /// No description provided for @user_tab_honor.
  ///
  /// In en, this message translates to:
  /// **'Honor'**
  String get user_tab_honor;

  /// No description provided for @user_dynamic_group.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get user_dynamic_group;

  /// No description provided for @user_dynamic_title.
  ///
  /// In en, this message translates to:
  /// **'Dynamic'**
  String get user_dynamic_title;

  /// No description provided for @user_focus.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get user_focus;

  /// No description provided for @user_un_focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get user_un_focus;

  /// No description provided for @user_focus_no_support.
  ///
  /// In en, this message translates to:
  /// **'Not Support.'**
  String get user_focus_no_support;

  /// No description provided for @user_create_at.
  ///
  /// In en, this message translates to:
  /// **'Create at: '**
  String get user_create_at;

  /// No description provided for @user_orgs_title.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get user_orgs_title;

  /// No description provided for @repos_tab_readme.
  ///
  /// In en, this message translates to:
  /// **'README'**
  String get repos_tab_readme;

  /// No description provided for @repos_tab_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get repos_tab_info;

  /// No description provided for @repos_tab_file.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get repos_tab_file;

  /// No description provided for @repos_tab_issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get repos_tab_issue;

  /// No description provided for @repos_tab_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get repos_tab_activity;

  /// No description provided for @repos_tab_commits.
  ///
  /// In en, this message translates to:
  /// **'Commits'**
  String get repos_tab_commits;

  /// No description provided for @repos_tab_issue_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get repos_tab_issue_all;

  /// No description provided for @repos_tab_issue_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get repos_tab_issue_open;

  /// No description provided for @repos_tab_issue_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get repos_tab_issue_closed;

  /// No description provided for @repos_issue_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get repos_issue_filter;

  /// No description provided for @repos_issue_filter_title.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get repos_issue_filter_title;

  /// No description provided for @repos_issue_filter_sort.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get repos_issue_filter_sort;

  /// No description provided for @repos_issue_filter_sort_created.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get repos_issue_filter_sort_created;

  /// No description provided for @repos_issue_filter_sort_updated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get repos_issue_filter_sort_updated;

  /// No description provided for @repos_issue_filter_sort_comments.
  ///
  /// In en, this message translates to:
  /// **'Most commented'**
  String get repos_issue_filter_sort_comments;

  /// No description provided for @repos_issue_filter_direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get repos_issue_filter_direction;

  /// No description provided for @repos_issue_filter_direction_asc.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get repos_issue_filter_direction_asc;

  /// No description provided for @repos_issue_filter_direction_desc.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get repos_issue_filter_direction_desc;

  /// No description provided for @repos_issue_filter_labels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get repos_issue_filter_labels;

  /// No description provided for @repos_issue_filter_labels_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get repos_issue_filter_labels_loading;

  /// No description provided for @repos_issue_filter_labels_empty.
  ///
  /// In en, this message translates to:
  /// **'No labels on this repository'**
  String get repos_issue_filter_labels_empty;

  /// No description provided for @repos_issue_filter_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get repos_issue_filter_apply;

  /// No description provided for @repos_issue_filter_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get repos_issue_filter_clear;

  /// No description provided for @repos_option_release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get repos_option_release;

  /// No description provided for @repos_option_branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get repos_option_branch;

  /// No description provided for @repos_fork_at.
  ///
  /// In en, this message translates to:
  /// **'Fork at '**
  String get repos_fork_at;

  /// No description provided for @repos_create_at.
  ///
  /// In en, this message translates to:
  /// **'Create at '**
  String get repos_create_at;

  /// No description provided for @repos_last_commit.
  ///
  /// In en, this message translates to:
  /// **'Last commit at '**
  String get repos_last_commit;

  /// No description provided for @repos_all_issue_count.
  ///
  /// In en, this message translates to:
  /// **'All Issue: '**
  String get repos_all_issue_count;

  /// No description provided for @repos_open_issue_count.
  ///
  /// In en, this message translates to:
  /// **'Open Issue: '**
  String get repos_open_issue_count;

  /// No description provided for @repos_close_issue_count.
  ///
  /// In en, this message translates to:
  /// **'Close Issue: '**
  String get repos_close_issue_count;

  /// No description provided for @repos_issue_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get repos_issue_search;

  /// No description provided for @repos_no_support_issue.
  ///
  /// In en, this message translates to:
  /// **'Not Support Issue'**
  String get repos_no_support_issue;

  /// No description provided for @issue_reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get issue_reply;

  /// No description provided for @issue_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get issue_edit;

  /// No description provided for @issue_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get issue_open;

  /// No description provided for @issue_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get issue_close;

  /// No description provided for @issue_lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get issue_lock;

  /// No description provided for @issue_unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get issue_unlock;

  /// No description provided for @issue_reply_issue.
  ///
  /// In en, this message translates to:
  /// **'Reply Issue'**
  String get issue_reply_issue;

  /// No description provided for @issue_commit_issue.
  ///
  /// In en, this message translates to:
  /// **'Commit Issue'**
  String get issue_commit_issue;

  /// No description provided for @issue_edit_issue.
  ///
  /// In en, this message translates to:
  /// **'Edit Issue'**
  String get issue_edit_issue;

  /// No description provided for @issue_edit_issue_commit.
  ///
  /// In en, this message translates to:
  /// **'Edit Reply'**
  String get issue_edit_issue_commit;

  /// No description provided for @issue_edit_issue_edit_commit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get issue_edit_issue_edit_commit;

  /// No description provided for @issue_edit_issue_delete_commit.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get issue_edit_issue_delete_commit;

  /// No description provided for @issue_edit_issue_copy_commit.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get issue_edit_issue_copy_commit;

  /// No description provided for @issue_edit_issue_content_not_be_null.
  ///
  /// In en, this message translates to:
  /// **'Content cannot be empty'**
  String get issue_edit_issue_content_not_be_null;

  /// No description provided for @issue_edit_issue_title_not_be_null.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get issue_edit_issue_title_not_be_null;

  /// No description provided for @issue_edit_issue_title_tip.
  ///
  /// In en, this message translates to:
  /// **'Please input title'**
  String get issue_edit_issue_title_tip;

  /// No description provided for @issue_edit_issue_content_tip.
  ///
  /// In en, this message translates to:
  /// **'Please input content'**
  String get issue_edit_issue_content_tip;

  /// No description provided for @notify_title.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get notify_title;

  /// No description provided for @notify_tab_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notify_tab_all;

  /// No description provided for @notify_tab_part.
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get notify_tab_part;

  /// No description provided for @notify_tab_unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notify_tab_unread;

  /// No description provided for @notify_unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notify_unread;

  /// No description provided for @notify_readed.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notify_readed;

  /// No description provided for @notify_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get notify_status;

  /// No description provided for @notify_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get notify_type;

  /// No description provided for @notify_unsupported_type.
  ///
  /// In en, this message translates to:
  /// **'Unsupported notification type: {type}, opened in browser'**
  String notify_unsupported_type(String type);

  /// No description provided for @notify_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get notify_archive;

  /// No description provided for @notify_subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get notify_subscribe;

  /// No description provided for @notify_unsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get notify_unsubscribe;

  /// No description provided for @notify_read_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark as read, please try again'**
  String get notify_read_failed;

  /// No description provided for @notify_archive_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to archive, please try again'**
  String get notify_archive_failed;

  /// No description provided for @notify_subscribe_failed.
  ///
  /// In en, this message translates to:
  /// **'Subscription action failed, please try again'**
  String get notify_subscribe_failed;

  /// No description provided for @notify_subscribe_success.
  ///
  /// In en, this message translates to:
  /// **'Subscribed to this thread'**
  String get notify_subscribe_success;

  /// No description provided for @notify_unsubscribe_success.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribed from this thread'**
  String get notify_unsubscribe_success;

  /// No description provided for @notify_archive_success.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get notify_archive_success;

  /// No description provided for @notify_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get notify_reason;

  /// No description provided for @notify_reason_approval_requested.
  ///
  /// In en, this message translates to:
  /// **'Approval requested'**
  String get notify_reason_approval_requested;

  /// No description provided for @notify_reason_assign.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get notify_reason_assign;

  /// No description provided for @notify_reason_author.
  ///
  /// In en, this message translates to:
  /// **'You authored'**
  String get notify_reason_author;

  /// No description provided for @notify_reason_ci_activity.
  ///
  /// In en, this message translates to:
  /// **'Actions run finished'**
  String get notify_reason_ci_activity;

  /// No description provided for @notify_reason_comment.
  ///
  /// In en, this message translates to:
  /// **'You commented'**
  String get notify_reason_comment;

  /// No description provided for @notify_reason_invitation.
  ///
  /// In en, this message translates to:
  /// **'Repo invitation accepted'**
  String get notify_reason_invitation;

  /// No description provided for @notify_reason_manual.
  ///
  /// In en, this message translates to:
  /// **'You subscribed'**
  String get notify_reason_manual;

  /// No description provided for @notify_reason_member_feature_requested.
  ///
  /// In en, this message translates to:
  /// **'Member feature requested'**
  String get notify_reason_member_feature_requested;

  /// No description provided for @notify_reason_mention.
  ///
  /// In en, this message translates to:
  /// **'@mentioned you'**
  String get notify_reason_mention;

  /// No description provided for @notify_reason_review_requested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get notify_reason_review_requested;

  /// No description provided for @notify_reason_security_advisory_credit.
  ///
  /// In en, this message translates to:
  /// **'Security advisory credit'**
  String get notify_reason_security_advisory_credit;

  /// No description provided for @notify_reason_security_alert.
  ///
  /// In en, this message translates to:
  /// **'Security alert'**
  String get notify_reason_security_alert;

  /// No description provided for @notify_reason_state_change.
  ///
  /// In en, this message translates to:
  /// **'You changed state'**
  String get notify_reason_state_change;

  /// No description provided for @notify_reason_subscribed.
  ///
  /// In en, this message translates to:
  /// **'You watch this repo'**
  String get notify_reason_subscribed;

  /// No description provided for @notify_reason_team_mention.
  ///
  /// In en, this message translates to:
  /// **'Your team was mentioned'**
  String get notify_reason_team_mention;

  /// No description provided for @notify_filter_repo.
  ///
  /// In en, this message translates to:
  /// **'Filter by repo'**
  String get notify_filter_repo;

  /// No description provided for @notify_filter_repo_all.
  ///
  /// In en, this message translates to:
  /// **'All repos'**
  String get notify_filter_repo_all;

  /// No description provided for @notify_filter_repo_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'No notifications for this repo'**
  String get notify_filter_repo_empty_hint;

  /// No description provided for @notify_filter_reason.
  ///
  /// In en, this message translates to:
  /// **'Filter by reason'**
  String get notify_filter_reason;

  /// No description provided for @notify_filter_reason_all.
  ///
  /// In en, this message translates to:
  /// **'All reasons'**
  String get notify_filter_reason_all;

  /// No description provided for @notify_filter_reason_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'No notifications for this reason'**
  String get notify_filter_reason_empty_hint;

  /// No description provided for @search_title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_title;

  /// No description provided for @search_tab_repos.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get search_tab_repos;

  /// No description provided for @search_tab_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get search_tab_user;

  /// No description provided for @search_tab_issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get search_tab_issue;

  /// No description provided for @search_tab_code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get search_tab_code;

  /// No description provided for @release_tab_release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get release_tab_release;

  /// No description provided for @release_tab_tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get release_tab_tag;

  /// No description provided for @user_profile_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get user_profile_name;

  /// No description provided for @user_profile_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get user_profile_email;

  /// No description provided for @user_profile_link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get user_profile_link;

  /// No description provided for @user_profile_org.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get user_profile_org;

  /// No description provided for @user_profile_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get user_profile_location;

  /// No description provided for @user_profile_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get user_profile_info;

  /// No description provided for @search_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get search_type;

  /// No description provided for @search_sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get search_sort;

  /// No description provided for @search_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get search_language;

  /// No description provided for @search_filter_type_best_match.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get search_filter_type_best_match;

  /// No description provided for @search_filter_type_stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get search_filter_type_stars;

  /// No description provided for @search_filter_type_forks.
  ///
  /// In en, this message translates to:
  /// **'Forks'**
  String get search_filter_type_forks;

  /// No description provided for @search_filter_type_updated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get search_filter_type_updated;

  /// No description provided for @search_sort_desc.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get search_sort_desc;

  /// No description provided for @search_sort_asc.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get search_sort_asc;

  /// No description provided for @search_history_title.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get search_history_title;

  /// No description provided for @search_history_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Type a keyword to start searching'**
  String get search_history_empty_hint;

  /// No description provided for @search_history_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get search_history_clear;

  /// No description provided for @search_history_clear_confirm.
  ///
  /// In en, this message translates to:
  /// **'Clear search history?'**
  String get search_history_clear_confirm;

  /// No description provided for @feed_back_tip.
  ///
  /// In en, this message translates to:
  /// **'Your feedback will be sent to Github as a public issue'**
  String get feed_back_tip;

  /// No description provided for @issue_badge_bot.
  ///
  /// In en, this message translates to:
  /// **'bot'**
  String get issue_badge_bot;

  /// No description provided for @issue_badge_edited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get issue_badge_edited;

  /// No description provided for @issue_comment_minimized.
  ///
  /// In en, this message translates to:
  /// **'This comment has been minimized'**
  String get issue_comment_minimized;

  /// No description provided for @issue_reactions_add_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Add reaction'**
  String get issue_reactions_add_tooltip;

  /// No description provided for @issue_reaction_failed.
  ///
  /// In en, this message translates to:
  /// **'Reaction failed'**
  String get issue_reaction_failed;

  /// No description provided for @issue_reaction_remove_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove reaction'**
  String get issue_reaction_remove_failed;

  /// No description provided for @issue_assoc_owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get issue_assoc_owner;

  /// No description provided for @issue_assoc_member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get issue_assoc_member;

  /// No description provided for @issue_assoc_collaborator.
  ///
  /// In en, this message translates to:
  /// **'Collaborator'**
  String get issue_assoc_collaborator;

  /// No description provided for @issue_assoc_contributor.
  ///
  /// In en, this message translates to:
  /// **'Contributor'**
  String get issue_assoc_contributor;

  /// No description provided for @issue_assoc_first_time_contributor.
  ///
  /// In en, this message translates to:
  /// **'First-time contributor'**
  String get issue_assoc_first_time_contributor;

  /// No description provided for @issue_assoc_first_timer.
  ///
  /// In en, this message translates to:
  /// **'First-timer'**
  String get issue_assoc_first_timer;

  /// No description provided for @issue_assoc_mannequin.
  ///
  /// In en, this message translates to:
  /// **'Mannequin'**
  String get issue_assoc_mannequin;

  /// No description provided for @issue_timeline_labeled.
  ///
  /// In en, this message translates to:
  /// **'{actor} added the label {label}'**
  String issue_timeline_labeled(String actor, String label);

  /// No description provided for @issue_timeline_unlabeled.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed the label {label}'**
  String issue_timeline_unlabeled(String actor, String label);

  /// No description provided for @issue_timeline_assigned.
  ///
  /// In en, this message translates to:
  /// **'{actor} assigned {assignee}'**
  String issue_timeline_assigned(String actor, String assignee);

  /// No description provided for @issue_timeline_unassigned.
  ///
  /// In en, this message translates to:
  /// **'{actor} unassigned {assignee}'**
  String issue_timeline_unassigned(String actor, String assignee);

  /// No description provided for @issue_timeline_milestoned.
  ///
  /// In en, this message translates to:
  /// **'{actor} added this to the {milestone} milestone'**
  String issue_timeline_milestoned(String actor, String milestone);

  /// No description provided for @issue_timeline_demilestoned.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed this from the {milestone} milestone'**
  String issue_timeline_demilestoned(String actor, String milestone);

  /// No description provided for @issue_timeline_renamed.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the title from {from} to {to}'**
  String issue_timeline_renamed(String actor, String from, String to);

  /// No description provided for @issue_timeline_closed.
  ///
  /// In en, this message translates to:
  /// **'{actor} closed this'**
  String issue_timeline_closed(String actor);

  /// No description provided for @issue_timeline_reopened.
  ///
  /// In en, this message translates to:
  /// **'{actor} reopened this'**
  String issue_timeline_reopened(String actor);

  /// No description provided for @issue_timeline_locked.
  ///
  /// In en, this message translates to:
  /// **'{actor} locked this conversation'**
  String issue_timeline_locked(String actor);

  /// No description provided for @issue_timeline_unlocked.
  ///
  /// In en, this message translates to:
  /// **'{actor} unlocked this conversation'**
  String issue_timeline_unlocked(String actor);

  /// No description provided for @issue_timeline_pinned.
  ///
  /// In en, this message translates to:
  /// **'{actor} pinned this'**
  String issue_timeline_pinned(String actor);

  /// No description provided for @issue_timeline_unpinned.
  ///
  /// In en, this message translates to:
  /// **'{actor} unpinned this'**
  String issue_timeline_unpinned(String actor);

  /// No description provided for @issue_timeline_merged.
  ///
  /// In en, this message translates to:
  /// **'{actor} merged this'**
  String issue_timeline_merged(String actor);

  /// No description provided for @issue_timeline_referenced.
  ///
  /// In en, this message translates to:
  /// **'{actor} referenced this'**
  String issue_timeline_referenced(String actor);

  /// No description provided for @issue_timeline_cross_referenced.
  ///
  /// In en, this message translates to:
  /// **'{actor} mentioned this from another issue'**
  String issue_timeline_cross_referenced(String actor);

  /// No description provided for @issue_timeline_mentioned.
  ///
  /// In en, this message translates to:
  /// **'{actor} was mentioned'**
  String issue_timeline_mentioned(String actor);

  /// No description provided for @issue_timeline_subscribed.
  ///
  /// In en, this message translates to:
  /// **'{actor} subscribed'**
  String issue_timeline_subscribed(String actor);

  /// No description provided for @issue_timeline_unsubscribed.
  ///
  /// In en, this message translates to:
  /// **'{actor} unsubscribed'**
  String issue_timeline_unsubscribed(String actor);

  /// No description provided for @issue_timeline_generic.
  ///
  /// In en, this message translates to:
  /// **'{actor} {event}'**
  String issue_timeline_generic(String actor, String event);

  /// No description provided for @pr_state_merged.
  ///
  /// In en, this message translates to:
  /// **'merged'**
  String get pr_state_merged;

  /// No description provided for @pr_state_draft.
  ///
  /// In en, this message translates to:
  /// **'draft'**
  String get pr_state_draft;

  /// No description provided for @pr_review_requested.
  ///
  /// In en, this message translates to:
  /// **'Review requested:'**
  String get pr_review_requested;

  /// No description provided for @pr_files_changed.
  ///
  /// In en, this message translates to:
  /// **'{count} files changed'**
  String pr_files_changed(int count);

  /// No description provided for @pr_commits.
  ///
  /// In en, this message translates to:
  /// **'{count} commits'**
  String pr_commits(int count);

  /// No description provided for @pr_timeline_reviewed_approved.
  ///
  /// In en, this message translates to:
  /// **'{actor} approved these changes'**
  String pr_timeline_reviewed_approved(String actor);

  /// No description provided for @pr_timeline_reviewed_changes_requested.
  ///
  /// In en, this message translates to:
  /// **'{actor} requested changes'**
  String pr_timeline_reviewed_changes_requested(String actor);

  /// No description provided for @pr_timeline_reviewed_commented.
  ///
  /// In en, this message translates to:
  /// **'{actor} reviewed'**
  String pr_timeline_reviewed_commented(String actor);

  /// No description provided for @pr_timeline_reviewed_dismissed.
  ///
  /// In en, this message translates to:
  /// **'{actor} dismissed a review'**
  String pr_timeline_reviewed_dismissed(String actor);

  /// No description provided for @pr_timeline_review_requested.
  ///
  /// In en, this message translates to:
  /// **'{actor} requested a review from {reviewer}'**
  String pr_timeline_review_requested(String actor, String reviewer);

  /// No description provided for @pr_timeline_review_request_removed.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed the review request from {reviewer}'**
  String pr_timeline_review_request_removed(String actor, String reviewer);

  /// No description provided for @pr_timeline_ready_for_review.
  ///
  /// In en, this message translates to:
  /// **'{actor} marked this pull request as ready for review'**
  String pr_timeline_ready_for_review(String actor);

  /// No description provided for @pr_timeline_convert_to_draft.
  ///
  /// In en, this message translates to:
  /// **'{actor} marked this pull request as draft'**
  String pr_timeline_convert_to_draft(String actor);

  /// No description provided for @pr_timeline_head_ref_force_pushed.
  ///
  /// In en, this message translates to:
  /// **'{actor} force-pushed the head branch'**
  String pr_timeline_head_ref_force_pushed(String actor);

  /// No description provided for @pr_timeline_base_ref_force_pushed.
  ///
  /// In en, this message translates to:
  /// **'{actor} force-pushed the base branch'**
  String pr_timeline_base_ref_force_pushed(String actor);

  /// No description provided for @pr_timeline_head_ref_deleted.
  ///
  /// In en, this message translates to:
  /// **'{actor} deleted the head branch'**
  String pr_timeline_head_ref_deleted(String actor);

  /// No description provided for @pr_timeline_head_ref_restored.
  ///
  /// In en, this message translates to:
  /// **'{actor} restored the head branch'**
  String pr_timeline_head_ref_restored(String actor);

  /// No description provided for @pr_timeline_base_ref_changed.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the base branch'**
  String pr_timeline_base_ref_changed(String actor);

  /// No description provided for @pr_timeline_auto_merge_enabled.
  ///
  /// In en, this message translates to:
  /// **'{actor} enabled auto-merge'**
  String pr_timeline_auto_merge_enabled(String actor);

  /// No description provided for @pr_timeline_auto_merge_disabled.
  ///
  /// In en, this message translates to:
  /// **'{actor} disabled auto-merge'**
  String pr_timeline_auto_merge_disabled(String actor);

  /// No description provided for @pr_timeline_committed.
  ///
  /// In en, this message translates to:
  /// **'{actor} committed {shortSha} — {message}'**
  String pr_timeline_committed(String actor, String shortSha, String message);

  /// No description provided for @pr_timeline_committed_no_message.
  ///
  /// In en, this message translates to:
  /// **'{actor} committed {shortSha}'**
  String pr_timeline_committed_no_message(String actor, String shortSha);

  /// No description provided for @pr_timeline_copilot_work_started.
  ///
  /// In en, this message translates to:
  /// **'{actor} started working on this PR'**
  String pr_timeline_copilot_work_started(String actor);

  /// No description provided for @pr_timeline_copilot_work_finished.
  ///
  /// In en, this message translates to:
  /// **'{actor} finished working on this PR'**
  String pr_timeline_copilot_work_finished(String actor);

  /// No description provided for @pr_timeline_added_to_merge_queue.
  ///
  /// In en, this message translates to:
  /// **'{actor} added this pull request to the merge queue'**
  String pr_timeline_added_to_merge_queue(String actor);

  /// No description provided for @pr_timeline_removed_from_merge_queue.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed this pull request from the merge queue'**
  String pr_timeline_removed_from_merge_queue(String actor);

  /// No description provided for @issue_timeline_added_to_project.
  ///
  /// In en, this message translates to:
  /// **'{actor} added this to a project'**
  String issue_timeline_added_to_project(String actor);

  /// No description provided for @issue_timeline_project_status_changed.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the project status'**
  String issue_timeline_project_status_changed(String actor);

  /// No description provided for @issue_timeline_issue_type_added.
  ///
  /// In en, this message translates to:
  /// **'{actor} set the issue type'**
  String issue_timeline_issue_type_added(String actor);

  /// No description provided for @event_dynamic_commit_comment.
  ///
  /// In en, this message translates to:
  /// **'Commit comment at {repo}'**
  String event_dynamic_commit_comment(String repo);

  /// No description provided for @event_dynamic_create_repository.
  ///
  /// In en, this message translates to:
  /// **'Created repository {repo}'**
  String event_dynamic_create_repository(String repo);

  /// No description provided for @event_dynamic_create_ref.
  ///
  /// In en, this message translates to:
  /// **'Created {refType} {ref} at {repo}'**
  String event_dynamic_create_ref(String refType, String ref, String repo);

  /// No description provided for @event_dynamic_delete_ref.
  ///
  /// In en, this message translates to:
  /// **'Deleted {refType} {ref} at {repo}'**
  String event_dynamic_delete_ref(String refType, String ref, String repo);

  /// No description provided for @event_dynamic_fork_full.
  ///
  /// In en, this message translates to:
  /// **'Forked {fromRepo} to {forker}/{fromRepo}'**
  String event_dynamic_fork_full(String fromRepo, String forker);

  /// No description provided for @event_dynamic_fork_repo.
  ///
  /// In en, this message translates to:
  /// **'Forked {repo}'**
  String event_dynamic_fork_repo(String repo);

  /// No description provided for @event_dynamic_fork_generic.
  ///
  /// In en, this message translates to:
  /// **'Forked a repository'**
  String get event_dynamic_fork_generic;

  /// No description provided for @event_dynamic_gollum.
  ///
  /// In en, this message translates to:
  /// **'{actor} edited a wiki page'**
  String event_dynamic_gollum(String actor);

  /// No description provided for @event_dynamic_installation.
  ///
  /// In en, this message translates to:
  /// **'{action} a GitHub App'**
  String event_dynamic_installation(String action);

  /// No description provided for @event_dynamic_installation_repos.
  ///
  /// In en, this message translates to:
  /// **'{action} repository from an installation'**
  String event_dynamic_installation_repos(String action);

  /// No description provided for @event_dynamic_issue_comment.
  ///
  /// In en, this message translates to:
  /// **'{action} comment on issue #{number} in {repo}'**
  String event_dynamic_issue_comment(String action, String number, String repo);

  /// No description provided for @event_dynamic_issue.
  ///
  /// In en, this message translates to:
  /// **'{action} issue #{number} in {repo}'**
  String event_dynamic_issue(String action, String number, String repo);

  /// No description provided for @event_dynamic_marketplace.
  ///
  /// In en, this message translates to:
  /// **'{action} marketplace plan'**
  String event_dynamic_marketplace(String action);

  /// No description provided for @event_dynamic_member.
  ///
  /// In en, this message translates to:
  /// **'{action} member to {repo}'**
  String event_dynamic_member(String action, String repo);

  /// No description provided for @event_dynamic_org_block.
  ///
  /// In en, this message translates to:
  /// **'{action} a user'**
  String event_dynamic_org_block(String action);

  /// No description provided for @event_dynamic_project_card.
  ///
  /// In en, this message translates to:
  /// **'{action} a project card'**
  String event_dynamic_project_card(String action);

  /// No description provided for @event_dynamic_project_column.
  ///
  /// In en, this message translates to:
  /// **'{action} a project column'**
  String event_dynamic_project_column(String action);

  /// No description provided for @event_dynamic_project.
  ///
  /// In en, this message translates to:
  /// **'{action} a project'**
  String event_dynamic_project(String action);

  /// No description provided for @event_dynamic_public.
  ///
  /// In en, this message translates to:
  /// **'Made {repo} public'**
  String event_dynamic_public(String repo);

  /// No description provided for @event_dynamic_pull_request.
  ///
  /// In en, this message translates to:
  /// **'{action} pull request in {repo}'**
  String event_dynamic_pull_request(String action, String repo);

  /// No description provided for @event_dynamic_pull_request_review.
  ///
  /// In en, this message translates to:
  /// **'{action} pull request review at {repo}'**
  String event_dynamic_pull_request_review(String action, String repo);

  /// No description provided for @event_dynamic_pull_request_review_comment.
  ///
  /// In en, this message translates to:
  /// **'{action} pull request review comment at {repo}'**
  String event_dynamic_pull_request_review_comment(String action, String repo);

  /// No description provided for @event_dynamic_push.
  ///
  /// In en, this message translates to:
  /// **'Pushed to {ref} at {repo}'**
  String event_dynamic_push(String ref, String repo);

  /// No description provided for @event_dynamic_release.
  ///
  /// In en, this message translates to:
  /// **'{action} release {tag} at {repo}'**
  String event_dynamic_release(String action, String tag, String repo);

  /// No description provided for @event_dynamic_discussion.
  ///
  /// In en, this message translates to:
  /// **'{action} a discussion at {repo}'**
  String event_dynamic_discussion(String action, String repo);

  /// No description provided for @event_dynamic_discussion_comment.
  ///
  /// In en, this message translates to:
  /// **'{action} a discussion comment at {repo}'**
  String event_dynamic_discussion_comment(String action, String repo);

  /// No description provided for @event_dynamic_pull_request_review_thread.
  ///
  /// In en, this message translates to:
  /// **'{action} a PR review thread at {repo}'**
  String event_dynamic_pull_request_review_thread(String action, String repo);

  /// No description provided for @discussion_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load discussion'**
  String get discussion_load_failed;

  /// No description provided for @discussion_not_found.
  ///
  /// In en, this message translates to:
  /// **'Discussion not found'**
  String get discussion_not_found;

  /// No description provided for @discussion_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get discussion_retry;

  /// No description provided for @discussion_answered_badge.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get discussion_answered_badge;

  /// No description provided for @discussion_empty_body.
  ///
  /// In en, this message translates to:
  /// **'This discussion has no body'**
  String get discussion_empty_body;

  /// No description provided for @discussion_skeleton_notice.
  ///
  /// In en, this message translates to:
  /// **'Comments, voting and mark-as-answer will be added in follow-up subtasks (roadmap §3.1).'**
  String get discussion_skeleton_notice;

  /// No description provided for @discussion_comments_count.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String discussion_comments_count(int count);

  /// No description provided for @event_dynamic_sponsorship.
  ///
  /// In en, this message translates to:
  /// **'{action} a sponsorship'**
  String event_dynamic_sponsorship(String action);

  /// No description provided for @event_dynamic_watch.
  ///
  /// In en, this message translates to:
  /// **'{action} {repo}'**
  String event_dynamic_watch(String action, String repo);

  /// No description provided for @event_dynamic_watch_started.
  ///
  /// In en, this message translates to:
  /// **'Starred {repo}'**
  String event_dynamic_watch_started(String repo);

  /// No description provided for @event_dynamic_push_head.
  ///
  /// In en, this message translates to:
  /// **'head: {sha}'**
  String event_dynamic_push_head(String sha);

  /// No description provided for @event_dynamic_push_commit_fallback.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get event_dynamic_push_commit_fallback;

  /// No description provided for @event_action_started.
  ///
  /// In en, this message translates to:
  /// **'started'**
  String get event_action_started;

  /// No description provided for @event_action_opened.
  ///
  /// In en, this message translates to:
  /// **'opened'**
  String get event_action_opened;

  /// No description provided for @event_action_edited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get event_action_edited;

  /// No description provided for @event_action_closed.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get event_action_closed;

  /// No description provided for @event_action_reopened.
  ///
  /// In en, this message translates to:
  /// **'reopened'**
  String get event_action_reopened;

  /// No description provided for @event_action_assigned.
  ///
  /// In en, this message translates to:
  /// **'assigned'**
  String get event_action_assigned;

  /// No description provided for @event_action_unassigned.
  ///
  /// In en, this message translates to:
  /// **'unassigned'**
  String get event_action_unassigned;

  /// No description provided for @event_action_labeled.
  ///
  /// In en, this message translates to:
  /// **'labeled'**
  String get event_action_labeled;

  /// No description provided for @event_action_unlabeled.
  ///
  /// In en, this message translates to:
  /// **'unlabeled'**
  String get event_action_unlabeled;

  /// No description provided for @event_action_created.
  ///
  /// In en, this message translates to:
  /// **'created'**
  String get event_action_created;

  /// No description provided for @event_action_deleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get event_action_deleted;

  /// No description provided for @event_action_review_requested.
  ///
  /// In en, this message translates to:
  /// **'requested review on'**
  String get event_action_review_requested;

  /// No description provided for @event_action_review_request_removed.
  ///
  /// In en, this message translates to:
  /// **'removed review request on'**
  String get event_action_review_request_removed;

  /// No description provided for @event_action_synchronize.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get event_action_synchronize;

  /// No description provided for @event_action_ready_for_review.
  ///
  /// In en, this message translates to:
  /// **'marked ready for review'**
  String get event_action_ready_for_review;

  /// No description provided for @event_action_dismissed.
  ///
  /// In en, this message translates to:
  /// **'dismissed'**
  String get event_action_dismissed;

  /// No description provided for @event_action_submitted.
  ///
  /// In en, this message translates to:
  /// **'submitted'**
  String get event_action_submitted;

  /// No description provided for @event_action_published.
  ///
  /// In en, this message translates to:
  /// **'published'**
  String get event_action_published;

  /// No description provided for @event_action_prereleased.
  ///
  /// In en, this message translates to:
  /// **'prereleased'**
  String get event_action_prereleased;

  /// No description provided for @event_action_released.
  ///
  /// In en, this message translates to:
  /// **'released'**
  String get event_action_released;

  /// No description provided for @event_action_added.
  ///
  /// In en, this message translates to:
  /// **'added'**
  String get event_action_added;

  /// No description provided for @event_action_removed.
  ///
  /// In en, this message translates to:
  /// **'removed'**
  String get event_action_removed;

  /// No description provided for @event_action_suspend.
  ///
  /// In en, this message translates to:
  /// **'suspended'**
  String get event_action_suspend;

  /// No description provided for @event_action_unsuspend.
  ///
  /// In en, this message translates to:
  /// **'unsuspended'**
  String get event_action_unsuspend;

  /// No description provided for @event_action_new_permissions_accepted.
  ///
  /// In en, this message translates to:
  /// **'accepted new permissions on'**
  String get event_action_new_permissions_accepted;

  /// No description provided for @event_action_purchased.
  ///
  /// In en, this message translates to:
  /// **'purchased'**
  String get event_action_purchased;

  /// No description provided for @event_action_cancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get event_action_cancelled;

  /// No description provided for @event_action_pending_change.
  ///
  /// In en, this message translates to:
  /// **'pending change on'**
  String get event_action_pending_change;

  /// No description provided for @event_action_pending_change_cancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled pending change on'**
  String get event_action_pending_change_cancelled;

  /// No description provided for @event_action_changed.
  ///
  /// In en, this message translates to:
  /// **'changed'**
  String get event_action_changed;

  /// No description provided for @event_action_moved.
  ///
  /// In en, this message translates to:
  /// **'moved'**
  String get event_action_moved;

  /// No description provided for @event_action_blocked.
  ///
  /// In en, this message translates to:
  /// **'blocked'**
  String get event_action_blocked;

  /// No description provided for @event_action_unblocked.
  ///
  /// In en, this message translates to:
  /// **'unblocked'**
  String get event_action_unblocked;

  /// No description provided for @event_action_merged.
  ///
  /// In en, this message translates to:
  /// **'merged'**
  String get event_action_merged;

  /// No description provided for @event_action_auto_merge_enabled.
  ///
  /// In en, this message translates to:
  /// **'enabled auto-merge'**
  String get event_action_auto_merge_enabled;

  /// No description provided for @event_action_auto_merge_disabled.
  ///
  /// In en, this message translates to:
  /// **'disabled auto-merge'**
  String get event_action_auto_merge_disabled;

  /// No description provided for @event_action_converted_to_draft.
  ///
  /// In en, this message translates to:
  /// **'converted to draft'**
  String get event_action_converted_to_draft;

  /// No description provided for @event_action_locked.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get event_action_locked;

  /// No description provided for @event_action_unlocked.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get event_action_unlocked;

  /// No description provided for @event_action_pinned.
  ///
  /// In en, this message translates to:
  /// **'pinned'**
  String get event_action_pinned;

  /// No description provided for @event_action_unpinned.
  ///
  /// In en, this message translates to:
  /// **'unpinned'**
  String get event_action_unpinned;

  /// No description provided for @event_action_transferred.
  ///
  /// In en, this message translates to:
  /// **'transferred'**
  String get event_action_transferred;

  /// No description provided for @event_action_milestoned.
  ///
  /// In en, this message translates to:
  /// **'milestoned'**
  String get event_action_milestoned;

  /// No description provided for @event_action_demilestoned.
  ///
  /// In en, this message translates to:
  /// **'demilestoned'**
  String get event_action_demilestoned;

  /// No description provided for @event_action_answered.
  ///
  /// In en, this message translates to:
  /// **'marked as answered'**
  String get event_action_answered;

  /// No description provided for @event_action_unanswered.
  ///
  /// In en, this message translates to:
  /// **'removed answer mark'**
  String get event_action_unanswered;

  /// No description provided for @event_action_category_changed.
  ///
  /// In en, this message translates to:
  /// **'changed category'**
  String get event_action_category_changed;

  /// No description provided for @event_action_resolved.
  ///
  /// In en, this message translates to:
  /// **'resolved'**
  String get event_action_resolved;

  /// No description provided for @event_action_unresolved.
  ///
  /// In en, this message translates to:
  /// **'unresolved'**
  String get event_action_unresolved;

  /// No description provided for @option_pr_files.
  ///
  /// In en, this message translates to:
  /// **'Files changed'**
  String get option_pr_files;

  /// No description provided for @pr_files_title.
  ///
  /// In en, this message translates to:
  /// **'PR #{number} files changed'**
  String pr_files_title(int number);

  /// No description provided for @pr_files_review_comments_count.
  ///
  /// In en, this message translates to:
  /// **'{count} review comments'**
  String pr_files_review_comments_count(int count);

  /// No description provided for @pr_files_review_line.
  ///
  /// In en, this message translates to:
  /// **'Line {line}'**
  String pr_files_review_line(int line);

  /// No description provided for @pr_files_review_outdated.
  ///
  /// In en, this message translates to:
  /// **'This comment is outdated'**
  String get pr_files_review_outdated;

  /// No description provided for @pr_files_review_thread_resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get pr_files_review_thread_resolved;

  /// No description provided for @pr_files_review_thread_unresolved.
  ///
  /// In en, this message translates to:
  /// **'Unresolved'**
  String get pr_files_review_thread_unresolved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
