import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/channel_model.dart';
import '../theme.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('کانال‌های تلگرام',
                style: TextStyle(color: CyrusColors.gold, letterSpacing: 1)),
            actions: [
              if (provider.isFetchingChannels)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: CyrusColors.gold, strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: CyrusColors.gold),
                  tooltip: 'آپدیت همه',
                  onPressed: () => provider.fetchAllChannels(),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddChannelDialog(context, provider),
            backgroundColor: CyrusColors.gold,
            foregroundColor: CyrusColors.background,
            child: const Icon(Icons.add),
          ),
          body: provider.channels.isEmpty
              ? _buildEmpty(context, provider)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.channels.length,
                  itemBuilder: (context, i) => _ChannelTile(
                    channel: provider.channels[i],
                    onRefresh: () => provider.fetchChannel(provider.channels[i]),
                    onDelete: () => provider.deleteChannel(provider.channels[i]),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.send_outlined,
              color: CyrusColors.greyDark, size: 64),
          const SizedBox(height: 16),
          const Text(
            'هیچ کانالی ندارید',
            style: TextStyle(color: CyrusColors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'یه کانال تلگرام با کانفیگ‌های VPN اضافه کنید',
            style: TextStyle(color: CyrusColors.greyDark, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddChannelDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('افزودن کانال'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyrusColors.gold,
              foregroundColor: CyrusColors.background,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChannelDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyrusColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CyrusColors.border),
        ),
        title: const Text(
          'افزودن کانال',
          style: TextStyle(color: CyrusColors.gold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'آدرس کانال تلگرام را وارد کنید',
              style: TextStyle(color: CyrusColors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: CyrusColors.white),
              decoration: InputDecoration(
                hintText: '@channel یا t.me/channel',
                hintStyle: const TextStyle(color: CyrusColors.greyDark),
                prefixIcon:
                    const Icon(Icons.send, color: CyrusColors.gold, size: 18),
                filled: true,
                fillColor: CyrusColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CyrusColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CyrusColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CyrusColors.gold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لغو',
                style: TextStyle(color: CyrusColors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addChannel(controller.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyrusColors.gold,
              foregroundColor: CyrusColors.background,
            ),
            child: const Text('اضافه کن'),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _ChannelTile({
    required this.channel,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isFetching = channel.status == 'fetching';

    return Dismissible(
      key: Key(channel.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: CyrusColors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: CyrusColors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyrusColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CyrusColors.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: CyrusColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send, color: CyrusColors.gold, size: 20),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.displayName,
                    style: const TextStyle(
                      color: CyrusColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${channel.configCount} کانفیگ',
                        style: const TextStyle(
                            color: CyrusColors.gold, fontSize: 12),
                      ),
                      const Text(' • ',
                          style: TextStyle(color: CyrusColors.greyDark)),
                      Text(
                        channel.lastFetchedText,
                        style: const TextStyle(
                            color: CyrusColors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Refresh button
            if (isFetching)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: CyrusColors.gold, strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh, color: CyrusColors.gold),
                onPressed: onRefresh,
              ),
          ],
        ),
      ),
    );
  }
}
