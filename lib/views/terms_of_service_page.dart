import 'package:flutter/material.dart';

const Color _kTermsBg = Color(0xFFF9FAFB);
const Color _kTermsTitle = Color(0xFF1A1C1E);
const Color _kTermsMuted = Color(0xFF6B7280);
const Color _kTermsCheck = Color(0xFF3B82F6);
const Color _kTermsBorder = Color(0xFFE5E7EB);
const Color _kTermsRowSelected = Color(0xFFF3F4F6);

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  static const List<_DocRow> _rows = [
    _DocRow('Terms & Conditions', Icons.description_outlined),
    _DocRow('Privacy Policy', Icons.lock_outline_rounded),
    _DocRow('Acceptable Use Rules', Icons.gavel_rounded),
    _DocRow('Code of Conduct', Icons.verified_user_outlined),
    _DocRow('Data Processing Agreement', Icons.cloud_upload_outlined),
  ];

  int _highlightedIndex = 3;
  bool _agreed = false;

  void _onDocTap(int index) {
    setState(() => _highlightedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kTermsBg,
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
                    color: _kTermsTitle,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _kTermsTitle,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Policies, privacy, and compliance documents.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _kTermsMuted,
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _kTermsBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < _rows.length; i++)
                            _DocTile(
                              row: _rows[i],
                              selected: i == _highlightedIndex,
                              showDivider: i < _rows.length - 1,
                              onTap: () => _onDocTap(i),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Checkbox(
                            value: _agreed,
                            onChanged: (v) =>
                                setState(() => _agreed = v ?? false),
                            activeColor: _kTermsCheck,
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'I agree to AMAC Terms of Service policies.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _kTermsMuted.withValues(alpha: 0.95),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}

class _DocRow {
  final String title;
  final IconData icon;

  const _DocRow(this.title, this.icon);
}

class _DocTile extends StatelessWidget {
  final _DocRow row;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  const _DocTile({
    required this.row,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: selected ? _kTermsRowSelected : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Icon(row.icon, size: 24, color: _kTermsMuted),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      row.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kTermsTitle,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_rounded,
                    color: _kTermsCheck,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, indent: 54, color: _kTermsBorder),
      ],
    );
  }
}
