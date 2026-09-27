import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'legal_config.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Документы и согласия'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _DocumentCard(
            title: LegalConfig.personalDataConsentTitle,
            subtitle: 'Отдельное согласие на обработку персональных данных',
            onTap: () => openDocument(
              context,
              LegalConfig.personalDataConsentTitle,
              LegalConfig.personalDataConsentText,
            ),
          ),
          const SizedBox(height: 12),
          _DocumentCard(
            title: LegalConfig.marketingConsentTitle,
            subtitle: 'Добровольное согласие на рекламу и специальные предложения',
            onTap: () => openDocument(
              context,
              LegalConfig.marketingConsentTitle,
              LegalConfig.marketingConsentText,
            ),
          ),
          const SizedBox(height: 12),
          _DocumentCard(
            title: LegalConfig.termsTitle,
            subtitle: 'Условия использования сервиса',
            onTap: () => openDocument(
              context,
              LegalConfig.termsTitle,
              LegalConfig.termsText,
            ),
          ),
          const SizedBox(height: 12),
          _DocumentCard(
            title: LegalConfig.privacyPolicyTitle,
            subtitle: 'Правила обработки и защиты персональных данных',
            onTap: () => openDocument(
              context,
              LegalConfig.privacyPolicyTitle,
              LegalConfig.privacyPolicyText,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Версия документов: ${LegalConfig.documentVersion}',
            style: AppTextStyles.rowLabelMuted,
          ),
        ],
      ),
    );
  }

  static void openDocument(BuildContext context, String title, String text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LegalDocumentPage(title: title, text: text),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.primaryBrown),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.rowLabelMuted),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalDocumentPage extends StatelessWidget {
  final String title;
  final String text;

  const _LegalDocumentPage({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(title),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
