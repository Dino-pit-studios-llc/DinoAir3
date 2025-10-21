import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../providers/translator_config_provider.dart';
import '../providers/translator_input_provider.dart';

class LanguageSelectorWidget extends ConsumerStatefulWidget {
  const LanguageSelectorWidget({super.key});

  @override
  ConsumerState<LanguageSelectorWidget> createState() =>
      _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState
    extends ConsumerState<LanguageSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isOpen = false;
  String _searchQuery = '';

  final Map<String, String> _languageNames = {
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
    'lua': 'Lua',
    'perl': 'Perl',
    'haskell': 'Haskell',
    'clojure': 'Clojure',
    'erlang': 'Erlang',
    'elixir': 'Elixir',
    'julia': 'Julia',
    'fortran': 'Fortran',
    'cobol': 'COBOL',
    'pascal': 'Pascal',
    'ada': 'Ada',
    'verilog': 'Verilog',
    'vhdl': 'VHDL',
    'assembly': 'Assembly',
    'objective-c': 'Objective-C',
    'delphi': 'Delphi',
    'vb': 'Visual Basic',
    'groovy': 'Groovy',
    'scheme': 'Scheme',
    'prolog': 'Prolog',
    'lisp': 'Lisp',
    'fsharp': 'F#',
    'ocaml': 'OCaml',
    'coffeescript': 'CoffeeScript',
    'livescript': 'LiveScript',
    'purescript': 'PureScript',
    'elm': 'Elm',
    'reason': 'Reason',
    'nim': 'Nim',
    'crystal': 'Crystal',
    'zig': 'Zig',
    'v': 'V',
    'ballerina': 'Ballerina',
    'pony': 'Pony',
    'red': 'Red',
    'rebol': 'Rebol',
    'factor': 'Factor',
    'forth': 'Forth',
    'brainfuck': 'Brainfuck',
    'whitespace': 'Whitespace',
    'piet': 'Piet',
    'malbolge': 'Malbolge',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);
    final availableLanguages = ref.watch(availableLanguagesProvider);

    // Filter languages based on search query
    final filteredLanguages =
        _getFilteredLanguages(supportedLanguages, availableLanguages);

    return GestureDetector(
      onTap: () {
        if (_isOpen) {
          setState(() {
            _isOpen = false;
          });
        }
      },
      child: Stack(
        children: [
          Container(
            width: 140,
            child: FocusableActionDetector(
              autofocus: false,
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (Intent intent) {
                    _toggleDropdown();
                    return null;
                  },
                ),
              },
              shortcuts: <ShortcutActivator, Intent>{
                LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
                LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
              },
              child: InkWell(
                key: const Key('translator_language_selector'),
                onTap: _toggleDropdown,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getLanguageDisplayName(selectedLanguage),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 18,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isOpen)
            Positioned(
              top: 42,
              left: 0,
              child: _buildDropdown(context),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);
    final availableLanguages = ref.watch(availableLanguagesProvider);

    final filteredLanguages =
        _getFilteredLanguages(supportedLanguages, availableLanguages);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search languages...',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: theme.textTheme.bodySmall,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            const Divider(height: 1),

            // Language list
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredLanguages.length,
                  itemBuilder: (context, index) {
                    final language = filteredLanguages[index];
                    final isSelected = language == selectedLanguage;
                    final displayName = _getLanguageDisplayName(language);

                    return InkWell(
                      onTap: () => _selectLanguage(language),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : null,
                        child: Text(
                          displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : null,
                            fontWeight: isSelected ? FontWeight.w500 : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getFilteredLanguages(
      List<String> supported, List<String> available) {
    final allLanguages = {...supported, ...available}.toList();
    if (_searchQuery.isEmpty) {
      return allLanguages;
    }

    return allLanguages.where((language) {
      final displayName = _getLanguageDisplayName(language).toLowerCase();
      return displayName.contains(_searchQuery);
    }).toList();
  }

  String _getLanguageDisplayName(String language) {
    return _languageNames[language] ?? language.toUpperCase();
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _searchQuery = '';
        _searchController.clear();
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _selectLanguage(String language) {
    ref.read(translatorInputProvider.notifier).updateLanguage(language);
    setState(() {
      _isOpen = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isOpen) {
      // Close dropdown when tapping outside
      Future.delayed(Duration.zero, () {
        if (mounted) {
          final focusScope = FocusScope.of(context);
          focusScope.addListener(() {
            if (!focusScope.hasFocus) {
              setState(() {
                _isOpen = false;
              });
            }
          });
        }
      });
    }
  }
}
