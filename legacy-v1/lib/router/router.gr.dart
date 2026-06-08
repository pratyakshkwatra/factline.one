// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i14;
import 'package:factline/api/models/game.dart' as _i19;
import 'package:factline/api/models/post.dart' as _i18;
import 'package:factline/api/models/user.dart' as _i20;
import 'package:factline/loading.dart' as _i8;
import 'package:factline/screens/add_post.dart' as _i1;
import 'package:factline/screens/auth/create_account.dart' as _i2;
import 'package:factline/screens/auth/login.dart' as _i9;
import 'package:factline/screens/forensic_report.dart' as _i3;
import 'package:factline/screens/game_play.dart' as _i4;
import 'package:factline/screens/language_selection.dart' as _i6;
import 'package:factline/screens/leaderboard.dart' as _i7;
import 'package:factline/screens/map.dart' as _i10;
import 'package:factline/screens/news_full.dart' as _i11;
import 'package:factline/screens/recommendations_full.dart' as _i12;
import 'package:factline/screens/settings.dart' as _i13;
import 'package:factline/screens/tab_view.dart' as _i5;
import 'package:factline/services/auth.dart' as _i16;
import 'package:flutter/material.dart' as _i15;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i17;

/// generated route for
/// [_i1.AddPostScreen]
class AddPostRoute extends _i14.PageRouteInfo<AddPostRouteArgs> {
  AddPostRoute({
    _i15.Key? key,
    required _i16.AuthService authService,
    required _i17.FlutterSecureStorage secureStorage,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         AddPostRoute.name,
         args: AddPostRouteArgs(
           key: key,
           authService: authService,
           secureStorage: secureStorage,
         ),
         initialChildren: children,
       );

  static const String name = 'AddPostRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddPostRouteArgs>();
      return _i1.AddPostScreen(
        key: args.key,
        authService: args.authService,
        secureStorage: args.secureStorage,
      );
    },
  );
}

class AddPostRouteArgs {
  const AddPostRouteArgs({
    this.key,
    required this.authService,
    required this.secureStorage,
  });

  final _i15.Key? key;

  final _i16.AuthService authService;

  final _i17.FlutterSecureStorage secureStorage;

  @override
  String toString() {
    return 'AddPostRouteArgs{key: $key, authService: $authService, secureStorage: $secureStorage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddPostRouteArgs) return false;
    return key == other.key &&
        authService == other.authService &&
        secureStorage == other.secureStorage;
  }

  @override
  int get hashCode =>
      key.hashCode ^ authService.hashCode ^ secureStorage.hashCode;
}

/// generated route for
/// [_i2.CreateAccountScreen]
class CreateAccountRoute extends _i14.PageRouteInfo<CreateAccountRouteArgs> {
  CreateAccountRoute({
    _i15.Key? key,
    required _i16.AuthService authService,
    required _i17.FlutterSecureStorage secureStorage,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         CreateAccountRoute.name,
         args: CreateAccountRouteArgs(
           key: key,
           authService: authService,
           secureStorage: secureStorage,
         ),
         initialChildren: children,
       );

  static const String name = 'CreateAccountRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CreateAccountRouteArgs>();
      return _i2.CreateAccountScreen(
        key: args.key,
        authService: args.authService,
        secureStorage: args.secureStorage,
      );
    },
  );
}

class CreateAccountRouteArgs {
  const CreateAccountRouteArgs({
    this.key,
    required this.authService,
    required this.secureStorage,
  });

  final _i15.Key? key;

  final _i16.AuthService authService;

  final _i17.FlutterSecureStorage secureStorage;

  @override
  String toString() {
    return 'CreateAccountRouteArgs{key: $key, authService: $authService, secureStorage: $secureStorage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CreateAccountRouteArgs) return false;
    return key == other.key &&
        authService == other.authService &&
        secureStorage == other.secureStorage;
  }

  @override
  int get hashCode =>
      key.hashCode ^ authService.hashCode ^ secureStorage.hashCode;
}

/// generated route for
/// [_i3.ForensicReportScreen]
class ForensicReportRoute extends _i14.PageRouteInfo<ForensicReportRouteArgs> {
  ForensicReportRoute({
    _i15.Key? key,
    required _i18.Post post,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         ForensicReportRoute.name,
         args: ForensicReportRouteArgs(key: key, post: post),
         initialChildren: children,
       );

  static const String name = 'ForensicReportRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ForensicReportRouteArgs>();
      return _i3.ForensicReportScreen(key: args.key, post: args.post);
    },
  );
}

class ForensicReportRouteArgs {
  const ForensicReportRouteArgs({this.key, required this.post});

  final _i15.Key? key;

  final _i18.Post post;

  @override
  String toString() {
    return 'ForensicReportRouteArgs{key: $key, post: $post}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ForensicReportRouteArgs) return false;
    return key == other.key && post == other.post;
  }

  @override
  int get hashCode => key.hashCode ^ post.hashCode;
}

/// generated route for
/// [_i4.GamePlayScreen]
class GamePlayRoute extends _i14.PageRouteInfo<GamePlayRouteArgs> {
  GamePlayRoute({
    _i15.Key? key,
    required _i19.GameArticle article,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         GamePlayRoute.name,
         args: GamePlayRouteArgs(key: key, article: article),
         initialChildren: children,
       );

  static const String name = 'GamePlayRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<GamePlayRouteArgs>();
      return _i4.GamePlayScreen(key: args.key, article: args.article);
    },
  );
}

class GamePlayRouteArgs {
  const GamePlayRouteArgs({this.key, required this.article});

  final _i15.Key? key;

  final _i19.GameArticle article;

  @override
  String toString() {
    return 'GamePlayRouteArgs{key: $key, article: $article}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GamePlayRouteArgs) return false;
    return key == other.key && article == other.article;
  }

  @override
  int get hashCode => key.hashCode ^ article.hashCode;
}

/// generated route for
/// [_i5.HomeScreen]
class HomeRoute extends _i14.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    _i15.Key? key,
    required _i16.AuthService authService,
    required _i17.FlutterSecureStorage secureStorage,
    required _i20.User user,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         HomeRoute.name,
         args: HomeRouteArgs(
           key: key,
           authService: authService,
           secureStorage: secureStorage,
           user: user,
         ),
         initialChildren: children,
       );

  static const String name = 'HomeRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HomeRouteArgs>();
      return _i5.HomeScreen(
        key: args.key,
        authService: args.authService,
        secureStorage: args.secureStorage,
        user: args.user,
      );
    },
  );
}

class HomeRouteArgs {
  const HomeRouteArgs({
    this.key,
    required this.authService,
    required this.secureStorage,
    required this.user,
  });

  final _i15.Key? key;

  final _i16.AuthService authService;

  final _i17.FlutterSecureStorage secureStorage;

  final _i20.User user;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, authService: $authService, secureStorage: $secureStorage, user: $user}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeRouteArgs) return false;
    return key == other.key &&
        authService == other.authService &&
        secureStorage == other.secureStorage &&
        user == other.user;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      authService.hashCode ^
      secureStorage.hashCode ^
      user.hashCode;
}

/// generated route for
/// [_i6.LanguageSelectionScreen]
class LanguageSelectionRoute
    extends _i14.PageRouteInfo<LanguageSelectionRouteArgs> {
  LanguageSelectionRoute({
    _i15.Key? key,
    required _i16.AuthService authService,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         LanguageSelectionRoute.name,
         args: LanguageSelectionRouteArgs(key: key, authService: authService),
         initialChildren: children,
       );

  static const String name = 'LanguageSelectionRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LanguageSelectionRouteArgs>();
      return _i6.LanguageSelectionScreen(
        key: args.key,
        authService: args.authService,
      );
    },
  );
}

class LanguageSelectionRouteArgs {
  const LanguageSelectionRouteArgs({this.key, required this.authService});

  final _i15.Key? key;

  final _i16.AuthService authService;

  @override
  String toString() {
    return 'LanguageSelectionRouteArgs{key: $key, authService: $authService}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LanguageSelectionRouteArgs) return false;
    return key == other.key && authService == other.authService;
  }

  @override
  int get hashCode => key.hashCode ^ authService.hashCode;
}

/// generated route for
/// [_i7.LeaderboardScreen]
class LeaderboardRoute extends _i14.PageRouteInfo<LeaderboardRouteArgs> {
  LeaderboardRoute({
    _i15.Key? key,
    required _i16.AuthService authService,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         LeaderboardRoute.name,
         args: LeaderboardRouteArgs(key: key, authService: authService),
         initialChildren: children,
       );

  static const String name = 'LeaderboardRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LeaderboardRouteArgs>();
      return _i7.LeaderboardScreen(
        key: args.key,
        authService: args.authService,
      );
    },
  );
}

class LeaderboardRouteArgs {
  const LeaderboardRouteArgs({this.key, required this.authService});

  final _i15.Key? key;

  final _i16.AuthService authService;

  @override
  String toString() {
    return 'LeaderboardRouteArgs{key: $key, authService: $authService}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LeaderboardRouteArgs) return false;
    return key == other.key && authService == other.authService;
  }

  @override
  int get hashCode => key.hashCode ^ authService.hashCode;
}

/// generated route for
/// [_i8.LoadingScreen]
class LoadingRoute extends _i14.PageRouteInfo<void> {
  const LoadingRoute({List<_i14.PageRouteInfo>? children})
    : super(LoadingRoute.name, initialChildren: children);

  static const String name = 'LoadingRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i8.LoadingScreen();
    },
  );
}

/// generated route for
/// [_i9.LoginScreen]
class LoginRoute extends _i14.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i15.Key? key,
    required _i16.AuthService authService,
    required _i17.FlutterSecureStorage secureStorage,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(
           key: key,
           authService: authService,
           secureStorage: secureStorage,
         ),
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LoginRouteArgs>();
      return _i9.LoginScreen(
        key: args.key,
        authService: args.authService,
        secureStorage: args.secureStorage,
      );
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({
    this.key,
    required this.authService,
    required this.secureStorage,
  });

  final _i15.Key? key;

  final _i16.AuthService authService;

  final _i17.FlutterSecureStorage secureStorage;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, authService: $authService, secureStorage: $secureStorage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key &&
        authService == other.authService &&
        secureStorage == other.secureStorage;
  }

  @override
  int get hashCode =>
      key.hashCode ^ authService.hashCode ^ secureStorage.hashCode;
}

/// generated route for
/// [_i10.MapScreen]
class MapRoute extends _i14.PageRouteInfo<MapRouteArgs> {
  MapRoute({
    _i15.Key? key,
    required _i16.AuthService authService,
    required _i20.User user,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         MapRoute.name,
         args: MapRouteArgs(key: key, authService: authService, user: user),
         initialChildren: children,
       );

  static const String name = 'MapRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MapRouteArgs>();
      return _i10.MapScreen(
        key: args.key,
        authService: args.authService,
        user: args.user,
      );
    },
  );
}

class MapRouteArgs {
  const MapRouteArgs({this.key, required this.authService, required this.user});

  final _i15.Key? key;

  final _i16.AuthService authService;

  final _i20.User user;

  @override
  String toString() {
    return 'MapRouteArgs{key: $key, authService: $authService, user: $user}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapRouteArgs) return false;
    return key == other.key &&
        authService == other.authService &&
        user == other.user;
  }

  @override
  int get hashCode => key.hashCode ^ authService.hashCode ^ user.hashCode;
}

/// generated route for
/// [_i11.NewsFullScreen]
class NewsFullRoute extends _i14.PageRouteInfo<NewsFullRouteArgs> {
  NewsFullRoute({
    _i15.Key? key,
    required _i18.Post post,
    required _i16.AuthService authService,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         NewsFullRoute.name,
         args: NewsFullRouteArgs(
           key: key,
           post: post,
           authService: authService,
         ),
         initialChildren: children,
       );

  static const String name = 'NewsFullRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewsFullRouteArgs>();
      return _i11.NewsFullScreen(
        key: args.key,
        post: args.post,
        authService: args.authService,
      );
    },
  );
}

class NewsFullRouteArgs {
  const NewsFullRouteArgs({
    this.key,
    required this.post,
    required this.authService,
  });

  final _i15.Key? key;

  final _i18.Post post;

  final _i16.AuthService authService;

  @override
  String toString() {
    return 'NewsFullRouteArgs{key: $key, post: $post, authService: $authService}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewsFullRouteArgs) return false;
    return key == other.key &&
        post == other.post &&
        authService == other.authService;
  }

  @override
  int get hashCode => key.hashCode ^ post.hashCode ^ authService.hashCode;
}

/// generated route for
/// [_i12.RecommendationsFullScreen]
class RecommendationsFullRoute
    extends _i14.PageRouteInfo<RecommendationsFullRouteArgs> {
  RecommendationsFullRoute({
    _i15.Key? key,
    required _i20.User user,
    required _i16.AuthService authService,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         RecommendationsFullRoute.name,
         args: RecommendationsFullRouteArgs(
           key: key,
           user: user,
           authService: authService,
         ),
         initialChildren: children,
       );

  static const String name = 'RecommendationsFullRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecommendationsFullRouteArgs>();
      return _i12.RecommendationsFullScreen(
        key: args.key,
        user: args.user,
        authService: args.authService,
      );
    },
  );
}

class RecommendationsFullRouteArgs {
  const RecommendationsFullRouteArgs({
    this.key,
    required this.user,
    required this.authService,
  });

  final _i15.Key? key;

  final _i20.User user;

  final _i16.AuthService authService;

  @override
  String toString() {
    return 'RecommendationsFullRouteArgs{key: $key, user: $user, authService: $authService}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecommendationsFullRouteArgs) return false;
    return key == other.key &&
        user == other.user &&
        authService == other.authService;
  }

  @override
  int get hashCode => key.hashCode ^ user.hashCode ^ authService.hashCode;
}

/// generated route for
/// [_i13.SettingsTab]
class SettingsTab extends _i14.PageRouteInfo<SettingsTabArgs> {
  SettingsTab({
    _i15.Key? key,
    required _i16.AuthService authService,
    required _i17.FlutterSecureStorage secureStorage,
    required _i20.User user,
    List<_i14.PageRouteInfo>? children,
  }) : super(
         SettingsTab.name,
         args: SettingsTabArgs(
           key: key,
           authService: authService,
           secureStorage: secureStorage,
           user: user,
         ),
         initialChildren: children,
       );

  static const String name = 'SettingsTab';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SettingsTabArgs>();
      return _i13.SettingsTab(
        key: args.key,
        authService: args.authService,
        secureStorage: args.secureStorage,
        user: args.user,
      );
    },
  );
}

class SettingsTabArgs {
  const SettingsTabArgs({
    this.key,
    required this.authService,
    required this.secureStorage,
    required this.user,
  });

  final _i15.Key? key;

  final _i16.AuthService authService;

  final _i17.FlutterSecureStorage secureStorage;

  final _i20.User user;

  @override
  String toString() {
    return 'SettingsTabArgs{key: $key, authService: $authService, secureStorage: $secureStorage, user: $user}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SettingsTabArgs) return false;
    return key == other.key &&
        authService == other.authService &&
        secureStorage == other.secureStorage &&
        user == other.user;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      authService.hashCode ^
      secureStorage.hashCode ^
      user.hashCode;
}
