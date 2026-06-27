import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../data/ivra_repository.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../shared/premium_snackbar.dart';

class AuthorizationsScreen extends ConsumerStatefulWidget {
  const AuthorizationsScreen({super.key});

  static const route = '/authorizations';

  @override
  ConsumerState<AuthorizationsScreen> createState() => _AuthorizationsScreenState();
}

class _AuthorizationsScreenState extends ConsumerState<AuthorizationsScreen> with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  TabController? _tabController;

  static const _fallbackPermissions = [
    'view_rooms',
    'manage_rooms',
    'view_inventory',
    'manage_hotels',
    'manage_products',
    'manage_team',
    'submit_edit_requests',
    'view_approvals',
    'approve_corrections',
    'view_alerts',
    'view_reports',
    'send_notifications',
    'view_audit_logs',
    'view_authorizations',
  ];

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _getPermissionTitle(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'manage_hotels':
        return l10n.t('permManageHotels');
      case 'manage_rooms':
        return l10n.t('permManageRooms');
      case 'manage_products':
        return l10n.t('permManageProducts');
      case 'manage_team':
        return l10n.t('permManageTeam');
      case 'submit_edit_requests':
        return l10n.t('permSubmitEditRequests');
      case 'approve_corrections':
        return l10n.t('permApproveCorrections');
      case 'view_approvals':
        return l10n.t('permViewApprovals');
      case 'view_alerts':
        return l10n.t('permViewAlerts');
      case 'view_reports':
        return l10n.t('permViewReports');
      case 'send_notifications':
        return l10n.t('permSendNotifications');
      case 'view_audit_logs':
        return l10n.t('permViewAuditLogs');
      case 'view_rooms':
        return l10n.t('permViewRooms');
      case 'view_inventory':
        return l10n.t('permViewInventory');
      case 'view_authorizations':
        return l10n.t('permViewAuthorizations');
      default:
        return key;
    }
  }

  String _getPermissionDescription(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'manage_hotels':
        return l10n.t('permManageHotelsDesc');
      case 'manage_rooms':
        return l10n.t('permManageRoomsDesc');
      case 'manage_products':
        return l10n.t('permManageProductsDesc');
      case 'manage_team':
        return l10n.t('permManageTeamDesc');
      case 'submit_edit_requests':
        return l10n.t('permSubmitEditRequestsDesc');
      case 'approve_corrections':
        return l10n.t('permApproveCorrectionsDesc');
      case 'view_approvals':
        return l10n.t('permViewApprovalsDesc');
      case 'view_alerts':
        return l10n.t('permViewAlertsDesc');
      case 'view_reports':
        return l10n.t('permViewReportsDesc');
      case 'send_notifications':
        return l10n.t('permSendNotificationsDesc');
      case 'view_audit_logs':
        return l10n.t('permViewAuditLogsDesc');
      case 'view_rooms':
        return l10n.t('permViewRoomsDesc');
      case 'view_inventory':
        return l10n.t('permViewInventoryDesc');
      case 'view_authorizations':
        return l10n.t('permViewAuthorizationsDesc');
      default:
        return '';
    }
  }

  String _getRoleLabel(BuildContext context, String role) {
    final l10n = AppLocalizations.of(context);
    switch (role) {
      case 'app_admin':
        return l10n.t('roleAppAdmin');
      case 'app_manager':
        return l10n.t('roleAppManager');
      case 'hotel_manager':
        return l10n.t('roleHotelManager');
      case 'hotel_staff':
        return l10n.t('roleHotelStaff');
      default:
        return role.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }

  Future<void> _togglePermission(String role, String permission, bool isEnabled) async {
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(repositoryProvider).updateRolePermission(
        role: role,
        permission: permission,
        isEnabled: isEnabled,
      );
      ref.invalidate(rolePermissionsProvider);
      if (mounted) {
        PremiumSnackbar.showSuccess(
          context,
          l10n.t('authorizationsUpdatedSuccessfully'),
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rolesAsync = ref.watch(rolesProvider);
    final permissionsAsync = ref.watch(rolePermissionsProvider);
    final allPermissionsAsync = ref.watch(allPermissionsProvider);

    return PageScaffold(
      title: l10n.t('authorizationsTitle'),
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
      child: AsyncValueView(
        value: rolesAsync,
        onRetry: () => ref.invalidate(rolesProvider),
        builder: (roles) {
          if (_tabController == null || _tabController!.length != roles.length) {
            _tabController?.dispose();
            _tabController = TabController(length: roles.length, vsync: this);
          }

          return AsyncValueView(
            value: permissionsAsync,
            onRetry: () => ref.invalidate(rolePermissionsProvider),
            builder: (matrix) {
              return AsyncValueView(
                value: allPermissionsAsync,
                onRetry: () => ref.invalidate(allPermissionsProvider),
                builder: (allPermissions) {
                  final isWide = MediaQuery.sizeOf(context).width >= 720;
                  final permissionsList = allPermissions.isNotEmpty ? allPermissions : _fallbackPermissions;

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('authorizationsHeader'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.t('authorizationsSubtitle'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (isWide)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 32,
                                  columns: [
                                    DataColumn(label: Text(l10n.t('authorizationsPermission'))),
                                    ...roles.map(
                                      (role) => DataColumn(
                                        label: Text(
                                          _getRoleLabel(context, role),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: permissionsList.map((permission) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _getPermissionTitle(context, permission),
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _getPermissionDescription(context, permission),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        ...roles.map((role) {
                                          final isEnabled = matrix[role]?.contains(permission) ?? false;
                                          final isSystemAdmin = role == 'app_admin';

                                          return DataCell(
                                            Switch(
                                              value: isSystemAdmin ? true : isEnabled,
                                              activeColor: const Color(0xFF267D65),
                                              onChanged: isSystemAdmin
                                                  ? null
                                                  : (val) => _togglePermission(role, permission, val),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: roles.map((role) => Tab(text: _getRoleLabel(context, role))).toList(),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: roles.map((role) {
                                return ListView.separated(
                                  itemCount: permissionsList.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final permission = permissionsList[index];
                                    final isEnabled = matrix[role]?.contains(permission) ?? false;
                                    final isSystemAdmin = role == 'app_admin';

                                    return SwitchListTile(
                                      value: isSystemAdmin ? true : isEnabled,
                                      title: Text(
                                        _getPermissionTitle(context, permission),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(_getPermissionDescription(context, permission)),
                                      activeColor: const Color(0xFF267D65),
                                      onChanged: isSystemAdmin
                                          ? null
                                          : (val) => _togglePermission(role, permission, val),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
