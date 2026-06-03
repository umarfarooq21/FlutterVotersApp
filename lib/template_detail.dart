import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/APIs/api_service.dart';
import 'package:quiz_app/APIs/ResponseClasses/contacts_catwise_response.dart';
import 'package:quiz_app/APIs/Storage/auth_storage.dart';
import 'package:url_launcher/url_launcher.dart';

/// One row for the recipient picker (optional SMS number).
class TemplateRecipientOption {
  final String name;
  final String location;
  final String? phone;

  const TemplateRecipientOption({
    required this.name,
    required this.location,
    this.phone,
  });
}

class TemplateDetailPage extends StatefulWidget {
  final String recipientName;
  final String templateTitle;
  final String templateContent;
  final List<TemplateRecipientOption>? recipients;

  const TemplateDetailPage({
    super.key,
    required this.recipientName,
    required this.templateTitle,
    required this.templateContent,
    this.recipients,
  });

  @override
  State<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends State<TemplateDetailPage> {
  late TextEditingController _messageController;
  late String _selectedRecipientName;

  /// Filled from [ApiService.getContacts] when [widget.recipients] is not passed.
  List<TemplateRecipientOption> _apiRecipients = [];
  bool _contactsFetchComplete = false;
  bool _contactsFetchFailed = false;

  static const List<TemplateRecipientOption> _defaultRecipients = [
    TemplateRecipientOption(name: 'Aisha Rahman', location: 'Bellevue'),
    TemplateRecipientOption(name: 'Adam Harris', location: 'Seattle'),
    TemplateRecipientOption(name: 'Fatima Khan', location: 'Redmond'),
    TemplateRecipientOption(name: 'Hannah Lee', location: 'Kirkland'),
    TemplateRecipientOption(name: 'Layla Noor', location: 'Tacoma'),
  ];

  List<TemplateRecipientOption> get _pickerRecipients {
    if (widget.recipients != null && widget.recipients!.isNotEmpty) {
      return widget.recipients!;
    }
    if (!_contactsFetchComplete) {
      return _defaultRecipients;
    }
    if (_contactsFetchFailed) {
      return _defaultRecipients;
    }
    return _apiRecipients;
  }

  static TemplateRecipientOption _fromApiContact(ApiContactItem c) {
    final parts = [c.address.trim(), c.city.trim()]
        .where((s) => s.isNotEmpty)
        .toList();
    final loc = parts.isEmpty ? '—' : parts.join(', ');
    final name = c.name.trim().isEmpty ? 'Unknown' : c.name.trim();
    final phone = c.phone.trim();
    return TemplateRecipientOption(
      name: name,
      location: loc,
      phone: phone.isEmpty ? null : phone,
    );
  }

  Future<void> _loadContactsFromApi() async {
    if (widget.recipients != null && widget.recipients!.isNotEmpty) {
      return;
    }
    final userId = await AuthStorage.getUserId();
    final token = await AuthStorage.getAccessToken();
    if (!mounted) return;
    if (userId == null ||
        token == null ||
        userId.isEmpty ||
        token.isEmpty) {
      setState(() {
        _contactsFetchComplete = true;
        _contactsFetchFailed = true;
      });
      return;
    }
    setState(() => _contactsFetchFailed = false);
    final res = await ApiService.getContacts(userId: userId, token: token);
    if (!mounted) return;
    if (res == null) {
      setState(() {
        _contactsFetchComplete = true;
        _contactsFetchFailed = true;
        _apiRecipients = [];
      });
      return;
    }
    setState(() {
      _apiRecipients = res.contacts.map(_fromApiContact).toList();
      _contactsFetchComplete = true;
      _contactsFetchFailed = false;
    });
  }

  static const Color _kBorder = Color(0xFFE5E7EB);
  static const Color _kMuted = Color(0xFF6B7280);
  static const Color _kBlue = Color(0xFF2563EB);
  static const Color _kSelectedRow = Color(0xFFEFF6FF);

  @override
  void initState() {
    super.initState();
    final trimmed = widget.recipientName.trim();
    if (trimmed.isNotEmpty) {
      _selectedRecipientName = trimmed;
    } else if (_pickerRecipients.isNotEmpty) {
      _selectedRecipientName = _pickerRecipients.first.name;
    } else {
      _selectedRecipientName = '';
    }
    _messageController = TextEditingController(
      text: _personalizedMessage(_selectedRecipientName),
    );
    if (widget.recipients == null || widget.recipients!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadContactsFromApi());
    } else {
      _contactsFetchComplete = true;
    }
  }

  String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? fullName : parts.first;
  }

  String _personalizedMessage(String recipientFullName) {
    return widget.templateContent.replaceAll(
      '[Name]',
      _firstName(recipientFullName),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  List<TemplateRecipientOption> _recipientsForSheet() {
    final base = List<TemplateRecipientOption>.from(_pickerRecipients);
    final name = _selectedRecipientName.trim();
    final has = base.any((e) => e.name == name);
    if (!has && name.isNotEmpty) {
      base.add(TemplateRecipientOption(name: name, location: '—'));
    }
    base.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return base;
  }

  Future<void> _openRecipientSheet() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _RecipientPickerSheet(
          recipients: _recipientsForSheet(),
          initialName: _selectedRecipientName,
          selectedRowColor: _kSelectedRow,
          primaryBlue: _kBlue,
        );
      },
    );
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() {
        _selectedRecipientName = picked;
        _messageController.text = _personalizedMessage(picked);
      });
    }
  }

  String? _normalizeSmsPhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return null;
    return digits;
  }

  Future<void> _sendSms() async {
    final text = _messageController.text;
    String? phone;
    for (final r in _pickerRecipients) {
      if (r.name == _selectedRecipientName) {
        phone = r.phone;
        break;
      }
    }
    final normalized = _normalizeSmsPhone(phone);
    final Uri uri;
    if (normalized != null) {
      uri = Uri(
        scheme: 'sms',
        path: normalized,
        queryParameters: {'body': text},
      );
    } else {
      uri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the messaging app.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the messaging app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final detailTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: detailTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.black,
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize message',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.templateTitle,
                style: GoogleFonts.inter(
                  color: _kMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if ((widget.recipients == null || widget.recipients!.isEmpty) &&
                  !_contactsFetchComplete)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openRecipientSheet,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kBorder, width: 1),
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'To',
                                  style: GoogleFonts.inter(
                                    color: _kMuted,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _selectedRecipientName,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0F172A),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey.shade400,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _kBorder, width: 1),
                              color: Colors.white,
                            ),
                            child: TextField(
                              controller: _messageController,
                              maxLines: 8,
                              minLines: 6,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF0F172A),
                                height: 1.45,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  18,
                                  16,
                                  18,
                                ),
                                hintText: 'Type your message...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          top: 0,
                          child: ColoredBox(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                'SMS PREVIEW',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sendSms,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          'Send via SMS',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Opens your default messaging app with this text',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientPickerSheet extends StatefulWidget {
  final List<TemplateRecipientOption> recipients;
  final String initialName;
  final Color selectedRowColor;
  final Color primaryBlue;

  const _RecipientPickerSheet({
    required this.recipients,
    required this.initialName,
    required this.selectedRowColor,
    required this.primaryBlue,
  });

  @override
  State<_RecipientPickerSheet> createState() => _RecipientPickerSheetState();
}

class _RecipientPickerSheetState extends State<_RecipientPickerSheet> {
  late String _selected;
  late TextEditingController _search;
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialName;
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<TemplateRecipientOption> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.recipients;
    return widget.recipients
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q),
        )
        .toList();
  }

  Map<String, List<TemplateRecipientOption>> _grouped() {
    final map = <String, List<TemplateRecipientOption>>{};
    for (final c in _filtered) {
      final letter = c.name.isNotEmpty
          ? c.name[0].toUpperCase()
          : '#';
      map.putIfAbsent(letter, () => []).add(c);
    }
    final keys = map.keys.toList()..sort();
    final ordered = <String, List<TemplateRecipientOption>>{};
    for (final k in keys) {
      ordered[k] = map[k]!
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return ordered;
  }

  Color _avatarColor(String name) {
    const palette = [
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
    ];
    var h = 0;
    for (final u in name.codeUnits) {
      h = (h + u) % palette.length;
    }
    return palette[h];
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final grouped = _grouped();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'To',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          color: widget.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _search,
                  focusNode: _searchFocus,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search contacts',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Color(0xFFBFDBFE),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: widget.primaryBlue.withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: grouped.isEmpty
                    ? ListView(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 32,
                          bottom: 12 + bottom,
                        ),
                        children: [
                          Center(
                            child: Text(
                              _search.text.trim().isEmpty
                                  ? 'No contacts available.'
                                  : 'No contacts match your search.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.only(bottom: 12 + bottom),
                  itemCount: grouped.length,
                  itemBuilder: (context, sectionIndex) {
                    final letter = grouped.keys.elementAt(sectionIndex);
                    final items = grouped[letter]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                          child: Text(
                            letter,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        ...items.map((c) {
                          final selected = c.name == _selected;
                          return Material(
                            color: selected
                                ? widget.selectedRowColor
                                : Colors.white,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selected = c.name),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: _avatarColor(c.name),
                                      child: Text(
                                        _initials(c.name),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.location,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_circle,
                                        color: widget.primaryBlue,
                                        size: 24,
                                      )
                                    else
                                      const SizedBox(width: 24),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const Divider(height: 1, thickness: 1),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
