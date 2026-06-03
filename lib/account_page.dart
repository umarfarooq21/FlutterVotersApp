import 'package:flutter/material.dart';
import 'package:quiz_app/APIs/Storage/auth_storage.dart';
import 'package:quiz_app/login.dart';

const Color _kAccountBg = Color(0xFFF2F4F7);
const Color _kAccountPrimary = Color(0xFF1A5CFF);
const Color _kAccountTitle = Color(0xFF0F172A);
const Color _kAccountMuted = Color(0xFF64748B);
const Color _kAccountBorder = Color(0xFFE5E7EB);
const String _kAccountAvatarAsset = 'images/account_avatar.png';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _phoneCtrl;

  bool _obscurePassword = true;

  bool _msgReminders = true;
  bool _followUp = true;
  bool _weeklyDigest = false;
  bool _goalAlerts = true;
  final bool _termsUpdates = true;

  int _appearance = 2;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Amira Hassan');
    _emailCtrl = TextEditingController(text: 'amira@amacwa.org');
    _addressCtrl = TextEditingController(
      text: '1320 Lakeview Ave, Seattle, WA 98122',
    );
    _passwordCtrl = TextEditingController(text: '••••••••');
    _phoneCtrl = TextEditingController(text: '(206) 555-0148');
    _loadEmailFromSession();
  }

  Future<void> _loadEmailFromSession() async {
    final id = await AuthStorage.getUserId();
    if (!mounted || id == null || id.trim().isEmpty) return;
    final trimmed = id.trim();
    if (!trimmed.contains('@')) return;
    setState(() => _emailCtrl.text = trimmed);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({Widget? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccountBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccountBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccountPrimary, width: 1.5),
      ),
      suffixIcon: suffix,
    );
  }

  Future<void> _onLogout() async {
    await AuthStorage.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _onRequestDeletion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request account deletion'),
        content: const Text(
          'This will start the process to permanently delete your account '
          'and associated data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Request deletion'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion request submitted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAccountBg,
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
                    color: _kAccountTitle,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _kAccountTitle,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage your account and app preferences.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _kAccountMuted,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _profileCard(),
                    const SizedBox(height: 20),
                    _sectionHeader('NOTIFICATION PREFERENCES'),
                    const SizedBox(height: 10),
                    _notificationCard(),
                    const SizedBox(height: 20),
                    _sectionHeader('APPEARANCE'),
                    const SizedBox(height: 10),
                    _appearanceCard(),
                    const SizedBox(height: 20),
                    _sectionHeader('ACCOUNT ACTIONS'),
                    const SizedBox(height: 10),
                    _accountActionsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: _kAccountMuted,
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccountBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundImage: AssetImage(_kAccountAvatarAsset),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Photo upload coming soon.'),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ),
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
                    const Text(
                      'Profile photo',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kAccountTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to upload a new photo.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kAccountMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _labeledField('Full name', _nameCtrl),
          const SizedBox(height: 14),
          _labeledField('Email', _emailCtrl, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _labeledField('Address', _addressCtrl),
          const SizedBox(height: 14),
          _passwordField(),
          const SizedBox(height: 14),
          _labeledField(
            'Phone number',
            _phoneCtrl,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile changes saved.')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kAccountPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save profile changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController c, {
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kAccountMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboard,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kAccountTitle,
          ),
          decoration: _fieldDecoration(),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kAccountMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kAccountTitle,
          ),
          decoration: _fieldDecoration(
            suffix: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _kAccountMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _notificationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccountBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _notifTile('Message reminders', _msgReminders, (v) {
            setState(() => _msgReminders = v);
          }),
          const SizedBox(height: 8),
          _notifTile('Follow-up prompts', _followUp, (v) {
            setState(() => _followUp = v);
          }),
          const SizedBox(height: 8),
          _notifTile('Weekly summary digest', _weeklyDigest, (v) {
            setState(() => _weeklyDigest = v);
          }),
          const SizedBox(height: 8),
          _notifTile('Goal milestone alerts', _goalAlerts, (v) {
            setState(() => _goalAlerts = v);
          }),
          const SizedBox(height: 8),
          _notifTile(
            'Terms updates (required)',
            _termsUpdates,
            null,
            subtitle: 'Mandatory compliance notification.',
            activeTrackColor: const Color(0xFF93C5FD),
          ),
        ],
      ),
    );
  }

  Widget _notifTile(
    String title,
    bool value,
    ValueChanged<bool>? onChanged, {
    String? subtitle,
    Color? activeTrackColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccountBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kAccountTitle,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kAccountMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: activeTrackColor ?? _kAccountPrimary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }

  Widget _appearanceCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccountBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _appearanceOption(0, Icons.light_mode_outlined, 'Light')),
          const SizedBox(width: 8),
          Expanded(child: _appearanceOption(1, Icons.dark_mode_outlined, 'Dark')),
          const SizedBox(width: 8),
          Expanded(
            child: _appearanceOption(2, Icons.palette_outlined, 'System'),
          ),
        ],
      ),
    );
  }

  Widget _appearanceOption(int index, IconData icon, String label) {
    final selected = _appearance == index;
    return Material(
      color: selected ? const Color(0xFFEFF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _appearance = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _kAccountPrimary : _kAccountBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? _kAccountPrimary : _kAccountMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? _kAccountPrimary : _kAccountTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountActionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccountBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.gpp_maybe_outlined,
            label: 'Request account deletion',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: _onRequestDeletion,
          ),
          const Divider(height: 1, thickness: 1, color: _kAccountBorder),
          _actionTile(
            icon: Icons.logout,
            label: 'Log out',
            iconColor: _kAccountTitle,
            textColor: _kAccountTitle,
            onTap: _onLogout,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: label.contains('deletion') ? Colors.red : _kAccountMuted,
      ),
      onTap: onTap,
    );
  }
}
