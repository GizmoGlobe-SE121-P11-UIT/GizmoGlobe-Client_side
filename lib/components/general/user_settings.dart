import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/providers/theme_provider.dart';
import 'package:gizmoglobe_client/providers/language_provider.dart';

class UserSettingsModal extends StatefulWidget {
  const UserSettingsModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UserSettingsModal(),
    );
  }

  @override
  State<UserSettingsModal> createState() => _UserSettingsModalState();
}

class _UserSettingsModalState extends State<UserSettingsModal> {
  late String _selectedLanguage;
  late ThemeMode _selectedTheme;
  
  // Store original values to detect changes
  late String _originalLanguage;
  late ThemeMode _originalTheme;

  @override
  void initState() {
    super.initState();
    _selectedLanguage =
        context.read<LanguageProvider>().currentLocale.languageCode;
    _selectedTheme = context.read<ThemeProvider>().themeMode;
    
    _originalLanguage = _selectedLanguage;
    _originalTheme = _selectedTheme;
  }
  
  bool get _hasChanges => 
      _selectedLanguage != _originalLanguage || _selectedTheme != _originalTheme;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      S.of(context).settings,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content with compact settings
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                children: [
                  _buildLanguageSettingsCompact(context),
                  const SizedBox(height: 20),
                  _buildThemeSettingsCompact(context),
                  const SizedBox(height: 24),
                  _buildSaveButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettingsCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.language,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).language,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  S.of(context).changeLanguageDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(
                      '🇺🇸 ${S.of(context).languageEn}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'vi',
                    child: Text(
                      '🇻🇳 ${S.of(context).languageVi}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLanguage = value);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettingsCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dark_mode_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).changeTheme,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  S.of(context).changeThemeDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<ThemeMode>(
            value: _selectedTheme,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.light_mode_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      S.of(context).lightMode,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dark_mode_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      S.of(context).darkMode,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedTheme = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            child: Text(
              S.of(context).cancel,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _hasChanges ? _saveSettings : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              S.of(context).save,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    final languageProvider = context.read<LanguageProvider>();
    final themeProvider = context.read<ThemeProvider>();
    
    // Apply language change if different
    if (_selectedLanguage != _originalLanguage) {
      languageProvider.setLanguage(_selectedLanguage);
    }
    
    // Apply theme change if different
    if (_selectedTheme != _originalTheme) {
      themeProvider.setTheme(_selectedTheme);
    }
    
    // Close the modal
    Navigator.pop(context);
  }
}
