import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  static const route = '/notifications/send';

  @override
  ConsumerState<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends ConsumerState<SendNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String _targetType = 'all'; // 'all', 'role', 'hotel', 'user'
  String? _targetValue;
  String? _targetPage;
  final List<String> _actionButtons = [];
  
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final loc = AppLocalizations.of(context)!;
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('pleaseEnterTitleBody'))),
      );
      return;
    }

    if (_targetType != 'all' && _targetValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('pleaseSelectTarget'))),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'targetType': _targetType,
          'targetValue': _targetValue,
          'targetPage': _targetPage,
          'actionButtons': _actionButtons.isEmpty ? null : _actionButtons,
        },
      );

      if (response.status == 200 && mounted) {
        final data = response.data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.tParams('notificationSent', {
              'successCount': data['successCount']?.toString() ?? '0',
              'failureCount': data['failureCount']?.toString() ?? '0'
            })),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _targetType = 'all';
          _targetValue = null;
        });
      } else {
        throw Exception(response.data?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final hotelsAsync = ref.watch(hotelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('sendPushTitle')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc.t('composeMessage'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: loc.t('notificationTitle'),
                        hintText: loc.t('notificationTitleHint'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: loc.t('notificationBody'),
                        hintText: loc.t('notificationBodyHint'),
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      loc.t('targetAudience'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        ChoiceChip(
                          label: Text(loc.t('allUsers')),
                          selected: _targetType == 'all',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _targetType = 'all';
                                _targetValue = null;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(loc.t('byRole')),
                          selected: _targetType == 'role',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _targetType = 'role';
                                _targetValue = null;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(loc.t('byHotel')),
                          selected: _targetType == 'hotel',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _targetType = 'hotel';
                                _targetValue = null;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(loc.t('byUserEmail')),
                          selected: _targetType == 'user',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _targetType = 'user';
                                _targetValue = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Dynamic Target Selector
                    if (_targetType == 'role') ...[
                      DropdownButtonFormField<String>(
                        value: _targetValue,
                        decoration: InputDecoration(
                          labelText: loc.t('selectRole'),
                          border: const OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'app_admin', child: Text('App Admin')),
                          DropdownMenuItem(value: 'app_manager', child: Text('App Manager')),
                          DropdownMenuItem(value: 'hotel_manager', child: Text('Hotel Manager')),
                          DropdownMenuItem(value: 'hotel_staff', child: Text('Hotel Staff')),
                        ],
                        onChanged: (val) => setState(() => _targetValue = val),
                      ),
                    ] else if (_targetType == 'hotel') ...[
                      hotelsAsync.when(
                        data: (hotels) {
                          return DropdownButtonFormField<String>(
                            value: _targetValue,
                            decoration: InputDecoration(
                              labelText: loc.t('selectHotel'),
                              border: const OutlineInputBorder(),
                            ),
                            items: hotels.map((h) => DropdownMenuItem(
                              value: h.id,
                              child: Text(h.name),
                            )).toList(),
                            onChanged: (val) => setState(() => _targetValue = val),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (err, stack) => Text('Error loading hotels: $err'),
                      ),
                    ] else if (_targetType == 'user') ...[
                      TextField(
                        decoration: InputDecoration(
                          labelText: loc.t('userEmail'),
                          hintText: loc.t('enterSpecificUserEmail'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        onChanged: (val) => _targetValue = val,
                      ),
                    ],

                    const SizedBox(height: 32),
                    Text(
                      loc.t('actionAndRouting'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _targetPage,
                      decoration: InputDecoration(
                        labelText: loc.t('openSpecificPage'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(loc.t('defaultNoPage'))),
                        DropdownMenuItem(value: '/', child: Text(loc.t('dashboard'))),
                        DropdownMenuItem(value: '/inventory', child: Text(loc.t('inventory'))),
                        DropdownMenuItem(value: '/alerts', child: Text(loc.t('alerts'))),
                        DropdownMenuItem(value: '/approvals', child: Text(loc.t('approvals'))),
                      ],
                      onChanged: (val) => setState(() => _targetPage = val),
                    ),
                    const SizedBox(height: 16),
                    Text(loc.t('actionButtonsAndroid'), style: theme.textTheme.titleSmall),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: Text(loc.t('dismiss')),
                          selected: _actionButtons.contains('Dismiss'),
                          onSelected: (val) {
                            setState(() {
                              val ? _actionButtons.add('Dismiss') : _actionButtons.remove('Dismiss');
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(loc.t('acknowledge')),
                          selected: _actionButtons.contains('Acknowledge'),
                          onSelected: (val) {
                            setState(() {
                              val ? _actionButtons.add('Acknowledge') : _actionButtons.remove('Acknowledge');
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(loc.t('openApp')),
                          selected: _actionButtons.contains('Open App'),
                          onSelected: (val) {
                            setState(() {
                              val ? _actionButtons.add('Open App') : _actionButtons.remove('Open App');
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(loc.t('markAsRead')),
                          selected: _actionButtons.contains('Mark as Read'),
                          onSelected: (val) {
                            setState(() {
                              val ? _actionButtons.add('Mark as Read') : _actionButtons.remove('Mark as Read');
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: _isSending ? null : _sendNotification,
                      icon: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSending ? 'Sending...' : loc.t('dispatchNotification'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
