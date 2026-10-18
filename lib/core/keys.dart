import 'package:flutter/widgets.dart';

abstract final class GavelKeys {
  static const ValueKey<String> navHome = ValueKey('nav_home');
  static const ValueKey<String> navCase = ValueKey('nav_case');
  static const ValueKey<String> navResearch = ValueKey('nav_research');
  static const ValueKey<String> navTeam = ValueKey('nav_team');
  static const ValueKey<String> navMe = ValueKey('nav_me');

  static const ValueKey<String> homeActiveCase = ValueKey('home_active_case');
  static const ValueKey<String> homeStatExhibits = ValueKey(
    'home_stat_exhibits',
  );
  static const ValueKey<String> homeStatWitnesses = ValueKey(
    'home_stat_witnesses',
  );
  static const ValueKey<String> homeStatTasks = ValueKey('home_stat_tasks');
  static const ValueKey<String> homeAskCase = ValueKey('home_ask_case');
  static const ValueKey<String> homeAssignments = ValueKey('home_assignments');
  static const ValueKey<String> homeTeamReadiness = ValueKey(
    'home_team_readiness',
  );

  static ValueKey<String> homeAssignment(String taskId) =>
      ValueKey('home_assignment_$taskId');

  static const ValueKey<String> meOpenGallery = ValueKey('me_open_gallery');

  static const ValueKey<String> galleryThemeToggle = ValueKey(
    'gallery_theme_toggle',
  );
  static const ValueKey<String> galleryPushPage = ValueKey('gallery_push_page');
}
