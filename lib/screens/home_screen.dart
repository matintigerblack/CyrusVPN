import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../services/vpn_service.dart';
import '../services/health_monitor.dart';
import '../theme.dart';
import 'channels_screen.dart';
import 'configs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _DashboardTab(),
    ConfigsScreen(),
    ChannelsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: CyrusColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'اتصال',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_outlined),
              activeIcon: Icon(Icons.list),
              label: 'کانفیگ‌ها',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.send_outlined),
              activeIcon: Icon(Icons.send),
              label: 'کانال‌ها',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(context),
                ),
                // Connection Button
                SliverToBoxAdapter(
                  child: _buildConnectionSection(context, provider),
                ),
                // Stats
                if (provider.isConnected)
                  SliverToBoxAdapter(
                    child: _buildStats(context, provider),
                  ),
                // Status message
                if (provider.statusMessage.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildStatusMessage(context, provider),
                  ),
                // Active config info
                if (provider.activeConfig != null)
                  SliverToBoxAdapter(
                    child: _buildActiveConfig(context, provider),
                  ),
                // Health monitor
                if (provider.isConnected)
                  SliverToBoxAdapter(
                    child: _buildHealthIndicator(context, provider),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'CYRUS',
            style: TextStyle(
              color: CyrusColors.gold,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: CyrusColors.gold, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'VPN',
              style: TextStyle(
                color: CyrusColors.gold,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildConnectionSection(BuildContext context, AppProvider provider) {
    final isConnected = provider.isConnected;
    final isConnecting = provider.isConnecting;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: GestureDetector(
          onTap: provider.toggleConnection,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              if (isConnected)
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CyrusColors.gold.withOpacity(0.15),
                      width: 2,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      duration: 2000.ms,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.08, 1.08),
                      end: const Offset(1, 1),
                      duration: 2000.ms,
                    ),
              // Main button
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isConnected
                        ? [
                            CyrusColors.gold.withOpacity(0.3),
                            CyrusColors.surface,
                          ]
                        : isConnecting
                            ? [
                                CyrusColors.gold.withOpacity(0.1),
                                CyrusColors.surface,
                              ]
                            : [
                                CyrusColors.surfaceLight,
                                CyrusColors.surface,
                              ],
                  ),
                  border: Border.all(
                    color: isConnected
                        ? CyrusColors.gold
                        : isConnecting
                            ? CyrusColors.gold.withOpacity(0.5)
                            : CyrusColors.border,
                    width: 2,
                  ),
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: CyrusColors.gold.withOpacity(0.25),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isConnecting)
                      const CircularProgressIndicator(
                        color: CyrusColors.gold,
                        strokeWidth: 2,
                      )
                    else
                      Icon(
                        isConnected
                            ? Icons.shield
                            : Icons.shield_outlined,
                        size: 48,
                        color: isConnected
                            ? CyrusColors.gold
                            : CyrusColors.grey,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      isConnecting
                          ? 'در حال اتصال'
                          : isConnected
                              ? 'متصل'
                              : 'اتصال',
                      style: TextStyle(
                        color: isConnected
                            ? CyrusColors.gold
                            : CyrusColors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.arrow_upward,
            label: 'آپلود',
            value: provider.uploadSpeed,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.arrow_downward,
            label: 'دانلود',
            value: provider.downloadSpeed,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.timer_outlined,
            label: 'زمان',
            value: provider.connectionDuration,
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildStatusMessage(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: CyrusColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CyrusColors.border),
        ),
        child: Text(
          provider.statusMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CyrusColors.grey, fontSize: 13),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildActiveConfig(BuildContext context, AppProvider provider) {
    final config = provider.activeConfig!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyrusColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CyrusColors.gold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_outlined,
                    color: CyrusColors.gold, size: 16),
                const SizedBox(width: 8),
                const Text('سرور فعال',
                    style: TextStyle(
                        color: CyrusColors.gold,
                        fontSize: 12,
                        letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              config.remark,
              style: const TextStyle(
                  color: CyrusColors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${config.server} : ${config.port}',
              style: const TextStyle(color: CyrusColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              config.protocol.toUpperCase(),
              style: const TextStyle(
                  color: CyrusColors.goldDark,
                  fontSize: 11,
                  letterSpacing: 1),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildHealthIndicator(BuildContext context, AppProvider provider) {
    final healthColors = {
      HealthState.healthy: CyrusColors.green,
      HealthState.degrading: CyrusColors.yellow,
      HealthState.critical: CyrusColors.red,
      HealthState.dead: CyrusColors.red,
    };

    final healthLabels = {
      HealthState.healthy: 'اتصال پایدار',
      HealthState.degrading: 'اتصال ضعیف',
      HealthState.critical: 'اتصال بحرانی',
      HealthState.dead: 'قطع شده',
    };

    final color = healthColors[provider.healthState]!;
    final label = healthLabels[provider.healthState]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.4, 1.4),
                duration: 1000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.4, 1.4),
                end: const Offset(1, 1),
                duration: 1000.ms,
              ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: CyrusColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CyrusColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: CyrusColors.gold, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: CyrusColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text(label,
                style: const TextStyle(
                    color: CyrusColors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
