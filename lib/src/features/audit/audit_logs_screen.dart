import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';

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
          tooltip: l10n.t('clearAuditLogs') ?? 'Clear Logs',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.t('confirmAction') ?? 'Confirm Action'),
                content: Text(l10n.t('confirmClearLogs') ?? 'Are you sure you want to clear all audit logs? This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.t('btnCancel') ?? 'Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.t('btnClear') ?? 'Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
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
              Expanded(
                child: Card(
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
          ),
        ),
      ],
    );
  },
),
);
}
}
