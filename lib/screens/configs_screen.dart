import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/vpn_config.dart';
import '../theme.dart';

class ConfigsScreen extends StatelessWidget {
  const ConfigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'کانفیگ‌ها (${provider.configs.length})',
              style: const TextStyle(color: CyrusColors.gold, letterSpacing: 1),
            ),
            actions: [
              if (provider.isTestingConfigs)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: CyrusColors.gold,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.speed, color: CyrusColors.gold),
                  tooltip: 'تست همه',
                  onPressed: () => provider.testAllConfigs(),
                ),
            ],
          ),
          body: provider.configs.isEmpty
              ? _buildEmpty(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.configs.length,
                  itemBuilder: (context, i) {
                    return _ConfigTile(
                      config: provider.configs[i],
                      isActive:
                          provider.activeConfig?.id == provider.configs[i].id,
                      onTap: () => provider.connectTo(provider.configs[i]),
                      onDelete: () => provider.deleteConfig(provider.configs[i]),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dns_outlined, color: CyrusColors.greyDark, size: 64),
          SizedBox(height: 16),
          Text(
            'کانفیگی وجود ندارد',
            style: TextStyle(color: CyrusColors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'از تب کانال‌ها یک کانال اضافه کنید',
            style: TextStyle(color: CyrusColors.greyDark, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  final VpnConfig config;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConfigTile({
    required this.config,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  Color get _latencyColor {
    if (!config.isTested) return CyrusColors.grey;
    if (config.isTimeout) return CyrusColors.red;
    if (config.latency < 200) return CyrusColors.green;
    if (config.latency < 500) return CyrusColors.yellow;
    return CyrusColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(config.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: CyrusColors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: CyrusColors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive
                ? CyrusColors.gold.withOpacity(0.08)
                : CyrusColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? CyrusColors.gold : CyrusColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Protocol badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: CyrusColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  config.protocol.toUpperCase(),
                  style: const TextStyle(
                    color: CyrusColors.gold,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.remark,
                      style: const TextStyle(
                        color: CyrusColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      config.server,
                      style: const TextStyle(
                        color: CyrusColors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Latency
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    config.latencyText,
                    style: TextStyle(
                      color: _latencyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isActive)
                    const Text(
                      'فعال',
                      style: TextStyle(
                        color: CyrusColors.gold,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
