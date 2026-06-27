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
  String _searchQuery = '';

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

  String _getPermissionCategory(BuildContext context, String permission) {
    final l10n = AppLocalizations.of(context);
    switch (permission) {
      case 'view_rooms':
      case 'submit_edit_requests':
      case 'view_inventory':
        return l10n.t('authCategoryCore');
      case 'manage_rooms':
      case 'manage_hotels':
      case 'manage_products':
      case 'manage_team':
        return l10n.t('authCategoryManagement');
      case 'view_approvals':
      case 'approve_corrections':
      case 'view_alerts':
        return l10n.t('authCategoryControl');
      case 'view_reports':
      case 'send_notifications':
        return l10n.t('authCategoryAnalytics');
      case 'view_audit_logs':
      case 'view_authorizations':
        return l10n.t('authCategorySecurity');
      default:
        return l10n.t('authCategoryCore');
    }
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

  Future<void> _bulkSetPermissions(String role, bool enable) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(repositoryProvider);
      final allPermissions = ref.read(allPermissionsProvider).valueOrNull ?? _fallbackPermissions;
      
      for (final permission in allPermissions) {
        await repository.updateRolePermission(
          role: role,
          permission: permission,
          isEnabled: enable,
        );
      }
      
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

  void _showCreateRoleDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.t('authCreateRoleTitle')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.t('authRoleNameLabel'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.t('authRoleDisplayNameError');
                    }
                    final regExp = RegExp(r'^[a-z]+(_[a-z]+)*$');
                    if (!regExp.hasMatch(value)) {
                      return l10n.t('authRoleNameError');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.t('authRoleDescLabel'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  Navigator.pop(context);
                  
                  setState(() => _isSaving = true);
                  try {
                    await ref.read(repositoryProvider).createRole(
                      name: name,
                      description: desc,
                    );
                    ref.invalidate(rolesProvider);
                    ref.invalidate(rolePermissionsProvider);
                    
                    if (context.mounted) {
                      PremiumSnackbar.showSuccess(
                        context,
                        l10n.t('authRoleCreatedSuccess'),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      PremiumSnackbar.showError(context, e);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                }
              },
              child: Text(l10n.t('save')),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMobilePermissionList({
    required BuildContext context,
    required String role,
    required List<String> permissions,
    required Map<String, Set<String>> matrix,
  }) {
    final List<Widget> list = [];
    String? currentCategory;

    for (final permission in permissions) {
      final cat = _getPermissionCategory(context, permission);
      if (cat != currentCategory) {
        currentCategory = cat;
        list.add(
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            alignment: Alignment.centerLeft,
            child: Text(
              cat.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );
      }

      final isEnabled = matrix[role]?.contains(permission) ?? false;
      final isSystemAdmin = role == 'app_admin';

      list.add(
        SwitchListTile(
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
        ),
      );
    }
    return list;
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
          )
        else
          TextButton.icon(
            onPressed: () => _showCreateRoleDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.t('authBtnCreateRole')),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
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

                  final filteredPermissions = permissionsList.where((permission) {
                    if (_searchQuery.trim().isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    final title = _getPermissionTitle(context, permission).toLowerCase();
                    final desc = _getPermissionDescription(context, permission).toLowerCase();
                    return title.contains(query) || desc.contains(query);
                  }).toList();

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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: l10n.t('authSearchHint'),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
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
                                        label: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getRoleLabel(context, role),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            if (role != 'app_admin')
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: () => _bulkSetPermissions(role, true),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                                      child: Text(
                                                        l10n.t('authBulkGrantAll'),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Theme.of(context).colorScheme.primary,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Text('|', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                  InkWell(
                                                    onTap: () => _bulkSetPermissions(role, false),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                                      child: Text(
                                                        l10n.t('authBulkRevokeAll'),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Theme.of(context).colorScheme.error,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: () {
                                    final rowsList = <DataRow>[];
                                    String? lastCategory;

                                    for (final permission in filteredPermissions) {
                                      final cat = _getPermissionCategory(context, permission);
                                      if (cat != lastCategory) {
                                        lastCategory = cat;
                                        rowsList.add(
                                          DataRow(
                                            color: WidgetStateProperty.all(
                                              Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                                            ),
                                            cells: [
                                              DataCell(
                                                Text(
                                                  cat.toUpperCase(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: Theme.of(context).colorScheme.primary,
                                                    letterSpacing: 1.1,
                                                  ),
                                                ),
                                              ),
                                              for (var i = 0; i < roles.length; i++)
                                                const DataCell(SizedBox.shrink()),
                                            ],
                                          ),
                                        );
                                      }

                                      rowsList.add(
                                        DataRow(
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
                                        ),
                                      );
                                    }
                                    return rowsList;
                                  }(),
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
                          AnimatedBuilder(
                            animation: _tabController!,
                            builder: (context, _) {
                              final roleIndex = _tabController!.index;
                              if (roleIndex >= roles.length) return const SizedBox.shrink();
                              final role = roles[roleIndex];
                              if (role == 'app_admin') return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _bulkSetPermissions(role, true),
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: Text(l10n.t('authBulkGrantAll')),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _bulkSetPermissions(role, false),
                                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                                      label: Text(l10n.t('authBulkRevokeAll')),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: roles.map((role) {
                                final mobileWidgets = _buildMobilePermissionList(
                                  context: context,
                                  role: role,
                                  permissions: filteredPermissions,
                                  matrix: matrix,
                                );

                                return ListView.separated(
                                  itemCount: mobileWidgets.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) => mobileWidgets[index],
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
