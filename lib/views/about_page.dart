import 'package:flutter/material.dart';
import 'package:quiz_app/views/contact_support_sheet.dart';

const Color _kAboutBg = Color(0xFFF8F9FB);
const Color _kAboutTitle = Color(0xFF1A202C);
const Color _kAboutMuted = Color(0xFF718096);
const Color _kAboutSectionCaps = Color(0xFF94A3B8);
const Color _kAboutBorder = Color(0xFFE2E8F0);
const Color _kAboutNestedBg = Color(0xFFF1F5F9);
const Color _kAboutBullet = Color(0xFF818CF8);
const Color _kAboutNestedBorder = Color(0xFFBFDBFE);

/// Display name and marketing version shown on the About screen.
const String _kAboutAppVersionLabel = 'Voting App v1.0.0';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAboutBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: _kAboutTitle,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _kAboutTitle,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Details and support.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _kAboutMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _whiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionCaps('INFORMATION & SUPPORT'),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'App Version',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _kAboutTitle,
                                  ),
                                ),
                              ),
                              Text(
                                _kAboutAppVersionLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _kAboutTitle,
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            height: 28,
                            thickness: 1,
                            color: _kAboutBorder,
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => showContactSupportSheet(context),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.mail_outline_rounded,
                                    color: _kAboutMuted.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Contact Support',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _kAboutTitle,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: _kAboutMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _whiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'About AMAC',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _kAboutTitle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'American Muslim Advancement Council',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _kAboutMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _nestedInfoBlock(
                            title: 'Who We Are',
                            body:
                                'Muslims organizing to engage in the local, state, '
                                'and national political process. Currently we operate '
                                'primarily out of California and Washington state.',
                          ),
                          const SizedBox(height: 12),
                          _nestedInfoBlock(
                            title: 'Our Goal',
                            body:
                                'To advance Muslim participation, inclusion, and '
                                'consideration in politics and policy making.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _whiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'About This App',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _kAboutTitle,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'The Voting App amplifies your democratic voice by helping '
                            'you mobilize your friends and family to vote.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _kAboutMuted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _kAboutNestedBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kAboutNestedBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'How It Works',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _kAboutTitle,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _bullet(
                                  'Import your contacts and see their voter registration status',
                                ),
                                _bullet(
                                  'Identify which contacts are less likely to vote using propensity scores',
                                ),
                                _bullet(
                                  'Use pre-written message templates to encourage voting',
                                ),
                                _bullet(
                                  'Follow a proven 4-step plan to guide each contact to the polls',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCaps(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: _kAboutSectionCaps,
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAboutBorder),
      ),
      child: child,
    );
  }

  Widget _nestedInfoBlock({
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAboutNestedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kAboutTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kAboutMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _kAboutBullet,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kAboutMuted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
