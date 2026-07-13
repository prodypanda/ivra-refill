import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../data/ivra_repository.dart';
import '../../domain/app_enums.dart';
import '../../data/ivra_repository.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../../state/app_state.dart';
import '../../data/ivra_repository.dart';
import '../../domain/app_enums.dart';
import '../../data/ivra_repository.dart';

// Create dedicated providers
final rolesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(repositoryProvider);
  return repo.fetchRoles();
});

final rolePermissionsProvider = FutureProvider<Map<String, Set<String>>>((ref) async {
  final repo = ref.read(repositoryProvider);
  return repo.fetchRolePermissions();
});

final rolePermissionsCombinedProvider = FutureProvider<({List<String> roles, Map<String, Set<String>> permissions})>((ref) async {
  final roles = await ref.watch(rolesProvider.future);
  final permissions = await ref.watch(rolePermissionsProvider.future);
  return (roles: roles, permissions: permissions);
});

class RolePermissionsScreen extends ConsumerWidget {
  const RolePermissionsScreen({super.key});

  static const route = '/settings/roles';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final combinedAsync = ref.watch(rolePermissionsCombinedProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return PageScaffold(
      title: l10n.t('rolePermissionsGuide'),
      child: AsyncValueView(
        value: combinedAsync,
        builder: (data) {
          final roles = data.roles;
          final permissions = data.permissions;
          
          if (roles.isEmpty || permissions.isEmpty) {
             return Center(child: Text(AppLocalizations.of(context)!.t('roleNoPermissionsFound')));
          }

          // Convert sets to a distinct list of all possible permissions
          final allPermissions = permissions.values.expand((element) => element).toSet().toList()..sort();

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith((states) => theme.colorScheme.surfaceContainerHighest),
                columnSpacing: 24,
                columns: [
                  DataColumn(label: Text(AppLocalizations.of(context)!.t('roleFeatureColumnLabel'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                  for (final role in roles)
                    DataColumn(
                      label: Text(
                        role.replaceAll('_', ' ').toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      )
                    ),
                ],
                rows: [
                  for (final permission in allPermissions)
                    DataRow(
                      cells: [
                        DataCell(Text(permission.replaceAll('_', ' ').toUpperCase())),
                        for (final role in roles)
                          DataCell(
                            Icon(
                              permissions[role]?.contains(permission) == true ? Icons.check_circle : Icons.cancel,
                              color: permissions[role]?.contains(permission) == true ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
