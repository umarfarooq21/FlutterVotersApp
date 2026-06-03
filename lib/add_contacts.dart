import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quiz_app/APIs/ResponseClasses/fuzzy_search_response.dart';
import 'package:quiz_app/APIs/Storage/auth_storage.dart';
import 'package:quiz_app/APIs/api_service.dart';
import 'package:quiz_app/contact_name_format.dart';
import 'package:shimmer/shimmer.dart';

/// Primary blue aligned with contacts / app chrome.
const Color _kAddContactBlue = Color(0xFF1D4ED8);
const Color _kAddContactBlueTint = Color(0xFFEFF6FF);
const Color _kStepGray = Color(0xFFD1D5DB);
const Color _kBodyGray = Color(0xFF6B7280);
const Color _kFooterGray = Color(0xFF9CA3AF);

class AddContactsPage extends StatefulWidget {
  const AddContactsPage({super.key});

  @override
  State<AddContactsPage> createState() => _AddContactsPageState();
}

class _AddContactsPageState extends State<AddContactsPage> {
  int _currentStep = 1;
  String? _selectedContactName;
  int _selectedMatchIndex = 0;
  String _selectedConnectionType = "Friend";
  List<FuzzySearchMatch> _matches = [];
  bool _searchLoading = false;
  String? _searchError;
  bool _saveLoading = false;

  static const _connectionTypes = [
    "Friend",
    "Spouse",
    "Parent",
    "Sibling",
    "Cousin",
    "Relative",
    "Roommate",
  ];

  Future<void> _selectContact(BuildContext context) async {
    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Contacts Permission Required"),
            content: const Text(
              "Please allow contacts access in settings to select a contact.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
      }
      return;
    }

    final contact = await FlutterContacts.openExternalPick();
    if (!context.mounted || contact == null) return;

    final name = contact.displayName.trim();
    setState(() {
      _selectedContactName = name.isEmpty ? 'Unknown' : name;
      _currentStep = 2;
      _selectedMatchIndex = 0;
      _matches = [];
      _searchError = null;
      _searchLoading = true;
    });
    await _fetchFuzzyMatches(name);
  }

  Future<void> _fetchFuzzyMatches(String fullName) async {
    final query = fullName.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchLoading = false;
        _searchError = 'Enter a name to search the voter file.';
        _matches = [];
      });
      return;
    }

    try {
      if (!await AuthStorage.hasSession()) {
        if (!mounted) return;
        setState(() {
          _searchLoading = false;
          _searchError = 'Sign in to search the voter file.';
          _matches = [];
        });
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null ||
          token == null ||
          userId.isEmpty ||
          token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _searchLoading = false;
          _searchError = 'Sign in to search the voter file.';
          _matches = [];
        });
        return;
      }

      final results = await ApiService.fuzzySearchApp(
        userId: userId,
        token: token,
        fullNames: query,
      );

      if (!mounted) return;

      if (results == null) {
        setState(() {
          _searchLoading = false;
          _searchError = 'Could not load matches. Pull to try again.';
          _matches = [];
        });
        return;
      }

      setState(() {
        _matches = results;
        _searchLoading = false;
        _searchError = results.isEmpty
            ? 'No voter file matches found for this name.'
            : null;
        _selectedMatchIndex = 0;
      });
    } catch (e, st) {
      debugPrint('AddContacts fuzzySearch: $e\n$st');
      if (!mounted) return;
      setState(() {
        _searchLoading = false;
        _searchError = 'Could not load matches. Try again.';
        _matches = [];
      });
    }
  }

  FuzzySearchMatch? get _selectedMatch {
    if (_matches.isEmpty ||
        _selectedMatchIndex < 0 ||
        _selectedMatchIndex >= _matches.length) {
      return null;
    }
    return _matches[_selectedMatchIndex];
  }

  void _onBack() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
        _selectedContactName = null;
        _matches = [];
        _searchError = null;
        _searchLoading = false;
      });
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 2);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 20, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: _onBack,
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Add Contact",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _LinearStepHeader(currentStep: _currentStep),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              ],
            ),
          ),
          Expanded(
            child: _currentStep == 1
                ? _buildStep1()
                : _currentStep == 2
                    ? _buildStep2()
                    : _buildStep3(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(
                      color: _kAddContactBlueTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 52,
                      color: _kAddContactBlue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                      children: [
                        const TextSpan(
                          text: "1/3 ",
                          style: TextStyle(color: _kAddContactBlue),
                        ),
                        TextSpan(
                          text: "Import from Contacts",
                          style: TextStyle(color: Colors.grey.shade900),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Select a contact from your phone's address book to check their registration status.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _kBodyGray,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _selectContact(context),
                      icon: const Icon(Icons.search, color: Colors.white, size: 22),
                      label: const Text(
                        "Select Contact",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAddContactBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "We verify against the voter file securely.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _kFooterGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2() {
    final displayName = formatContactDisplayName(_selectedContactName ?? '');
    final confirmFirst = _selectedMatch?.displayName.split(' ').first ??
        displayName.split(' ').first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.grey.shade900,
            ),
            children: const [
              TextSpan(
                text: "2/3 ",
                style: TextStyle(color: _kAddContactBlue),
              ),
              TextSpan(text: "Confirm Match"),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "Select the correct voter file for '$displayName'.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        if (_searchLoading)
          ...List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _MatchCardShimmer(),
              ))
        else if (_searchError != null && _matches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _searchError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          )
        else
          ...List.generate(_matches.length, (i) {
            final m = _matches[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MatchCard(
                name: m.displayName,
                location: m.displayLocation,
                age: m.displayAge,
                matchTag: m.matchTag,
                selected: _selectedMatchIndex == i,
                onTap: () => setState(() => _selectedMatchIndex = i),
              ),
            );
          }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _searchLoading || _selectedContactName == null
              ? null
              : () {
                  setState(() {
                    _searchLoading = true;
                    _searchError = null;
                  });
                  _fetchFuzzyMatches(_selectedContactName!);
                },
          icon: const Icon(Icons.tune, size: 20, color: Color(0xFF6B7280)),
          label: const Text(
            "Refine Search Results",
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "None of these look right? ",
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                "Add Manually",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _searchLoading || _selectedMatch == null
                ? null
                : () => setState(() => _currentStep = 3),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAddContactBlue,
              disabledBackgroundColor: const Color(0xFF93C5FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: Text(
              "Confirm $confirmFirst",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final displayName = _selectedMatch?.displayName ??
        formatContactDisplayName(_selectedContactName ?? '');
    final initials = _getInitials(displayName);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: _kAddContactBlueTint,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: _kAddContactBlue,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
               Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.grey.shade900,
            ),
            children: const [
              TextSpan(
                text: "3/3 ",
                style: TextStyle(color: _kAddContactBlue),
              ),
              TextSpan(text: "How do you know them?"),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          "Select your connection type",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        ..._connectionTypes.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ConnectionTypeCard(
              label: type,
              selected: _selectedConnectionType == type,
              onTap: () => setState(() => _selectedConnectionType = type),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _saveLoading ? null : _saveContact,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAddContactBlue,
              disabledBackgroundColor: const Color(0xFF93C5FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: _saveLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Save Contact",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveContact() async {
    final match = _selectedMatch;
    if (match == null) return;

    setState(() => _saveLoading = true);

    try {
      if (!await AuthStorage.hasSession()) {
        if (!mounted) return;
        setState(() => _saveLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save a contact.')),
        );
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        if (!mounted) return;
        setState(() => _saveLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save a contact.')),
        );
        return;
      }

      // Fetch relations to resolve the selected connection type to a RelationId.
      final relations = await ApiService.getRelations(
        userId: userId,
        token: token,
      );
      final relation = relations?.firstWhere(
        (r) => r.relationName
            .toLowerCase()
            .contains(_selectedConnectionType.toLowerCase()),
        orElse: () => relations!.first,
      );
      final relationId = relation?.id ?? 16;
      final desc = relation?.relationName ?? _selectedConnectionType;

      final message = await ApiService.saveContactNew(
        userId: userId,
        token: token,
        captainId: userId,
        voterId: match.stateVoterId,
        relationId: relationId,
        desc: desc,
        name: match.fullNames,
        city: match.regCity,
        address: match.fullAddress,
        voterStatus: match.voterStatus,
        phone: match.phone,
      );

      if (!mounted) return;
      setState(() => _saveLoading = false);

      if (message != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save contact. Please try again.'),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('saveContact error: $e\n$st');
      if (!mounted) return;
      setState(() => _saveLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return "?";
    final first = parts.first;
    final last = parts.length > 1 ? parts.last : "";
    return "${first.isNotEmpty ? first[0] : "?"}${last.isNotEmpty ? last[0] : ""}"
        .toUpperCase();
  }
}

class _ConnectionTypeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ConnectionTypeCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? _kAddContactBlue : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _kAddContactBlue : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A000000),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinearStepHeader extends StatelessWidget {
  final int currentStep;

  const _LinearStepHeader({required this.currentStep});

  static const double _barWidth = 22;
  static const double _barHeight = 3;

  @override
  Widget build(BuildContext context) {
    TextStyle labelStyle(int stepIndex) {
      final active = currentStep >= stepIndex;
      return TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: active ? _kAddContactBlue : _kStepGray,
      );
    }

    /// Segment after step `afterStep` (1 → between 1/3 & 2/3, 2 → between 2/3 & 3/3, 3 → after 3/3).
    Widget bar(int afterStep) {
      final filled = currentStep >= afterStep;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          width: _barWidth,
          height: _barHeight,
          decoration: BoxDecoration(
            color: filled ? _kAddContactBlue : _kStepGray,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("1/3", style: labelStyle(1)),
        bar(1),
        Text("2/3", style: labelStyle(2)),
        bar(2),
        Text("3/3", style: labelStyle(3)),
        bar(3),
      ],
    );
  }
}

class _MatchCardShimmer extends StatelessWidget {
  const _MatchCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String name;
  final String location;
  final String age;
  final String matchTag;
  final bool selected;
  final VoidCallback onTap;

  const _MatchCard({
    required this.name,
    required this.location,
    required this.age,
    required this.matchTag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _kAddContactBlue : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _kAddContactBlue : Colors.transparent,
                  border: Border.all(
                    color: selected ? _kAddContactBlue : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$location • $age",
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _MatchTag(label: matchTag),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTag extends StatelessWidget {
  final String label;

  const _MatchTag({required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (label) {
      case "VERY LIKELY":
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case "LIKELY":
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFF59E0B);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == "VERY LIKELY")
            Icon(Icons.shield_outlined, size: 14, color: fg),
          if (label == "VERY LIKELY") const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
