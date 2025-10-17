import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ToolCallDisplayWidget extends StatefulWidget {
  const ToolCallDisplayWidget({
    required this.toolCall,
    super.key,
  });

  final Map<String, dynamic> toolCall;

  @override
  State<ToolCallDisplayWidget> createState() => _ToolCallDisplayWidgetState();
}

class _ToolCallDisplayWidgetState extends State<ToolCallDisplayWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Function icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.functions,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Function name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFunctionName(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_getFunctionDescription().isNotEmpty)
                          Text(
                            _getFunctionDescription(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Expand/collapse icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parameters section
                  if (_hasParameters()) ...[
                    Text(
                      'Parameters:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: SelectableText(
                        _formatParameters(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Copy button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFunctionName() {
    return widget.toolCall['function']?['name'] as String? ?? 'Unknown Function';
  }

  String _getFunctionDescription() {
    // You can add more sophisticated logic here to extract descriptions
    return 'Function call';
  }

  bool _hasParameters() {
    final parameters = widget.toolCall['function']?['arguments'];
    return parameters != null && parameters.toString().isNotEmpty;
  }

  String _formatParameters() {
    try {
      final parameters = widget.toolCall['function']?['arguments'];
      if (parameters == null) return 'No parameters';

      // If it's already a formatted string, return it
      if (parameters is String) {
        return parameters;
      }

      // Otherwise, format as JSON
      final encoder = const JsonEncoder.withIndent('  ');
      return encoder.convert(parameters);
    } catch (e) {
      return 'Error formatting parameters: $e';
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final textToCopy = '''
Function: ${_getFunctionName()}

Parameters:
${_formatParameters()}
''';

    await Clipboard.setData(ClipboardData(text: textToCopy));

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tool call copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
