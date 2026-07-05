import re

with open("lib/src/features/inventory/femme_de_chambre_screen.dart", "r", encoding="utf-8") as f:
    code = f.read()

# 1. Add import
if "image_picker" not in code:
    code = code.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:image_picker/image_picker.dart';")

# 2. Add state variables
if "_isUploadingAvatar" not in code:
    code = code.replace("class _FemmeDeChambreScreenState extends ConsumerState<FemmeDeChambreScreen> {", "class _FemmeDeChambreScreenState extends ConsumerState<FemmeDeChambreScreen> {\n  var _isUploadingAvatar = false;")

# 3. Replace build method
build_pattern = re.compile(r"  @override\n  Widget build\(BuildContext context\) \{.*?    \);\n  \}", re.DOTALL)

new_build = """  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Aesthetic gradient background
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF111827), const Color(0xFF1F2937), const Color(0xFF111827)]
          : [const Color(0xFFF9FAFB), const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
    );

    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isHousekeeper = currentUser?.role == UserRole.housekeeper;
    final canManage = currentUser?.role != UserRole.hotelStaff && !isHousekeeper;

    return PageScaffold(
      title: isHousekeeper ? l10n.t('myBasket') : l10n.t('housekeepersTitle'),
      onRefresh: () async {
        if (isHousekeeper) {
          ref.invalidate(housekeeperAllocationsProvider);
          ref.invalidate(productsProvider);
          await Future.wait([
            ref.read(housekeeperAllocationsProvider.future),
            ref.read(productsProvider.future),
          ]);
        } else {
          ref.invalidate(hotelHousekeepersProvider);
          await ref.read(hotelHousekeepersProvider.future);
        }
      },
      actions: isHousekeeper ? [
        IconButton(
          tooltip: l10n.t('checkoutStock'),
          icon: const Icon(Icons.add_shopping_cart_outlined),
          onPressed: () => _showCheckoutDialog(context),
        ),
        IconButton(
          tooltip: l10n.t('returnStock'),
          icon: const Icon(Icons.assignment_return_outlined),
          onPressed: () => _showReturnDialog(context),
        ),
        IconButton(
          tooltip: l10n.t('allHistory'),
          icon: const Icon(Icons.history),
          onPressed: () => _showAllHistoryDialog(context, currentUser!.id),
        ),
      ] : [
        if (canManage)
          FilledButton.icon(
            onPressed: () => _showInviteHousekeeperDialog(context),
            icon: const Icon(Icons.person_add_outlined),
            label: Text(l10n.t('inviteHousekeeper')),
          ),
      ],
      child: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: isHousekeeper 
          ? _buildHousekeeperView(context, currentUser!)
          : _buildManagementView(context, currentUser!),
      ),
    );
  }

  Widget _buildHousekeeperView(BuildContext context, UserProfile currentUser) {
    final allocationsAsync = ref.watch(housekeeperAllocationsProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AsyncValueView(
      value: allocationsAsync,
      builder: (allocations) {
        if (allocations.isEmpty) {
          return Column(
            children: [
              _buildAvatarHeader(context, currentUser),
              Expanded(
                child: EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: l10n.t('housekeeperCart'),
                  message: l10n.t('noAllocations'),
                  actionLabel: l10n.t('checkoutStock'),
                  onAction: () => _showCheckoutDialog(context),
                ),
              ),
            ],
          );
        }

        final totalFullBottles = allocations.fold<int>(0, (sum, item) => sum + item.fullBottles);
        final totalEmptyBottles = allocations.fold<int>(0, (sum, item) => sum + item.emptyBottles);
        final totalFullBidons = allocations.fold<int>(0, (sum, item) => sum + item.fullBidons);
        final totalOpenBidons = allocations.fold<int>(0, (sum, item) => sum + item.openBidons);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAvatarHeader(context, currentUser),
              const SizedBox(height: 24),
              
              // Summary cards row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isMobile ? 1.4 : 1.6,
                    children: [
                      _buildSummaryCard(
                        context,
                        title: l10n.t('fullBottles'),
                        value: '$totalFullBottles',
                        icon: Icons.local_drink,
                        color: const Color(0xFFF2A900),
                      ),
                      _buildSummaryCard(
                        context,
                        title: l10n.t('inventoryTableEmptyBottlesGeneric'),
                        value: '$totalEmptyBottles',
                        icon: Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      _buildSummaryCard(
                        context,
                        title: l10n.t('inventoryTableFullBidonsGeneric'),
                        value: '$totalFullBidons',
                        icon: Icons.opacity_outlined,
                        color: Colors.blueAccent,
                      ),
                      _buildSummaryCard(
                        context,
                        title: l10n.t('inventoryTableOpenBidons'),
                        value: '$totalOpenBidons',
                        icon: Icons.hourglass_empty,
                        color: Colors.teal,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Allocation list header
              Text(
                l10n.t('housekeeperCart'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Allocations cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allocations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final allocation = allocations[index];
                  return _buildAllocationCard(context, allocation);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarHeader(BuildContext context, UserProfile user) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploadingAvatar ? null : () => _pickAvatar(user.id),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null
                      ? Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimaryContainer)
                      : null,
                ),
                if (_isUploadingAvatar)
                  const Positioned.fill(
                    child: CircularProgressIndicator(),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context).t('userRoleHousekeeper'),
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementView(BuildContext context, UserProfile currentUser) {
    final housekeepersAsync = ref.watch(hotelHousekeepersProvider);
    final l10n = AppLocalizations.of(context);

    return AsyncValueView(
      value: housekeepersAsync,
      builder: (housekeepers) {
        if (housekeepers.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: l10n.t('housekeepersTitle'),
            message: l10n.t('noHousekeepers'),
            actionLabel: currentUser.role != UserRole.hotelStaff ? l10n.t('inviteHousekeeper') : null,
            onAction: currentUser.role != UserRole.hotelStaff ? () => _showInviteHousekeeperDialog(context) : null,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: housekeepers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final hk = housekeepers[index];
            return _buildHousekeeperExpandableCard(context, hk, currentUser);
          },
        );
      },
    );
  }

  Widget _buildHousekeeperExpandableCard(BuildContext context, UserProfile hk, UserProfile currentUser) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canManage = currentUser.role != UserRole.hotelStaff;

    return GlassCard(
      child: ExpansionTile(
        leading: GestureDetector(
          onTap: canManage ? () => _pickAvatar(hk.id) : null,
          child: Stack(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: hk.avatarUrl != null ? NetworkImage(hk.avatarUrl!) : null,
                child: hk.avatarUrl == null
                    ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
                    : null,
              ),
              if (canManage)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 10,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(hk.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(hk.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l10n.t('allHistory'),
              onPressed: () => _showAllHistoryDialog(context, hk.id),
            ),
            if (canManage)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'toggle_status') {
                    await ref.read(repositoryProvider).setTeamMemberActive(userId: hk.id, isActive: !hk.isActive);
                    ref.invalidate(hotelHousekeepersProvider);
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => PremiumConfirmDialog(
                        title: l10n.t('confirmAction'),
                        message: l10n.tParams('confirmDeleteUser', {'userName': hk.fullName}),
                        confirmText: l10n.t('deleteGeneric'),
                        isDestructive: true,
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(repositoryProvider).deleteUser(userId: hk.id);
                      ref.invalidate(hotelHousekeepersProvider);
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Text(hk.isActive ? l10n.t('teamDeactivate') : l10n.t('teamReactivate')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.t('deleteGeneric'), style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('basketContent'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final basketAsync = ref.watch(housekeeperBasketProvider(hk.id));
                    return basketAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                      data: (basket) {
                        if (basket.isEmpty) {
                          return Text(l10n.t('noAllocations'), style: const TextStyle(fontStyle: FontStyle.italic));
                        }
                        return Column(
                          children: basket.map((a) => _buildAllocationCard(context, a)).toList(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(String targetUserId) async {
    final l10n = AppLocalizations.of(context);
    try {
      final picker = ImagePicker();
      XFile? image;
      try {
        image = await picker.pickImage(source: ImageSource.gallery);
      } catch (_) {
        image = await picker.pickMedia();
      }
      
      if (image == null) return;
      
      setState(() => _isUploadingAvatar = true);
      
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      
      await ref.read(repositoryProvider).updateUserAvatar(
        userId: targetUserId,
        bytes: bytes,
        fileExt: ext,
      );
      
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser?.id == targetUserId) {
        ref.invalidate(realCurrentUserProvider);
        ref.invalidate(currentUserProvider);
      }
      ref.invalidate(hotelHousekeepersProvider);
      ref.invalidate(teamMembersProvider);
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _showInviteHousekeeperDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.t('inviteHousekeeper')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.t('accountFullName')),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l10n.t('accountEmail')),
                  validator: (v) => v!.isEmpty || !v.contains('@') ? 'Invalid email' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('btnCancel')),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final hotelId = ref.read(selectedHotelIdProvider);
                    await ref.read(repositoryProvider).inviteTeamMember(
                      email: emailController.text.trim(),
                      role: UserRole.housekeeper,
                      hotelId: hotelId,
                      fullName: nameController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      PremiumSnackbar.show(context, 'Invitation sent', icon: Icons.check);
                      ref.invalidate(hotelHousekeepersProvider);
                    }
                  } catch (e) {
                    if (context.mounted) PremiumSnackbar.showError(context, e);
                  }
                }
              },
              child: Text(l10n.t('teamInvite')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAllHistoryDialog(BuildContext context, String housekeeperId) async {
    final l10n = AppLocalizations.of(context);
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.history),
              const SizedBox(width: 8),
              Text(l10n.t('allHistory')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final targetEventsAsync = ref.watch(housekeeperHistoryProvider(housekeeperId));
                return targetEventsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                  data: (targetEvents) {
                    if (targetEvents.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(l10n.t('noHistory'), textAlign: TextAlign.center),
                      );
                    }
                    
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: targetEvents.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final event = targetEvents[index];
                        final dateFormat = DateFormat('MMM d, yyyy HH:mm');
                        final pName = Localizations.localeOf(context).languageCode == 'ar'
                            ? event.product.nameAr
                            : (Localizations.localeOf(context).languageCode == 'fr'
                                ? event.product.nameFr
                                : event.product.nameEn);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('$pName - ${event.reason}'),
                          subtitle: Text(dateFormat.format(event.occurredAt.toLocal())),
                          trailing: Text(
                            _stockEventDeltas(l10n, event),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    );
                  }
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('btnClose')),
            ),
          ],
        );
      },
    );
  }
"""

if "Widget _buildHousekeeperView" not in code:
    code = build_pattern.sub(new_build, code, count=1)

with open("lib/src/features/inventory/femme_de_chambre_screen.dart", "w", encoding="utf-8") as f:
    f.write(code)
