import 'package:flutter/material.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';

enum LegalDocumentType { privacyPolicy, termsOfService }

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final title = switch (type) {
      LegalDocumentType.privacyPolicy => 'Privacy Policy',
      LegalDocumentType.termsOfService => 'Terms of Service',
    };
    final sections = _sectionsFor(type);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final section in sections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          section.body,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_DocSection> _sectionsFor(LegalDocumentType type) {
    switch (type) {
      case LegalDocumentType.privacyPolicy:
        return const [
          _DocSection(
            title: 'Information We Use',
            body:
                'Liankhawpui uses account data, profile details, and content you create '
                '(news, announcements, comments, uploads) to deliver app features.',
          ),
          _DocSection(
            title: 'How Data Is Processed',
            body:
                'Data is stored in Supabase and synchronized for offline use through PowerSync. '
                'Push notification delivery is handled by OneSignal.',
          ),
          _DocSection(
            title: 'Security',
            body:
                'The app uses role-based access controls and backend policies. Sensitive server keys '
                'are never intended to be stored in the app client.',
          ),
          _DocSection(
            title: 'Contact',
            body:
                'For privacy requests or corrections, contact the Liankhawpui app administrator.',
          ),
        ];
      case LegalDocumentType.termsOfService:
        return const [
          _DocSection(
            title: 'Acceptable Use',
            body:
                'You agree to use the app for lawful village-community information sharing. '
                'Do not post harmful, abusive, or misleading content.',
          ),
          _DocSection(
            title: 'Account & Role Responsibility',
            body:
                'Editors and admins are responsible for moderation accuracy, announcements, and '
                'organization information updates.',
          ),
          _DocSection(
            title: 'Content Ownership',
            body:
                'You retain ownership of your submitted content. By publishing in the app, you grant '
                'Liankhawpui permission to display and distribute it in-app.',
          ),
          _DocSection(
            title: 'Service Changes',
            body:
                'Features may be updated or modified for reliability, security, and community benefit.',
          ),
        ];
    }
  }
}

class _DocSection {
  final String title;
  final String body;

  const _DocSection({required this.title, required this.body});
}
