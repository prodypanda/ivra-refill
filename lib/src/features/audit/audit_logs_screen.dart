import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../shared/premium_confirm_dialog.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  static const route = '/audit-logs';

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _scrollController = ScrollController();
  int? _sortColumnIndex = 0;
  bool _sortAscending = false;
  String? _selectedActionFilter;

  IconData _getActionIcon(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('login')) return Icons.login_rounded;
    if (lower.contains('logout')) return Icons.logout_rounded;
    if (lower.contains('create') || lower.contains('add')) return Icons.add_circle_outline_rounded;
    if (lower.contains('update') || lower.contains('edit')) return Icons.edit_note_rounded;
    if (lower.contains('delete') || lower.contains('clear')) return Icons.delete_outline_rounded;
    if (lower.contains('sync')) return Icons.sync_rounded;
    if (lower.contains('approve')) return Icons.assignment_turned_in_rounded;
    if (lower.contains('reject')) return Icons.assignment_late_rounded;
    return Icons.info_outline_rounded;
  }

  Color _getActionColor(BuildContext context, String action) {
    final lower = action.toLowerCase();
    final colorScheme = Theme.of(context).colorScheme;
    if (lower.contains('delete') || lower.contains('clear') || lower.contains('reject')) return colorScheme.error;
    if (lower.contains('create') || lower.contains('add') || lower.contains('approve')) return Colors.green.shade700;
    if (lower.contains('update') || lower.contains('edit')) return colorScheme.primary;
    if (lower.contains('login') || lower.contains('logout') || lower.contains('sync')) return colorScheme.secondary;
    return colorScheme.outline;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auditLogsAsync = ref.watch(auditLogsProvider);
    final teamMembersAsync = ref.watch(teamMembersProvider);

    return PageScaffold(
      title: l10n.t('auditLogs'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: l10n.t('clearAuditLogs'),
          onPressed: () async {
            final confirm = await PremiumConfirmDialog.show(
              context,
              title: l10n.t('confirmAction'),
              message: l10n.t('confirmClearLogs'),
            );
            if (confirm) {
              await ref.read(repositoryProvider).clearAuditLogs();
              ref.invalidate(auditLogsProvider);
            }
          },
        ),
      ],
      onRefresh: () async {
        ref.invalidate(auditLogsProvider);
        await ref.read(auditLogsProvider.future);
      },
      child: AsyncValueView(
        value: auditLogsAsync,
        builder: (logs) {
          final teamMembers = teamMembersAsync.valueOrNull ?? [];
          final uniqueActions = logs.map((l) => l.action).toSet().toList()..sort();
          
          var filteredLogs = _selectedActionFilter == null 
              ? logs.toList()
              : logs.where((l) => l.action == _selectedActionFilter).toList();
              
          filteredLogs.sort((a, b) {
            final asc = _sortAscending ? 1 : -1;
            switch (_sortColumnIndex) {
              case 0:
                return a.createdAt.compareTo(b.createdAt) * asc;
              case 1:
                final userA = a.userId != null ? teamMembers.where((m) => m.id == a.userId).firstOrNull?.email ?? a.userId! : 'System';
                final userB = b.userId != null ? teamMembers.where((m) => m.id == b.userId).firstOrNull?.email ?? b.userId! : 'System';
                return userA.compareTo(userB) * asc;
              case 2:
                return a.action.compareTo(b.action) * asc;
              case 3:
                return (a.ipAddress ?? '').compareTo(b.ipAddress ?? '') * asc;
              case 4:
                return (a.deviceInfo ?? '').compareTo(b.deviceInfo ?? '') * asc;
              default:
                return b.createdAt.compareTo(a.createdAt); // default descending
            }
          });

          final isWide = MediaQuery.sizeOf(context).width >= 720;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (uniqueActions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(l10n.t('auditFilterAllActions') ?? 'All Actions'),
                        selected: _selectedActionFilter == null,
                        onSelected: (_) => setState(() => _selectedActionFilter = null),
                      ),
                      ...uniqueActions.map((action) => FilterChip(
                        label: Text(action),
                        selected: _selectedActionFilter == action,
                        onSelected: (selected) {
                          setState(() => _selectedActionFilter = selected ? action : null);
                        },
                      )),
                    ],
                  ),
                ),
              if (isWide)
                Card(
                  margin: EdgeInsets.zero,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn(label: Text(l10n.t('auditTimestamp')), onSort: _onSort),
                          DataColumn(label: Text(l10n.t('auditUser')), onSort: _onSort),
                          DataColumn(label: Text(l10n.t('auditAction')), onSort: _onSort),
                          DataColumn(label: Text(l10n.t('auditIpAddress')), onSort: _onSort),
                          DataColumn(label: Text(l10n.t('auditDevice')), onSort: _onSort),
                        ],
                        rows: filteredLogs.map((log) {
                          final user = log.userId != null 
                              ? teamMembers.where((m) => m.id == log.userId).firstOrNull 
                              : null;
                          final userDisplay = user != null ? user.email : (log.userId ?? 'System');
                          
                          final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt);

                          return DataRow(
                            cells: [
                              DataCell(Text(date)),
                              DataCell(Text(userDisplay)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(log.action, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    if (log.details != null && log.details!.isNotEmpty)
                                      Text(
                                        log.details!.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(Text(log.ipAddress ?? '-')),
                              DataCell(Text(log.deviceInfo ?? '-')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                )
              else ...[
                if (filteredLogs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        l10n.t('noAuditLogs') ?? 'No audit logs found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                  )
                else
                  ...filteredLogs.map((log) {
                    final user = log.userId != null 
                        ? teamMembers.where((m) => m.id == log.userId).firstOrNull 
                        : null;
                    final userDisplay = user != null ? user.email : (log.userId ?? 'System');
                    final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt);

                    return _AuditLogMobileCard(
                      date: date,
                      userDisplay: userDisplay,
                      action: log.action,
                      icon: _getActionIcon(log.action),
                      color: _getActionColor(context, log.action),
                      ipAddress: log.ipAddress ?? '-',
                      deviceInfo: log.deviceInfo ?? '-',
                      details: log.details,
                    );
                  }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AuditLogMobileCard extends StatelessWidget {
  const _AuditLogMobileCard({
    required this.date,
    required this.userDisplay,
    required this.action,
    required this.icon,
    required this.color,
    required this.ipAddress,
    required this.deviceInfo,
    this.details,
  });

  final String date;
  final String userDisplay;
  final String action;
  final IconData icon;
  final Color color;
  final String ipAddress;
  final String deviceInfo;
  final Map<String, dynamic>? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: color,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    userDisplay,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: details!.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall,
                          children: [
                            TextSpan(
                              text: '${e.key}: ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${e.value}'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      ipAddress,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.devices, size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      deviceInfo,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
