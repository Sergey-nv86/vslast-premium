import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../screens/main_screen.dart';
import 'admin_entry_screen.dart';

class AppModeSelectionScreen extends StatelessWidget {
  const AppModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Center(
                child: Image.asset(
                  'assets/images/logo_light.png',
                  width: 220,
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              const Center(
                child: Text(
                  'Выберите режим работы',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF201C1A),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  auth.displayName.isNotEmpty
                      ? 'Здравствуйте, ${auth.displayName}'
                      : 'Выберите, куда перейти',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF806F65),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              _ModeCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Иду за покупками',
                subtitle: 'Каталог, заказы, программа лояльности',
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              _ModeCard(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Администрирование',
                subtitle: 'Заказы, товары, производство и управление',
                onTap: () {
                  Navigator.of(context).pushReplacement(adminEntryRoute());
                },
              ),

              const Spacer(),

              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().signOut();

                    if (!context.mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Выйти из аккаунта'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8E0D5)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EAE1),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: const Color(0xFF8B5E3C), size: 27),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF201C1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF806F65),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: Color(0xFF806F65)),
            ],
          ),
        ),
      ),
    );
  }
}
