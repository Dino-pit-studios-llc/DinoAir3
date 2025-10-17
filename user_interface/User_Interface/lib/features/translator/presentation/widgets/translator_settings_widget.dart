import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/translator_config_provider.dart';

class TranslatorSettingsWidget extends ConsumerStatefulWidget {
  const TranslatorSettingsWidget({super.key});

  @override
  ConsumerState<TranslatorSettingsWidget> createState() => _TranslatorSettingsWidgetState();
}

class _TranslatorSettingsWidgetState extends ConsumerState<TranslatorSettingsWidget> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDefaultLanguage = 'python';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current config values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentConfig = ref.read(currentTranslatorConfigProvider);
      if (currentConfig != null) {
        setState(() {
          _selectedDefaultLanguage = currentConfig.defaultLanguage;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(currentTranslatorConfigProvider);
    final isLoadingConfig = ref.watch(isLoadingTranslatorConfigProvider);

    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Translator Settings'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton(
                onPressed: _resetToDefaults,
                child: const Text('Reset'),
              ),
            ],
          ),
          body: isLoadingConfig
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // General Settings
                      _buildSectionHeader('General Settings'),

                      // Default Language
                      _buildDefaultLanguageSelector(),

                      const SizedBox(height: 24),

                      // Available Languages
                      _buildAvailableLanguagesSection(),

                      const SizedBox(height: 24),

                      // Model Settings
                      _buildModelSettingsSection(),

                      const SizedBox(height: 24),

                      // Advanced Settings
                      _buildAdvancedSettingsSection(),

                      const SizedBox(height: 32),

                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildDefaultLanguageSelector() {
    final theme = Theme.of(context);
    final availableLanguages = ref.watch(availableLanguagesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Language',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the default programming language for translations',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (availableLanguages.isEmpty)
              Text(
                'No languages available. Please configure languages first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else
              Builder(
                builder: (context) {
                  // Compute safe value for dropdown
                  final dropdownValue = availableLanguages.contains(_selectedDefaultLanguage)
                      ? _selectedDefaultLanguage
                      : availableLanguages.first;

                  // Update state if needed
                  if (_selectedDefaultLanguage != dropdownValue) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedDefaultLanguage = dropdownValue;
                        });
                      }
                    });
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: dropdownValue,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: availableLanguages.map((language) {
                      return DropdownMenuItem(
                        value: language,
                        child: Text(_getLanguageDisplayName(language)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDefaultLanguage = value;
                        });
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableLanguagesSection() {
    final theme = Theme.of(context);
    final availableLanguages = ref.watch(availableLanguagesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Available Languages',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddLanguageDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Languages that can be selected for translation',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableLanguages.map((language) {
                return Chip(
                  label: Text(_getLanguageDisplayName(language)),
                  onDeleted: language == _selectedDefaultLanguage
                      ? null
                      : () => _removeLanguage(language),
                  deleteIcon: language == _selectedDefaultLanguage
                      ? null
                      : const Icon(Icons.close, size: 16),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSettingsSection() {
    final theme = Theme.of(context);
    final modelSettings = ref.watch(currentTranslatorConfigProvider)?.modelSettings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure the translation model behavior',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable streaming'),
              subtitle: const Text('Show translation results as they are generated'),
              value: modelSettings?['streaming'] ?? false,
              onChanged: (value) {
                _updateModelSetting('streaming', value);
              },
            ),
            SwitchListTile(
              title: const Text('Show confidence scores'),
              subtitle: const Text('Display translation confidence percentages'),
              value: modelSettings?['showConfidence'] ?? true,
              onChanged: (value) {
                _updateModelSetting('showConfidence', value);
              },
            ),
            ListTile(
              title: const Text('Temperature'),
              subtitle: Text(
                'Controls randomness: ${(modelSettings?['temperature'] ?? 0.7).toStringAsFixed(1)}',
              ),
              trailing: SizedBox(
                width: 120,
                child: Slider(
                  value: (modelSettings?['temperature'] ?? 0.7).toDouble(),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) {
                    _updateModelSetting('temperature', value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Advanced configuration options',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Cache settings'),
              subtitle: const Text('Manage local translation cache'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showCacheSettings,
            ),
            ListTile(
              title: const Text('Reset all settings'),
              subtitle: const Text('Restore default configuration'),
              trailing: const Icon(Icons.warning, color: Colors.orange),
              onTap: _showResetConfirmation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Settings'),
        ),
      ],
    );
  }

  String _getLanguageDisplayName(String language) {
    const languageNames = {
      'python': 'Python',
      'javascript': 'JavaScript',
      'java': 'Java',
      'cpp': 'C++',
      'csharp': 'C#',
      'go': 'Go',
      'rust': 'Rust',
      'php': 'PHP',
      'ruby': 'Ruby',
      'swift': 'Swift',
      'kotlin': 'Kotlin',
      'typescript': 'TypeScript',
      'scala': 'Scala',
      'dart': 'Dart',
      'r': 'R',
      'matlab': 'MATLAB',
      'sql': 'SQL',
      'html': 'HTML',
      'css': 'CSS',
      'bash': 'Bash',
      'powershell': 'PowerShell',
    };

    return languageNames[language] ?? language.toUpperCase();
  }

  void _updateModelSetting(String key, dynamic value) {
    final currentConfig = ref.read(currentTranslatorConfigProvider);
    if (currentConfig == null) return;

    final currentSettings = Map<String, dynamic>.from(currentConfig.modelSettings ?? {});
    currentSettings[key] = value;

    final updatedConfig = currentConfig.copyWith(modelSettings: currentSettings);
    ref.read(translatorConfigProvider.notifier).updateConfig(updatedConfig);
  }

  void _showAddLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddLanguageDialog(),
    );
  }

  void _removeLanguage(String language) {
    ref.read(translatorConfigProvider.notifier).removeSupportedLanguage(language);
  }

  void _showCacheSettings() {
    showDialog(
      context: context,
      builder: (context) => const CacheSettingsDialog(),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will restore all settings to their default values. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetToDefaults();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update default language
      await ref.read(translatorConfigProvider.notifier).updateDefaultLanguage(_selectedDefaultLanguage);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetToDefaults() {
    ref.read(translatorConfigProvider.notifier).resetToDefaults();
    setState(() {
      _selectedDefaultLanguage = 'python';
    });
  }
}

// Dialog for adding new languages
class AddLanguageDialog extends StatefulWidget {
  const AddLanguageDialog({super.key});

  @override
  State<AddLanguageDialog> createState() => _AddLanguageDialogState();
}

class _AddLanguageDialogState extends State<AddLanguageDialog> {
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Language'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select a programming language to add:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Language dropdown would go here
            Text(
              'Language selector would be implemented here',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedLanguage != null ? () {
            // Add the language
            Navigator.of(context).pop();
          } : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Dialog for cache settings
class CacheSettingsDialog extends StatefulWidget {
  const CacheSettingsDialog({super.key});

  @override
  State<CacheSettingsDialog> createState() => _CacheSettingsDialogState();
}

class _CacheSettingsDialogState extends State<CacheSettingsDialog> {
  int _cacheSize = 1024; // Simulated cache size in KB
  bool _isClearing = false;

  void _clearCache() async {
    setState(() {
      _isClearing = true;
    });
    // Simulate cache clearing delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _cacheSize = 0;
      _isClearing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cache Settings'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current cache size: $_cacheSize KB',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: _isClearing
                  ? const Text('Clearing...')
                  : const Text('Clear Cache'),
              onPressed: _isClearing || _cacheSize == 0 ? null : _clearCache,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
