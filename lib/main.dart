/// This is the main entry point for the Otzaria application.
/// The application is a Flutter-based digital library system that supports
/// RTL (Right-to-Left) languages, particularly Hebrew.
/// It includes features for dark mode, customizable themes, and local storage management.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/app.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/bookmarks/repository/bookmark_repository.dart';
import 'package:otzaria/find_ref/find_ref_bloc.dart';
import 'package:otzaria/find_ref/find_ref_repository.dart';
import 'package:otzaria/focus/focus_repository.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/history_repository.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/library/bloc/library_event.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/navigation_repository.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/tabs_repository.dart';
import 'package:otzaria/workspaces/bloc/workspace_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';
import 'package:otzaria/workspaces/workspace_repository.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/app_bloc_observer.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/data/data_providers/hive_data_provider.dart';
import 'package:otzaria/personal_notes/bloc/personal_notes_bloc.dart';
import 'package:otzaria/personal_notes/bloc/personal_notes_event.dart';
import 'package:otzaria/core/app_paths.dart';
import 'package:otzaria/core/window_listener.dart';
import 'package:shamor_zachor/providers/shamor_zachor_data_provider.dart';
import 'package:shamor_zachor/providers/shamor_zachor_progress_provider.dart';
import 'package:shamor_zachor/services/shamor_zachor_service_factory.dart';
import 'package:shamor_zachor/services/dynamic_data_loader_service.dart';
import 'package:otzaria/utils/toc_parser.dart';
import 'package:otzaria/services/sources_books_service.dart';

// Platform-specific imports
import 'main_io.dart' if (dart.library.html) 'main_web.dart' as platform_main;

// Global reference to window listener for cleanup
AppWindowListener? _appWindowListener;

/// Getter for accessing the window listener from other parts of the app
AppWindowListener? get appWindowListener => _appWindowListener;

// Global reference to the dynamic data loader service for Shamor Zachor
DynamicDataLoaderService? _shamorZachorDataLoader;

/// Application entry point that initializes necessary components and launches the app.
void main() async {
  // Setup error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      platform_main.logError(details.toString());
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(FlutterErrorDetails(
        exception: error,
        stack: stack,
      ));
    } else {
      platform_main.logError(error.toString());
    }
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Check for single instance (only on native platforms)
  if (!kIsWeb) {
    final shouldExit = await platform_main.checkSingleInstance();
    if (shouldExit) return;
  }

  // Initialize bloc observer for debugging
  Bloc.observer = AppBlocObserver();

  await initialize();

  final historyRepository = HistoryRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FocusRepository>(
          create: (context) => FocusRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc(
              repository: SettingsRepository(),
            )..add(LoadSettings()),
          ),
          BlocProvider<LibraryBloc>(
            create: (context) => LibraryBloc()..add(LoadLibrary()),
          ),
          BlocProvider<IndexingBloc>(
            create: (context) => IndexingBloc.create(),
          ),
          BlocProvider<HistoryBloc>(
              create: (context) => HistoryBloc(historyRepository)),
          BlocProvider<TabsBloc>(
            create: (context) => TabsBloc(
              repository: TabsRepository(),
            )..add(LoadTabs()),
          ),
          BlocProvider<NavigationBloc>(
            create: (context) => NavigationBloc(
              repository: NavigationRepository(),
              tabsRepository: TabsRepository(),
            )..add(const CheckLibrary()),
          ),
          BlocProvider<FindRefBloc>(
              create: (context) => FindRefBloc(
                  findRefRepository: FindRefRepository(
                      dataRepository: DataRepository.instance))),
          BlocProvider<PersonalNotesBloc>(
            create: (context) =>
                PersonalNotesBloc()..add(const ConvertLegacyNotes()),
          ),
          BlocProvider<BookmarkBloc>(
            create: (context) => BookmarkBloc(BookmarkRepository()),
          ),
          BlocProvider<WorkspaceBloc>(
            create: (context) => WorkspaceBloc(
              repository: WorkspaceRepository(),
              tabsBloc: context.read<TabsBloc>(),
            )..add(LoadWorkspaces()),
          ),
          ChangeNotifierProvider<ShamorZachorDataProvider>(
            lazy: true,
            create: (context) {
              final provider = _shamorZachorDataLoader != null
                  ? ShamorZachorDataProvider.dynamic(_shamorZachorDataLoader!)
                  : ShamorZachorDataProvider();
              return provider;
            },
          ),
          ChangeNotifierProvider<ShamorZachorProgressProvider>(
            create: (context) => ShamorZachorProgressProvider(),
          ),
        ],
        child: const App(),
      ),
    ),
  );
}

/// Initializes all required services and configurations for the application.
Future<void> initialize() async {
  // Platform-specific initialization
  await platform_main.initializePlatform();

  // Initialize settings
  await Settings.init(cacheProvider: HiveCache());
  await initHive();
  await AppPaths.createNecessaryDirectories();

  // Load certificates (only on native platforms)
  if (!kIsWeb) {
    await platform_main.loadCerts();
  }

  // Initialize PDF cache (only on native platforms)
  if (!kIsWeb) {
    await platform_main.initPdfCache();
  }

  // Initialize Shamor Zachor dynamic data loader
  if (!kIsWeb) {
    try {
      final libraryBasePath = await AppPaths.getLibraryPath();
      _shamorZachorDataLoader =
          await ShamorZachorServiceFactory.getDynamicLoader(
        libraryBasePath: libraryBasePath,
        getTocFunction: TocParser.parseFlatFromFile,
      );
    } catch (e) {
      debugPrint('Failed to initialize Shamor Zachor: $e');
    }
  }

  // Perform automatic backup if needed (only on native platforms)
  if (!kIsWeb) {
    await platform_main.performAutoBackupIfNeeded();
  }

  // Load SourcesBooks.csv data into memory
  try {
    await SourcesBooksService().loadSourcesBooks();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to load SourcesBooks.csv: $e');
    }
  }

  // Initialize Notification Service (only on native platforms)
  if (!kIsWeb) {
    await platform_main.initNotifications();
  }
}

/// Initialize Hive storage
Future<void> initHive() async {
  await platform_main.initHive();
}

/// Clean up resources when the app is closing
void cleanup() {
  _appWindowListener?.dispose();
  SourcesBooksService().clearData();
}
