import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/library/bloc/library_event.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';

/// טאב הגדרות ספרייה
class LibrarySettingsTab extends StatelessWidget {
  const LibrarySettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // הגדרות ספרים חיצוניים
              _buildSectionCard(
                context: context,
                title: 'ספרים חיצוניים',
                children: [
                  SwitchListTile(
                    secondary: const Icon(FluentIcons.globe_24_regular),
                    title: const Text('האם להציג ספרים מאתרים חיצוניים?',
                        style: TextStyle(fontSize: 16)),
                    subtitle: Text(
                        state.showExternalBooks
                            ? 'יוצגו גם ספרים מאתרים חיצוניים'
                            : 'יוצגו רק ספרים מספריית אוצריא',
                        style: const TextStyle(fontSize: 13)),
                    value: state.showExternalBooks,
                    onChanged: (value) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateShowExternalBooks(value));
                      context
                          .read<SettingsBloc>()
                          .add(UpdateShowHebrewBooks(value));
                      context
                          .read<SettingsBloc>()
                          .add(UpdateShowOtzarHachochma(value));
                    },
                  ),
                  if (state.showExternalBooks) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: CheckboxListTile(
                        title: const Text('הצג ספרים מאוצר החכמה',
                            style: TextStyle(fontSize: 16)),
                        value: state.showOtzarHachochma,
                        onChanged: (value) {
                          if (value != null) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateShowOtzarHachochma(value));
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: CheckboxListTile(
                        title: const Text('הצג ספרים מהיברובוקס',
                            style: TextStyle(fontSize: 16)),
                        value: state.showHebrewBooks,
                        onChanged: (value) {
                          if (value != null) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateShowHebrewBooks(value));
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),

              // מיקום ספריות (רק בדסקטופ)
              if (!(Platform.isAndroid || Platform.isIOS)) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  context: context,
                  title: 'מיקום ספריות',
                  children: [
                    ListTile(
                      leading: const Icon(FluentIcons.folder_24_regular),
                      title: const Text('מיקום הספרייה',
                          style: TextStyle(fontSize: 16)),
                      subtitle: Text(
                        Settings.getValue<String>(
                                SettingsRepository.keyLibraryPath) ??
                            'לא קיים',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing:
                          const Icon(FluentIcons.chevron_right_24_regular),
                      onTap: () async {
                        String? path =
                            await FilePicker.platform.getDirectoryPath();
                        if (path != null && context.mounted) {
                          context
                              .read<LibraryBloc>()
                              .add(UpdateLibraryPath(path));
                          context
                              .read<NavigationBloc>()
                              .add(const CheckLibrary());
                        }
                      },
                    ),
                    const Divider(height: 1),
                    Tooltip(
                      message: 'במידה וקיימים ברשותך ספרים ממאגר זה',
                      child: ListTile(
                        leading: const Icon(FluentIcons.folder_24_regular),
                        title: const Text('מיקום ספרי היברובוקס',
                            style: TextStyle(fontSize: 16)),
                        subtitle: Text(
                          Settings.getValue<String>(
                                  SettingsRepository.keyHebrewBooksPath) ??
                              'לא קיים',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing:
                            const Icon(FluentIcons.chevron_right_24_regular),
                        onTap: () async {
                          String? path =
                              await FilePicker.platform.getDirectoryPath();
                          if (path != null && context.mounted) {
                            context
                                .read<LibraryBloc>()
                                .add(UpdateHebrewBooksPath(path));
                            context
                                .read<NavigationBloc>()
                                .add(const CheckLibrary());
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],

              // תיקיות מותאמות אישית (רק בדסקטופ)
              if (!(Platform.isAndroid || Platform.isIOS)) ...[],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
