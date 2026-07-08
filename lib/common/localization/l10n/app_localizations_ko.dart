// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get welcomeMessage => 'Flutter에 오신 것을 환영합니다';

  @override
  String get app_name => 'GSYGithubApp';

  @override
  String get app_ok => '확인';

  @override
  String get app_cancel => '취소';

  @override
  String get app_empty => '데이터 없음(oﾟ▽ﾟ)o';

  @override
  String get app_licenses => '라이선스';

  @override
  String get app_close => '닫기';

  @override
  String get app_version => '버전';

  @override
  String get app_back_tip => '종료하시겠습니까?';

  @override
  String get app_not_new_version => '새로운 버전이 없습니다';

  @override
  String get app_version_title => '버전 업데이트';

  @override
  String get nothing_now => '아무것도 없음';

  @override
  String get loading_text => '로딩 중···';

  @override
  String get option_web => '브라우저';

  @override
  String get option_copy => '복사';

  @override
  String get option_share => '공유';

  @override
  String get option_web_launcher_error => 'URL 오류';

  @override
  String get option_share_title => 'GSYGitHubFlutter에서 공유: ';

  @override
  String get option_share_copy_success => '복사 성공';

  @override
  String get login_text => '로그인';

  @override
  String get oauth_text => 'OAuth';

  @override
  String get login_out => '로그아웃';

  @override
  String get login_deprecated => '비밀번호 인증 API는 2020년 11월 13일에 Github에서 제거됩니다';

  @override
  String get home_reply => '피드백';

  @override
  String get home_change_language => '언어';

  @override
  String get home_vibration => '진동 피드백';

  @override
  String get home_change_grey => '그레이스케일';

  @override
  String get home_about => '정보';

  @override
  String get home_check_update => '업데이트 확인';

  @override
  String get home_history => '기록';

  @override
  String get home_user_info => '프로필';

  @override
  String get home_change_theme => '테마';

  @override
  String get home_language_default => '기본';

  @override
  String get home_language_zh => '中文';

  @override
  String get home_language_en => 'English';

  @override
  String get home_language_ko => '한국어';

  @override
  String get home_language_ja => '日本語';

  @override
  String get switch_language => '언어 선택';

  @override
  String get home_theme_default => '기본 테마';

  @override
  String get home_theme_1 => '테마 1';

  @override
  String get home_theme_2 => '테마 2';

  @override
  String get home_theme_3 => '테마 3';

  @override
  String get home_theme_4 => '테마 4';

  @override
  String get home_theme_5 => '테마 5';

  @override
  String get home_theme_6 => '테마 6';

  @override
  String get login_username_hint_text => '사용자 이름';

  @override
  String get login_password_hint_text => '비밀번호';

  @override
  String get login_success => '로그인 성공';

  @override
  String get network_error_401 => 'Http 401';

  @override
  String get network_error_403 => 'Http 403';

  @override
  String get network_error_404 => 'Http 404';

  @override
  String get network_error_422 => '요청 본문 오류, Github ClientId 또는 계정/비밀번호를 확인하세요';

  @override
  String get network_error_timeout => 'Http 시간 초과';

  @override
  String get network_error_unknown => 'Http 알 수 없는 오류';

  @override
  String get network_error => '네트워크 오류';

  @override
  String get github_refused =>
      'Github API 오류[OS 오류: 연결 거부]. 네트워크를 전환하거나 나중에 다시 시도하세요';

  @override
  String get load_more_not => '더 이상 없음';

  @override
  String get load_more_text => '로딩 중';

  @override
  String get home_dynamic => '동적';

  @override
  String get home_trend => '트렌드';

  @override
  String get home_my => '내 정보';

  @override
  String get trend_user_title => '중국 사용자 트렌드';

  @override
  String get trend_day => '오늘';

  @override
  String get trend_week => '이번 주';

  @override
  String get trend_month => '이번 달';

  @override
  String get trend_all => '전체';

  @override
  String get trend_all_languages => '모든 언어';

  @override
  String get user_tab_repos => '저장소';

  @override
  String get user_tab_fans => '팔로워';

  @override
  String get user_tab_focus => '팔로잉';

  @override
  String get user_tab_star => '스타';

  @override
  String get user_tab_honor => '명예';

  @override
  String get user_dynamic_group => '멤버';

  @override
  String get user_dynamic_title => '동적';

  @override
  String get user_focus => '팔로잉 중';

  @override
  String get user_un_focus => '팔로우';

  @override
  String get user_focus_no_support => '지원되지 않음';

  @override
  String get user_create_at => '생성일: ';

  @override
  String get user_orgs_title => '조직';

  @override
  String get repos_tab_readme => 'README';

  @override
  String get repos_tab_info => '정보';

  @override
  String get repos_tab_file => '파일';

  @override
  String get repos_tab_issue => '이슈';

  @override
  String get repos_tab_activity => '활동';

  @override
  String get repos_tab_commits => '커밋';

  @override
  String get repos_tab_issue_all => '전체';

  @override
  String get repos_tab_issue_open => '열림';

  @override
  String get repos_tab_issue_closed => '닫힘';

  @override
  String get repos_issue_filter => '필터';

  @override
  String get repos_issue_filter_title => '필터 및 정렬';

  @override
  String get repos_issue_filter_sort => '정렬 기준';

  @override
  String get repos_issue_filter_sort_created => '생성일';

  @override
  String get repos_issue_filter_sort_updated => '업데이트일';

  @override
  String get repos_issue_filter_sort_comments => '댓글 수';

  @override
  String get repos_issue_filter_direction => '정렬 순서';

  @override
  String get repos_issue_filter_direction_asc => '오름차순';

  @override
  String get repos_issue_filter_direction_desc => '내림차순';

  @override
  String get repos_issue_filter_labels => '라벨';

  @override
  String get repos_issue_filter_labels_loading => '로딩 중…';

  @override
  String get repos_issue_filter_labels_empty => '이 저장소에는 라벨이 없습니다';

  @override
  String get repos_issue_filter_apply => '적용';

  @override
  String get repos_issue_filter_clear => '지우기';

  @override
  String get repos_option_release => '릴리스';

  @override
  String get repos_option_branch => '브랜치';

  @override
  String get repos_fork_at => '포크 일자: ';

  @override
  String get repos_create_at => '생성 일자: ';

  @override
  String get repos_last_commit => '마지막 커밋: ';

  @override
  String get repos_all_issue_count => '전체 이슈: ';

  @override
  String get repos_open_issue_count => '열린 이슈: ';

  @override
  String get repos_close_issue_count => '닫힌 이슈: ';

  @override
  String get repos_issue_search => '검색';

  @override
  String get repos_no_support_issue => '이슈가 지원되지 않음';

  @override
  String get issue_reply => '답변';

  @override
  String get issue_edit => '편집';

  @override
  String get issue_open => '열기';

  @override
  String get issue_close => '닫기';

  @override
  String get issue_lock => '잠금';

  @override
  String get issue_unlock => '잠금 해제';

  @override
  String get issue_reply_issue => '이슈 답변';

  @override
  String get issue_commit_issue => '이슈 커밋';

  @override
  String get issue_edit_issue => '이슈 편집';

  @override
  String get issue_edit_issue_commit => '답변 편집';

  @override
  String get issue_edit_issue_edit_commit => '편집';

  @override
  String get issue_edit_issue_delete_commit => '삭제';

  @override
  String get issue_edit_issue_copy_commit => '복사';

  @override
  String get issue_edit_issue_content_not_be_null => '내용을 입력하세요';

  @override
  String get issue_edit_issue_title_not_be_null => '제목을 입력하세요';

  @override
  String get issue_edit_issue_title_tip => '제목을 입력하세요';

  @override
  String get issue_edit_issue_content_tip => '내용을 입력하세요';

  @override
  String get notify_title => '알림';

  @override
  String get notify_tab_all => '전체';

  @override
  String get notify_tab_part => '참여';

  @override
  String get notify_tab_unread => '읽지 않음';

  @override
  String get notify_unread => '읽지 않음';

  @override
  String get notify_readed => '읽음';

  @override
  String get notify_status => '상태';

  @override
  String get notify_type => '유형';

  @override
  String notify_unsupported_type(String type) {
    return '지원되지 않는 알림 유형: $type, 브라우저에서 열림';
  }

  @override
  String get notify_archive => '보관';

  @override
  String get notify_subscribe => '구독';

  @override
  String get notify_unsubscribe => '구독 취소';

  @override
  String get notify_read_failed => '읽음으로 표시하지 못했습니다. 다시 시도해 주세요';

  @override
  String get notify_archive_failed => '보관에 실패했습니다. 다시 시도해 주세요';

  @override
  String get notify_subscribe_failed => '구독 작업에 실패했습니다. 다시 시도해 주세요';

  @override
  String get notify_subscribe_success => '이 스레드를 구독했습니다';

  @override
  String get notify_unsubscribe_success => '이 스레드 구독을 취소했습니다';

  @override
  String get notify_archive_success => '보관되었습니다';

  @override
  String get notify_reason => '이유';

  @override
  String get notify_reason_approval_requested => '배포 승인 요청';

  @override
  String get notify_reason_assign => '당신에게 할당됨';

  @override
  String get notify_reason_author => '당신이 작성함';

  @override
  String get notify_reason_ci_activity => 'Actions 실행 완료';

  @override
  String get notify_reason_comment => '당신이 댓글 작성함';

  @override
  String get notify_reason_invitation => '협업 초대 수락함';

  @override
  String get notify_reason_manual => '당신이 구독함';

  @override
  String get notify_reason_member_feature_requested => '구성원 기능 요청';

  @override
  String get notify_reason_mention => '당신을 @멘션함';

  @override
  String get notify_reason_review_requested => '리뷰 요청됨';

  @override
  String get notify_reason_security_advisory_credit => '보안 권고 크레딧';

  @override
  String get notify_reason_security_alert => '보안 경고';

  @override
  String get notify_reason_state_change => '당신이 상태 변경함';

  @override
  String get notify_reason_subscribed => '이 저장소를 Watch';

  @override
  String get notify_reason_team_mention => '당신 팀이 멘션됨';

  @override
  String get notify_filter_repo => '저장소로 필터링';

  @override
  String get notify_filter_repo_all => '모든 저장소';

  @override
  String get notify_filter_repo_empty_hint => '이 저장소에 대한 알림이 없습니다';

  @override
  String get notify_filter_reason => '사유로 필터링';

  @override
  String get notify_filter_reason_all => '모든 사유';

  @override
  String get notify_filter_reason_empty_hint => '이 사유에 대한 알림이 없습니다';

  @override
  String get search_title => '검색';

  @override
  String get search_tab_repos => '저장소';

  @override
  String get search_tab_user => '사용자';

  @override
  String get search_tab_issue => 'Issue';

  @override
  String get search_tab_code => '코드';

  @override
  String get release_tab_release => '릴리스';

  @override
  String get release_tab_tag => '태그';

  @override
  String get user_profile_name => '이름';

  @override
  String get user_profile_email => '이메일';

  @override
  String get user_profile_link => '링크';

  @override
  String get user_profile_org => '회사';

  @override
  String get user_profile_location => '위치';

  @override
  String get user_profile_info => '정보';

  @override
  String get search_type => '유형';

  @override
  String get search_sort => '정렬';

  @override
  String get search_language => '언어';

  @override
  String get search_filter_type_best_match => '최적 일치';

  @override
  String get search_filter_type_stars => '스타 수';

  @override
  String get search_filter_type_forks => '포크 수';

  @override
  String get search_filter_type_updated => '최근 업데이트';

  @override
  String get search_sort_desc => '내림차순';

  @override
  String get search_sort_asc => '오름차순';

  @override
  String get search_history_title => '검색 기록';

  @override
  String get search_history_empty_hint => '키워드를 입력하여 검색을 시작하세요';

  @override
  String get search_history_clear => '지우기';

  @override
  String get search_history_clear_confirm => '검색 기록을 지우시겠습니까?';

  @override
  String get feed_back_tip => '귀하의 피드백은 Github에 공개 이슈로 제출됩니다';

  @override
  String get issue_badge_bot => '봇';

  @override
  String get issue_badge_edited => '편집됨';

  @override
  String get issue_comment_minimized => '이 댓글은 접혔습니다';

  @override
  String get issue_reactions_add_tooltip => '리액션 추가';

  @override
  String get issue_reaction_failed => '리액션 실패';

  @override
  String get issue_reaction_remove_failed => '리액션 취소 실패';

  @override
  String get issue_assoc_owner => '소유자';

  @override
  String get issue_assoc_member => '멤버';

  @override
  String get issue_assoc_collaborator => '협업자';

  @override
  String get issue_assoc_contributor => '기여자';

  @override
  String get issue_assoc_first_time_contributor => '첫 기여자';

  @override
  String get issue_assoc_first_timer => '첫 참여자';

  @override
  String get issue_assoc_mannequin => '마네킹';

  @override
  String issue_timeline_labeled(String actor, String label) {
    return '$actor 님이 라벨 $label 을(를) 추가했습니다';
  }

  @override
  String issue_timeline_unlabeled(String actor, String label) {
    return '$actor 님이 라벨 $label 을(를) 제거했습니다';
  }

  @override
  String issue_timeline_assigned(String actor, String assignee) {
    return '$actor 님이 $assignee 을(를) 할당했습니다';
  }

  @override
  String issue_timeline_unassigned(String actor, String assignee) {
    return '$actor 님이 $assignee 의 할당을 해제했습니다';
  }

  @override
  String issue_timeline_milestoned(String actor, String milestone) {
    return '$actor 님이 마일스톤 $milestone 에 추가했습니다';
  }

  @override
  String issue_timeline_demilestoned(String actor, String milestone) {
    return '$actor 님이 마일스톤 $milestone 에서 제거했습니다';
  }

  @override
  String issue_timeline_renamed(String actor, String from, String to) {
    return '$actor 님이 제목을 $from 에서 $to (으)로 변경했습니다';
  }

  @override
  String issue_timeline_closed(String actor) {
    return '$actor 님이 이 이슈를 닫았습니다';
  }

  @override
  String issue_timeline_reopened(String actor) {
    return '$actor 님이 이 이슈를 다시 열었습니다';
  }

  @override
  String issue_timeline_locked(String actor) {
    return '$actor 님이 대화를 잠갔습니다';
  }

  @override
  String issue_timeline_unlocked(String actor) {
    return '$actor 님이 대화 잠금을 해제했습니다';
  }

  @override
  String issue_timeline_pinned(String actor) {
    return '$actor 님이 고정했습니다';
  }

  @override
  String issue_timeline_unpinned(String actor) {
    return '$actor 님이 고정을 해제했습니다';
  }

  @override
  String issue_timeline_merged(String actor) {
    return '$actor 님이 병합했습니다';
  }

  @override
  String issue_timeline_referenced(String actor) {
    return '$actor 님이 이 이슈를 참조했습니다';
  }

  @override
  String issue_timeline_cross_referenced(String actor) {
    return '$actor 님이 다른 이슈에서 이 이슈를 언급했습니다';
  }

  @override
  String issue_timeline_mentioned(String actor) {
    return '$actor 님이 언급되었습니다';
  }

  @override
  String issue_timeline_subscribed(String actor) {
    return '$actor 님이 구독했습니다';
  }

  @override
  String issue_timeline_unsubscribed(String actor) {
    return '$actor 님이 구독을 해제했습니다';
  }

  @override
  String issue_timeline_generic(String actor, String event) {
    return '$actor $event';
  }

  @override
  String get pr_state_merged => '머지됨';

  @override
  String get pr_state_draft => '초안';

  @override
  String get pr_review_requested => '리뷰 요청:';

  @override
  String pr_files_changed(int count) {
    return '$count개 파일 변경';
  }

  @override
  String pr_commits(int count) {
    return '$count개 커밋';
  }

  @override
  String pr_timeline_reviewed_approved(String actor) {
    return '$actor 님이 변경 사항을 승인했습니다';
  }

  @override
  String pr_timeline_reviewed_changes_requested(String actor) {
    return '$actor 님이 변경을 요청했습니다';
  }

  @override
  String pr_timeline_reviewed_commented(String actor) {
    return '$actor 님이 리뷰했습니다';
  }

  @override
  String pr_timeline_reviewed_dismissed(String actor) {
    return '$actor 님이 리뷰를 취소했습니다';
  }

  @override
  String pr_timeline_review_requested(String actor, String reviewer) {
    return '$actor 님이 $reviewer 에게 리뷰를 요청했습니다';
  }

  @override
  String pr_timeline_review_request_removed(String actor, String reviewer) {
    return '$actor 님이 $reviewer 에 대한 리뷰 요청을 취소했습니다';
  }

  @override
  String pr_timeline_ready_for_review(String actor) {
    return '$actor 님이 이 PR을 리뷰 가능 상태로 표시했습니다';
  }

  @override
  String pr_timeline_convert_to_draft(String actor) {
    return '$actor 님이 이 PR을 초안으로 전환했습니다';
  }

  @override
  String pr_timeline_head_ref_force_pushed(String actor) {
    return '$actor 님이 헤드 브랜치를 강제 푸시했습니다';
  }

  @override
  String pr_timeline_base_ref_force_pushed(String actor) {
    return '$actor 님이 베이스 브랜치를 강제 푸시했습니다';
  }

  @override
  String pr_timeline_head_ref_deleted(String actor) {
    return '$actor 님이 헤드 브랜치를 삭제했습니다';
  }

  @override
  String pr_timeline_head_ref_restored(String actor) {
    return '$actor 님이 헤드 브랜치를 복원했습니다';
  }

  @override
  String pr_timeline_base_ref_changed(String actor) {
    return '$actor 님이 베이스 브랜치를 변경했습니다';
  }

  @override
  String pr_timeline_auto_merge_enabled(String actor) {
    return '$actor 님이 자동 병합을 활성화했습니다';
  }

  @override
  String pr_timeline_auto_merge_disabled(String actor) {
    return '$actor 님이 자동 병합을 비활성화했습니다';
  }

  @override
  String pr_timeline_committed(String actor, String shortSha, String message) {
    return '$actor 님이 $shortSha 를 커밋했습니다 — $message';
  }

  @override
  String pr_timeline_committed_no_message(String actor, String shortSha) {
    return '$actor 님이 $shortSha 를 커밋했습니다';
  }

  @override
  String pr_timeline_copilot_work_started(String actor) {
    return '$actor 님이 이 PR 작업을 시작했습니다';
  }

  @override
  String pr_timeline_copilot_work_finished(String actor) {
    return '$actor 님이 이 PR 작업을 완료했습니다';
  }

  @override
  String pr_timeline_added_to_merge_queue(String actor) {
    return '$actor 님이 이 PR을 병합 대기열에 추가했습니다';
  }

  @override
  String pr_timeline_removed_from_merge_queue(String actor) {
    return '$actor 님이 이 PR을 병합 대기열에서 제거했습니다';
  }

  @override
  String issue_timeline_added_to_project(String actor) {
    return '$actor 님이 프로젝트에 추가했습니다';
  }

  @override
  String issue_timeline_project_status_changed(String actor) {
    return '$actor 님이 프로젝트 상태를 변경했습니다';
  }

  @override
  String issue_timeline_issue_type_added(String actor) {
    return '$actor 님이 Issue 유형을 설정했습니다';
  }

  @override
  String event_dynamic_commit_comment(String repo) {
    return '$repo 에서 커밋에 댓글을 남겼습니다';
  }

  @override
  String event_dynamic_create_repository(String repo) {
    return '리포지토리 $repo 를 생성했습니다';
  }

  @override
  String event_dynamic_create_ref(String refType, String ref, String repo) {
    return '$repo 에서 $refType $ref 를 생성했습니다';
  }

  @override
  String event_dynamic_delete_ref(String refType, String ref, String repo) {
    return '$repo 에서 $refType $ref 를 삭제했습니다';
  }

  @override
  String event_dynamic_fork_full(String fromRepo, String forker) {
    return '$fromRepo 를 $forker/$fromRepo 로 fork 했습니다';
  }

  @override
  String event_dynamic_fork_repo(String repo) {
    return '$repo 를 fork 했습니다';
  }

  @override
  String get event_dynamic_fork_generic => '리포지토리를 fork 했습니다';

  @override
  String event_dynamic_gollum(String actor) {
    return '$actor 님이 wiki 를 편집했습니다';
  }

  @override
  String event_dynamic_installation(String action) {
    return 'GitHub App 을 $action 했습니다';
  }

  @override
  String event_dynamic_installation_repos(String action) {
    return '설치의 리포지토리를 $action 했습니다';
  }

  @override
  String event_dynamic_issue_comment(
    String action,
    String number,
    String repo,
  ) {
    return '$repo 의 issue #$number 댓글을 $action 했습니다';
  }

  @override
  String event_dynamic_issue(String action, String number, String repo) {
    return '$repo 의 issue #$number 를 $action 했습니다';
  }

  @override
  String event_dynamic_marketplace(String action) {
    return 'marketplace 요금제를 $action 했습니다';
  }

  @override
  String event_dynamic_member(String action, String repo) {
    return '$repo 의 멤버를 $action 했습니다';
  }

  @override
  String event_dynamic_org_block(String action) {
    return '사용자를 $action 했습니다';
  }

  @override
  String event_dynamic_project_card(String action) {
    return '프로젝트 카드를 $action 했습니다';
  }

  @override
  String event_dynamic_project_column(String action) {
    return '프로젝트 열을 $action 했습니다';
  }

  @override
  String event_dynamic_project(String action) {
    return '프로젝트를 $action 했습니다';
  }

  @override
  String event_dynamic_public(String repo) {
    return '$repo 를 공개했습니다';
  }

  @override
  String event_dynamic_pull_request(String action, String repo) {
    return '$repo 에서 PR 을 $action 했습니다';
  }

  @override
  String event_dynamic_pull_request_review(String action, String repo) {
    return '$repo 에서 PR review 를 $action 했습니다';
  }

  @override
  String event_dynamic_pull_request_review_comment(String action, String repo) {
    return '$repo 에서 PR review 댓글을 $action 했습니다';
  }

  @override
  String event_dynamic_push(String ref, String repo) {
    return '$repo 의 $ref 에 push 했습니다';
  }

  @override
  String event_dynamic_release(String action, String tag, String repo) {
    return '$repo 에서 release $tag 를 $action 했습니다';
  }

  @override
  String event_dynamic_discussion(String action, String repo) {
    return '$repo 에서 토론을 $action 했습니다';
  }

  @override
  String event_dynamic_discussion_comment(String action, String repo) {
    return '$repo 에서 토론 댓글을 $action 했습니다';
  }

  @override
  String event_dynamic_pull_request_review_thread(String action, String repo) {
    return '$repo 에서 PR 리뷰 스레드를 $action 했습니다';
  }

  @override
  String get discussion_load_failed => 'Discussion 을 불러오지 못했습니다';

  @override
  String get discussion_not_found => 'Discussion 을 찾을 수 없습니다';

  @override
  String get discussion_retry => '다시 시도';

  @override
  String get discussion_answered_badge => '답변 완료';

  @override
  String get discussion_empty_body => '이 Discussion 에는 본문이 없습니다';

  @override
  String get discussion_skeleton_notice =>
      '댓글 / 투표 / 답변 표시 등의 상호작용은 후속 서브태스크에서 추가됩니다 (roadmap §3.1).';

  @override
  String discussion_comments_count(int count) {
    return '댓글 $count 개';
  }

  @override
  String event_dynamic_sponsorship(String action) {
    return '스폰서십을 $action 했습니다';
  }

  @override
  String event_dynamic_watch(String action, String repo) {
    return '$repo 를 $action 했습니다';
  }

  @override
  String event_dynamic_watch_started(String repo) {
    return '$repo 에 별표를 표시했습니다';
  }

  @override
  String event_dynamic_push_head(String sha) {
    return 'head: $sha';
  }

  @override
  String get event_dynamic_push_commit_fallback => '커밋';

  @override
  String get event_action_started => '스타를 눌렀습니다';

  @override
  String get event_action_opened => '열기';

  @override
  String get event_action_edited => '편집';

  @override
  String get event_action_closed => '닫기';

  @override
  String get event_action_reopened => '다시 열기';

  @override
  String get event_action_assigned => '할당';

  @override
  String get event_action_unassigned => '할당 해제';

  @override
  String get event_action_labeled => '라벨 지정';

  @override
  String get event_action_unlabeled => '라벨 제거';

  @override
  String get event_action_created => '생성';

  @override
  String get event_action_deleted => '삭제';

  @override
  String get event_action_review_requested => '리뷰 요청';

  @override
  String get event_action_review_request_removed => '리뷰 요청 취소';

  @override
  String get event_action_synchronize => '업데이트';

  @override
  String get event_action_ready_for_review => '리뷰 준비됨으로 변경';

  @override
  String get event_action_dismissed => '거절';

  @override
  String get event_action_submitted => '제출';

  @override
  String get event_action_published => '게시';

  @override
  String get event_action_prereleased => '프리릴리스';

  @override
  String get event_action_released => '릴리스';

  @override
  String get event_action_added => '추가';

  @override
  String get event_action_removed => '제거';

  @override
  String get event_action_suspend => '일시 중지';

  @override
  String get event_action_unsuspend => '재개';

  @override
  String get event_action_new_permissions_accepted => '새 권한 수락';

  @override
  String get event_action_purchased => '구매';

  @override
  String get event_action_cancelled => '취소';

  @override
  String get event_action_pending_change => '변경 대기 중';

  @override
  String get event_action_pending_change_cancelled => '대기 중인 변경 취소';

  @override
  String get event_action_changed => '변경';

  @override
  String get event_action_moved => '이동';

  @override
  String get event_action_blocked => '차단';

  @override
  String get event_action_unblocked => '차단 해제';

  @override
  String get event_action_merged => '병합';

  @override
  String get event_action_auto_merge_enabled => '자동 병합 활성화';

  @override
  String get event_action_auto_merge_disabled => '자동 병합 비활성화';

  @override
  String get event_action_converted_to_draft => '초안으로 변환';

  @override
  String get event_action_locked => '잠금';

  @override
  String get event_action_unlocked => '잠금 해제';

  @override
  String get event_action_pinned => '고정';

  @override
  String get event_action_unpinned => '고정 해제';

  @override
  String get event_action_transferred => '이관';

  @override
  String get event_action_milestoned => '마일스톤 지정';

  @override
  String get event_action_demilestoned => '마일스톤 해제';

  @override
  String get event_action_answered => '답변으로 표시';

  @override
  String get event_action_unanswered => '답변 표시 해제';

  @override
  String get event_action_category_changed => '카테고리 변경';

  @override
  String get event_action_resolved => '해결됨으로 표시';

  @override
  String get event_action_unresolved => '해결됨 취소';

  @override
  String get event_action_marked_as_duplicate => '중복으로 표시';

  @override
  String get event_action_unmarked_as_duplicate => '중복 표시 해제';

  @override
  String get event_action_enqueued => '병합 큐에 추가';

  @override
  String get event_action_dequeued => '병합 큐에서 제거';

  @override
  String get event_action_deployed => '배포됨';

  @override
  String get event_action_updated => '업데이트';

  @override
  String get event_action_withdrawn => '철회';

  @override
  String get event_action_performed => '수행';

  @override
  String get event_advisory_severity_critical => '심각';

  @override
  String get event_advisory_severity_high => '높음';

  @override
  String get event_advisory_severity_moderate => '중간';

  @override
  String get event_advisory_severity_low => '낮음';

  @override
  String get event_advisory_severity_unknown => '알 수 없음';

  @override
  String event_dynamic_security_advisory(
    String action,
    String ghsaId,
    String severity,
  ) {
    return '보안 권고 $ghsaId($severity) $action';
  }

  @override
  String event_dynamic_security_advisory_no_id(String action, String severity) {
    return '보안 권고($severity) $action';
  }

  @override
  String get option_pr_files => '변경 파일';

  @override
  String pr_files_title(int number) {
    return 'PR #$number 변경 파일';
  }

  @override
  String pr_files_review_comments_count(int count) {
    return '리뷰 코멘트 $count개';
  }

  @override
  String pr_files_review_line(int line) {
    return '$line번째 줄';
  }

  @override
  String get pr_files_review_outdated => '이 코멘트는 오래되었습니다';

  @override
  String get pr_files_review_thread_resolved => '해결됨';

  @override
  String get pr_files_review_thread_unresolved => '미해결';
}
