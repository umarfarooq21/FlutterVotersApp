import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/controllers/auth_controller.dart';
import 'package:quiz_app/views/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController emailCtrl;
  late TextEditingController passCtrl;

  bool obscure = true;

  @override
  void initState() {
    super.initState();
    // Keep empty by default (avoid shipping hard-coded credentials).
    //shaheryar@inabia.com
    //Shery1@#
    emailCtrl = TextEditingController(
      text: "shaheryar@inabia.com",
    ); //taha@inabia.com //muhammadj@inabia.com
    passCtrl = TextEditingController(text: "Shery1@#"); //Taha@510 //Jawwad@2490
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    final ok = await auth.login(
      email: emailCtrl.text,
      password: passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.isLoading;
    final size = MediaQuery.of(context).size;
    final cardMaxWidth = size.width < 440 ? size.width : 440.0;

    final baseTheme = Theme.of(context);
    final loginTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: loginTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _LoginBrandLogo(size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FRIEND BANKING',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2C69FF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B1220),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _SocialButton(
                          label: "Continue with Apple",
                          leading: const Icon(Icons.apple, size: 22),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          onTap: () {},
                        ),
                        const SizedBox(height: 10),
                        _SocialButton(
                          label: "Continue with Google",
                          leading: const _GoogleGMark(size: 22),
                          foregroundColor: const Color(0xFF0B1220),
                          backgroundColor: Colors.white,
                          borderColor: const Color(0xFFE6E8EF),
                          onTap: () {},
                        ),
                        const SizedBox(height: 10),
                        _SocialButton(
                          label: "Continue with Microsoft",
                          leading: const _MicrosoftMark(size: 20),
                          foregroundColor: const Color(0xFF0B1220),
                          backgroundColor: Colors.white,
                          borderColor: const Color(0xFFE6E8EF),
                          onTap: () {},
                        ),
                        const SizedBox(height: 16),
                        const _OrDivider(),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0B1220),
                          ),
                          decoration: _fieldDecoration(
                            hintText: "Email",
                            prefixIcon: Icons.mail_outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passCtrl,
                          obscureText: obscure,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0B1220),
                          ),
                          decoration:
                              _fieldDecoration(
                                hintText: "Password",
                                prefixIcon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => obscure = !obscure),
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF9AA3B2),
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2C69FF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {},
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onLoginPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F5EFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Sign in",
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    "Your account is secured with modern encryption and\noptional device authentication.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8A94A6),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String hintText,
  required IconData prefixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.inter(
      color: const Color(0xFFB3BBC9),
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: const Color(0xFFF6F7FA),
    prefixIcon: Icon(prefixIcon, color: const Color(0xFF9AA3B2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE6E8EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE6E8EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF1F5EFF), width: 1.6),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE6E8EF), height: 1)),
        const SizedBox(width: 12),
        Text(
          "OR",
          style: GoogleFonts.inter(
            color: const Color(0xFFB3BBC9),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFE6E8EF), height: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onTap,
    required this.foregroundColor,
    required this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor ?? backgroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _MicrosoftMark extends StatelessWidget {
  const _MicrosoftMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final gap = size * 0.12;
    final tile = (size - gap) / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children:
            const [
              _MsTile(Color(0xFFF25022)),
              _MsTile(Color(0xFF7FBA00)),
              _MsTile(Color(0xFF00A4EF)),
              _MsTile(Color(0xFFFFB900)),
            ].map((w) {
              return SizedBox(width: tile, height: tile, child: w);
            }).toList(),
      ),
    );
  }
}

class _MsTile extends StatelessWidget {
  const _MsTile(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}

class _GoogleGMark extends StatelessWidget {
  const _GoogleGMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

/// White rounded tile, thin border, and padded logo (matches login header mock).
class _LoginBrandLogo extends StatelessWidget {
  final double size;

  const _LoginBrandLogo({required this.size});

  static const Color _kBorder = Color(0xFFE6E8EF);

  @override
  Widget build(BuildContext context) {
    final outerR = size * 0.28;
    final innerR = (outerR - 6).clamp(6.0, outerR);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(outerR),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerR),
        child: Image.asset(
          'images/icon/app_icon.png',
          fit: BoxFit.contain,
          errorBuilder: (context, err, st) {
            return Image.asset(
              'images/icon/poole.png',
              fit: BoxFit.contain,
              errorBuilder: (context2, err2, st2) {
                return const Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF1F5EFF),
                    size: 28,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide * 0.48;
    final innerR = outerR * 0.62;

    Path ringSegment(double startDeg, double sweepDeg) {
      final outer = Rect.fromCircle(center: center, radius: outerR);
      final inner = Rect.fromCircle(center: center, radius: innerR);
      final start = _deg(startDeg);
      final sweep = _deg(sweepDeg);

      final p = Path()
        ..addArc(outer, start, sweep)
        ..arcTo(inner, start + sweep, -sweep, false)
        ..close();
      return p;
    }

    final fill = Paint()..style = PaintingStyle.fill;

    // Angles chosen to resemble the official Google "G" mark.
    // We leave an opening on the right side, then draw the blue crossbar.
    fill.color = const Color(0xFFEA4335); // red (top)
    canvas.drawPath(ringSegment(-20, 95), fill);

    fill.color = const Color(0xFF4285F4); // blue (right-top)
    canvas.drawPath(ringSegment(75, 70), fill);

    fill.color = const Color(0xFF34A853); // green (right-bottom)
    canvas.drawPath(ringSegment(165, 75), fill);

    fill.color = const Color(0xFFFBBC05); // yellow (bottom-left)
    canvas.drawPath(ringSegment(240, 90), fill);

    // Blue crossbar.
    final barH = (outerR - innerR) * 0.92;
    final barW = outerR * 0.95;
    final barTop = center.dy - barH / 2;
    final barLeft = center.dx + innerR * 0.15;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barW, barH),
      Radius.circular(barH / 2),
    );
    fill.color = const Color(0xFF4285F4);
    canvas.drawRRect(barRect, fill);
  }

  double _deg(double deg) => deg * 3.141592653589793 / 180.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
