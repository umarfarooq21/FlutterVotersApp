import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/views/template_detail.dart';

class MessageTemplatePage extends StatelessWidget {
  final String recipientName;

  const MessageTemplatePage({super.key, this.recipientName = "Muhammad Ali"});

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final msgTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: msgTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: Text(
            "Select Message",
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Text(
                "MESSAGE TEMPLATES",
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              _MessageTemplateCard(
                title: "Initial Outreach",
                snippet:
                    "Salaam [Name]! I'm volunteering with AMAC to help get out the vote. Are you...",
                fullContent:
                    "Salaam [Name]! I'm volunteering with AMAC to help get out the vote. Are you planning to vote in the upcoming election?",
                titleColor: const Color(0xFF3B82F6),
                iconColor: const Color(0xFF3B82F6),
                recipientName: recipientName,
                onTap: (title, content) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TemplateDetailPage(
                        recipientName: recipientName,
                        templateTitle: title,
                        templateContent: content,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MessageTemplateCard(
                title: "Registration Check",
                snippet:
                    "Hi [Name], checking in to see if you've had a chance to update your voter registration...",
                fullContent:
                    "Hi [Name], checking in to see if you've had a chance to update your voter registration? Let me know if you need help!",
                titleColor: Colors.black,
                iconColor: const Color(0xFF374151),
                recipientName: recipientName,
                onTap: (title, content) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TemplateDetailPage(
                        recipientName: recipientName,
                        templateTitle: title,
                        templateContent: content,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MessageTemplateCard(
                title: "Election Day Reminder",
                snippet:
                    "Don't forget to vote tomorrow! Polls are open from 7am to 8pm. Do you need a...",
                fullContent:
                    "Don't forget to vote tomorrow! Polls are open from 7am to 8pm. Do you need a ride to the polls?",
                titleColor: Colors.black,
                iconColor: const Color(0xFF374151),
                recipientName: recipientName,
                onTap: (title, content) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TemplateDetailPage(
                        recipientName: recipientName,
                        templateTitle: title,
                        templateContent: content,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageTemplateCard extends StatelessWidget {
  final String title;
  final String snippet;
  final String fullContent;
  final Color titleColor;
  final Color iconColor;
  final String recipientName;
  final void Function(String title, String content) onTap;

  const _MessageTemplateCard({
    required this.title,
    required this.snippet,
    required this.fullContent,
    required this.titleColor,
    required this.iconColor,
    required this.recipientName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onTap(title, fullContent),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: iconColor,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: titleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
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
