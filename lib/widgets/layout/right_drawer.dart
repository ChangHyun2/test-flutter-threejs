import 'package:flutter/material.dart';

class RightDrawer extends StatelessWidget {
  const RightDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Right Panel',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Panel Content
          Expanded(
            child: ListView(
              children: [
                _buildPanelItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'App configuration',
                ),
                _buildPanelItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: '3 new messages',
                ),
                _buildPanelItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get assistance',
                ),
                _buildPanelItem(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App information',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () {
          // Handle panel item tap
        },
      ),
    );
  }
}

