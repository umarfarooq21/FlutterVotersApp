import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kSupportPrimary = Color(0xFF1A5CFF);
const Color _kSupportBorder = Color(0xFFE2E8F0);
const Color _kSupportMuted = Color(0xFF718096);
const String _kSupportEmail = 'support@amacwa.org';

Future<void> showContactSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const ContactSupportSheet(),
  );
}

class ContactSupportSheet extends StatefulWidget {
  const ContactSupportSheet({super.key});

  @override
  State<ContactSupportSheet> createState() => _ContactSupportSheetState();
}

class _ContactSupportSheetState extends State<ContactSupportSheet> {
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  XFile? _attachment;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kSupportBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kSupportBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kSupportPrimary, width: 1.5),
      ),
    );
  }

  Future<void> _openMailApp() async {
    final uri = Uri.parse('mailto:$_kSupportEmail');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open mail app.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open mail app.')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload is not available on web.')),
        );
      }
      return;
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => _attachment = file);
  }

  Future<void> _sendMessage() async {
    final subject = _subjectCtrl.text.trim();
    final body = _messageCtrl.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject and message.')),
      );
      return;
    }

    var mailBody = body;
    if (_attachment != null) {
      mailBody = '$body\n\n[Note: attach "${_attachment!.name}" manually in your mail app if needed.]';
    }

    final mailUri = Uri.parse(
      'mailto:$_kSupportEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(mailBody)}',
    );
    try {
      final ok = await launchUrl(mailUri, mode: LaunchMode.externalApplication);
      if (ok && mounted) Navigator.of(context).pop();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open mail app.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open mail app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final maxH = MediaQuery.of(context).size.height * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: maxH,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kSupportPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _kSupportBorder),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Messages are sent to',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kSupportMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            _kSupportEmail,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A202C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _openMailApp,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: _kSupportPrimary,
                            ),
                            child: const Text(
                              'Open in Mail app',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Subject',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSupportMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _subjectCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDeco(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSupportMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDeco(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kSupportBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attachment (optional)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kSupportMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _attachment == null
                                      ? 'No image selected'
                                      : _attachment!.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A202C),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _pickImage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A202C),
                              side: const BorderSide(color: _kSupportBorder),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              'Upload image',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _sendMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kSupportPrimary,
                          foregroundColor: Colors.white,
                          shape: StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send message',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
}
