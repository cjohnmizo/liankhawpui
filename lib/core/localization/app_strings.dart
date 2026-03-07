import 'package:flutter/widgets.dart';

enum AppLanguage {
  english('en'),
  mizo('lus');

  const AppLanguage(this.storageCode);

  final String storageCode;

  static AppLanguage fromStorageCode(String? value) {
    for (final language in AppLanguage.values) {
      if (language.storageCode == value) {
        return language;
      }
    }
    return AppLanguage.english;
  }
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isMizo => language == AppLanguage.mizo;

  String get settings => _value('Settings', 'Thil remna');
  String get settingsIntro => _value(
    'Adjust language, reading comfort, and sync preferences.',
    'Tawng, chhiar nuamna leh sync setting siamthat rawh.',
  );
  String get appearance => _value('Appearance', 'Lang leh hmel');
  String get darkMode => _value('Dark Mode', 'Theme muthim');
  String get darkModeSubtitle =>
      _value('Enable dark theme for the app', 'App hmuh dan muthim siam');
  String get fontSize => _value('Font Size', 'Font lian dan');
  String get fontSizeSubtitle => _value(
    'Adjust text size across the app',
    'App pum pui ah thuziak lian dan siamthat',
  );
  String get reset => _value('Reset', 'Rem that leh');
  String get languageLabel => _value('Language', 'Tawng');
  String get languageSubtitle =>
      _value('Choose your app language', 'App hmang tawng thlang rawh');
  String get english => 'English';
  String get mizo => 'Mizo';
  String get networkAndSync => _value('Network & Sync', 'Network leh Sync');
  String get lowDataMode => _value('Low Data Mode', 'Data tlem mode');
  String get lowDataModeSubtitle => _value(
    'Reduce image quality and bandwidth usage',
    'Thlalak quality leh data hman tlem tur',
  );
  String get notifications => _value('Notifications', 'Notification');
  String get enablePushNotifications =>
      _value('Enable Push Notifications', 'Push notification siam');
  String get enablePushNotificationsSubtitle => _value(
    'Allow announcement and news alerts on this device',
    'He device ah hriattirna leh chanchin thar alert siam',
  );
  String get notificationPermissionRequested => _value(
    'Notification permission request sent.',
    'Notification phalna dil a ni tawh.',
  );
  String get about => _value('About', 'Chungchang');
  String get version => _value('Version', 'Version');
  String get privacyPolicy => _value('Privacy Policy', 'Privacy Policy');
  String get termsOfService => _value('Terms of Service', 'Terms of Service');
  String get aboutAppUs => _value('About App / Us', 'App / Kan chungchang');
  String get syncStatus => _value('Sync Status', 'Sync dinhmun');
  String get connection => _value('Connection', 'Connection');
  String get lastSynced => _value('Last Synced', 'Hnuhnung sync');
  String get uploadQueue => _value('Upload Queue', 'Upload queue');
  String get lastError => _value('Last Error', 'Hnuhnung hmanhmawh');
  String get syncNow => _value('Sync Now', 'Tunah sync');
  String get syncRefreshRequested =>
      _value('Sync refresh requested.', 'Sync tihthar dil a ni tawh.');
  String get remoteSyncDisabled =>
      _value('Remote sync disabled', 'Remote sync tihloh');
  String get signInToSync => _value('Sign in to sync', 'Sync atan lut rawh');
  String get checking => _value('Checking...', 'En mek...');
  String get connecting => _value('Connecting', 'Zawm mek');
  String get syncing => _value('Syncing', 'Sync mek');
  String get connected => _value('Connected', 'Zawm a ni');
  String get reconnecting => _value('Reconnecting', 'Zawm leh mek');
  String get offline => _value('Offline', 'Offline');
  String get notYet => _value('Not yet', 'A la ni lo');
  String get loading => _value('Loading...', 'Loading...');
  String get home => _value('Home', 'In');
  String get news => _value('News', 'Chanchin');
  String get announcements => _value('Announcements', 'Hriattirna');
  String get organizations => _value('Organizations', 'Pawl hrang hrang');
  String get directory => _value('Directory', 'Khawlian Chanchin');
  String get guest => _value('Guest', 'Khual');
  String get communityMember => _value('Community Member', 'Khaw chhunga mi');
  String get guestSubtitle =>
      _value('Sign in to access more', 'A tam zawk hmuh nan lut rawh');
  String get myProfile => _value('My Profile', 'Ka profile');
  String get adminDashboard => _value('Admin Dashboard', 'Admin dashboard');
  String get signIn => _value('Sign In', 'Lut');
  String get signOut => _value('Sign Out', 'Chhuak');
  String get createPost => _value('Create post', 'Thu siam');
  String get offlineReconnectToCreateContent => _value(
    'Offline mode: reconnect to create content',
    'Offline a ni. Siamna tur atan internet nen zawng leh rawh',
  );
  String get dashboard => _value('Dashboard', 'Dashboard');
  String get profile => _value('Profile', 'Profile');
  String get recentNews => _value('Recent News', 'Chanchin thar hnuhnung');
  String get latestStoriesFromVillage => _value(
    'Latest stories from the village',
    'Khaw chhung thil thleng thar ber',
  );
  String get openNews => _value('Open news', 'Chanchin en');
  String get loadingRecentNews =>
      _value('Loading recent news...', 'Chanchin thar load mek...');
  String get couldNotLoadRecentNews =>
      _value('Could not load recent news', 'Chanchin thar load theih loh');
  String get noNewsPublishedYet =>
      _value('No news published yet', 'Chanchin a la awm lo');
  String get villageUpdatesAndNotices => _value(
    'Village updates and notices',
    'Khaw chhung hriattirna leh puanchhuahna',
  );
  String get viewAll => _value('View all', 'A zawngin en');
  String get noAnnouncementsYet =>
      _value('No announcements yet', 'Hriattirna a la awm lo');
  String get loadingAnnouncements =>
      _value('Loading announcements...', 'Hriattirna load mek...');
  String get couldNotLoadAnnouncements =>
      _value('Could not load announcements', 'Hriattirna load theih loh');
  String get organizationList =>
      _value('Organization List', 'Pawl hrang hrang');
  String get villageGroupsInGridView =>
      _value('Village groups in grid view', 'Khaw chhung pawl hrang hrang');
  String get browse => _value('Browse', 'Zawng');
  String get noOrganizationsAvailable =>
      _value('No organizations available', 'Pawl hrang hrang a la awm lo');
  String get loadingOrganizations =>
      _value('Loading organizations...', 'Pawl hrang hrang load mek...');
  String get couldNotLoadOrganizations =>
      _value('Could not load organizations', 'Pawl hrang hrang load theih loh');
  String get newsArticle => _value('News Article', 'Chanchin ziakna');
  String get announcement => _value('Announcement', 'Hriattirna');
  String get khawlianVillage => _value('Khawlian Village', 'Khawlian Khua');
  String get communityUpdates =>
      _value('Community Updates', 'Khaw chhung hriattirna');
  String get newsAnnouncementsOrganizations => _value(
    'News, announcements, and organizations',
    'Chanchin, hriattirna leh pawl hrang hrang',
  );
  String get offlineCache => _value('Offline cache', 'Offline cache');
  String get pinned => _value('Pinned', 'Dah');
  String get profileTitle => _value('Profile', 'Profile');
  String get accountDetails => _value('Account Details', 'Account chungchang');
  String get savedPosts => _value('Saved Posts', 'Thu vawn');
  String get comingSoon => _value('Coming soon', 'A lo thleng dawn');
  String get phone => _value('Phone', 'Phone');
  String get dateOfBirth => _value('Date of Birth', 'Pianni');
  String get address => _value('Address', 'Address');
  String get notSet => _value('Not set', 'Dah lo');
  String get noEmail => _value('No email', 'Email awm lo');
  String get newsFeed => _value('News Feed', 'Chanchin feed');
  String get searchOrganizations =>
      _value('Search organizations', 'Pawl hrang hrang zawng');
  String get noOrganizationsFoundForThisSearch => _value(
    'No organizations found for this search',
    'He zawhna atan pawl hrang hrang hmuh a ni lo',
  );

  String appVersion(String version) =>
      _value('App Version $version', 'App Version $version');

  String languageName(AppLanguage value) {
    switch (value) {
      case AppLanguage.english:
        return english;
      case AppLanguage.mizo:
        return mizo;
    }
  }

  String roleLabel(String value) {
    switch (value.toLowerCase()) {
      case 'guest':
        return guest;
      case 'user':
        return _value('User', 'Hmangtu');
      case 'editor':
        return _value('Editor', 'Editor');
      case 'admin':
        return _value('Admin', 'Admin');
      default:
        return value;
    }
  }

  String _value(String englishValue, String mizoValue) {
    return isMizo ? mizoValue : englishValue;
  }
}

class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    assert(scope != null, 'AppStringsScope not found in widget tree.');
    return scope!.strings;
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) {
    return oldWidget.strings.language != strings.language;
  }
}

extension AppStringsBuildContextX on BuildContext {
  AppStrings get t => AppStringsScope.of(this);
}
