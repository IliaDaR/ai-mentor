import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'AI-Ментор';
  static const String appSlogan = 'Учись продуктивности';
  static const String appVersion = '1.0.0';

  // AI
  static const String defaultApiProvider = 'deepseek';
  static const String defaultApiModel = 'deepseek-chat';
  static const String defaultApiBaseUrl =
      'https://api.deepseek.com/v1';
  static const int freeDailyRequests = 10;
  static const int proTrialDays = 7;

  // Focus
  static const int focusMinDuration = 25;
  static const int focusMaxDuration = 90;
  static const int focusDefaultDuration = 50;
  static const int focusPunishmentPoints = -10;
  static const int focusRewardPoints = 25;

  // Gamification
  static const int pointsPerPlanAccepted = 5;
  static const int pointsPerSmartTask = 15;
  static const int pointsPerCorrectQuadrant = 10;
  static const int pointsPerDelegation = 20;
  static const int pointsPerFocusHour = 25;
  static const int pointsPerInboxZero = 30;
  static const int pointsPerWeekNoMistakes = 50;
  static const int pointsPerExplainWhy = 10;

  // Limits (Free version)
  static const int freeMaxTasks = 50;
  static const int freeMaxMeetings = 3;

  // Database
  static const String databaseName = 'ai_mentor.db';
  static const int databaseVersion = 1;

  // Channels
  static const String notificationChannel = 'com.ai_mentor/notifications';
  static const String audioRecorderChannel = 'com.ai_mentor/audio';

  // Colors
  static const Color colorUrgentImportant = Color(0xFFB3261E);
  static const Color colorImportantNotUrgent = Color(0xFFF9AB00);
  static const Color colorUrgentNotImportant = Color(0xFFE65100);
  static const Color colorNotUrgentNotImportant = Color(0xFF757575);
  static const Color colorSuccess = Color(0xFF2E7D32);
  static const Color colorPrimaryLight = Color(0xFF6750A4);
  static const Color colorPrimaryDark = Color(0xFFD0BCFF);

  // Quadrant labels
  static const String labelUrgentImportant = 'Срочно-Важно';
  static const String labelImportantNotUrgent = 'Важно-Не срочно';
  static const String labelUrgentNotImportant = 'Срочно-Неважно';
  static const String labelNotUrgentNotImportant = 'Неважно';

  // Learning stages
  static const String stage1 = 'stage1';
  static const String stage2 = 'stage2';
  static const String stage3 = 'stage3';
  static const String stage4 = 'stage4';
  static const String stage5 = 'stage5';

  static const Map<String, String> stageLabels = {
    stage1: 'ИИ ведёт',
    stage2: 'Совместно',
    stage3: 'Проверка',
    stage4: 'Автономия',
    stage5: 'Наставник',
  };

  // User levels
  static const String levelNovice = 'novice';
  static const String levelApprentice = 'apprentice';
  static const String levelJourneyman = 'journeyman';
  static const String levelMaster = 'master';
  static const String levelAutonomous = 'autonomous';
  static const String levelMentor = 'mentor';

  // Monetization
  static const String proMonthly = 'pro_monthly';
  static const String proYearly = 'pro_yearly';
  static const String proLifetime = 'pro_lifetime';
  static const String proPlusTeam = 'pro_plus_team';
  static const int proMonthlyPrice = 499;
  static const int proYearlyPrice = 2990;
  static const int proLifetimePrice = 6990;
  static const int proPlusTeamPrice = 9990;

  // AdMob
  static const String adUnitIdBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String adUnitIdInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String adUnitIdRewarded =
      'ca-app-pub-3940256099942544/5224354917';
}
