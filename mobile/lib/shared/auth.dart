import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api.dart';
import 'role_router.dart';
import 'theme.dart';
import 'tokens.dart';
import 'widgets/cta_button.dart';
import 'widgets/dot_leader.dart';
import 'widgets/sindh_tile.dart';

class Session {
  String? token;
  String? userId;
  String role = 'citizen';
  String apiBase = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
}

final session = Session();

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final sp = await SharedPreferences.getInstance();
    session.token = sp.getString('token');
    session.userId = sp.getString('userId');
    session.role = sp.getString('role') ?? 'citizen';
    session.apiBase = sp.getString('apiBase') ?? session.apiBase;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: PulseColors.ink900,
        body: Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: PulseColors.signal),
          ),
        ),
      );
    }
    if (session.token == null) return const SignInPage();
    return const RoleRouter();
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _phone = TextEditingController(text: '03149946492');
  final _otp = TextEditingController();
  final _api = TextEditingController(text: session.apiBase);
  String _role = 'citizen';
  bool _otpSent = false;
  String? _error;
  bool _busy = false;

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      session.apiBase = _api.text.trim();
      await ApiClient.shared.requestOtp(_phone.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ApiClient.shared.verifyOtp(
        phone: _phone.text.trim(),
        otp: _otp.text.trim(),
        role: _role,
      );
      session.token = r['token'];
      session.userId = r['user_id'];
      session.role = r['role'];
      final sp = await SharedPreferences.getInstance();
      await sp.setString('token', session.token!);
      await sp.setString('userId', session.userId!);
      await sp.setString('role', session.role);
      await sp.setString('apiBase', session.apiBase);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RoleRouter()));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.ink900,
      body: Stack(
        children: [
          // Tactical Humanitarian Redesign: Massive centered watermark
          const Positioned.fill(
            child: Center(
              child: SindhTile(opacity: 0.03, size: 800),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x6, vertical: PulseSpace.x8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: PulseColors.ink800.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(PulseRadii.xxl),
                      border: Border.all(color: PulseColors.hairlineStrong, width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(PulseSpace.x6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('PULSE', style: PulseTheme.wordmark(size: 48)),
                            const SizedBox(width: PulseSpace.x3),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('v0.2', style: PulseTheme.dataXs()),
                            ),
                          ],
                        ),
                        const SizedBox(height: PulseSpace.x2),
                        const DotLeader(label: 'systems', value: 'Urban Crisis Response · Islamabad'),
                        const SizedBox(height: PulseSpace.x8),
                        _Field(label: 'API ENDPOINT', controller: _api, hint: 'http://localhost:8000', mono: true),
                        const SizedBox(height: PulseSpace.x4),
                        _Field(
                          label: 'PHONE',
                          controller: _phone,
                          hint: '03149946492',
                          keyboardType: TextInputType.phone,
                          mono: true,
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: PulseSpace.x4),
                          _Field(
                            label: 'ONE-TIME CODE',
                            controller: _otp,
                            hint: '654321',
                            keyboardType: TextInputType.number,
                            mono: true,
                          ),
                          const SizedBox(height: PulseSpace.x4),
                          Text('ROLE', style: PulseTheme.label()),
                          const SizedBox(height: PulseSpace.x2),
                          _RoleSelector(value: _role, onChanged: (v) => setState(() => _role = v)),
                        ],
                        const SizedBox(height: PulseSpace.x6),
                        CtaButton(
                          label: _otpSent ? 'Verify & continue' : 'Request OTP',
                          loading: _busy,
                          onPressed: _busy ? null : (_otpSent ? _verify : _request),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: PulseSpace.x3),
                          Container(
                            padding: const EdgeInsets.all(PulseSpace.x3),
                            decoration: BoxDecoration(
                              color: PulseColors.crimson.withValues(alpha: 0.06),
                              border: Border.all(color: PulseColors.crimson, width: 1),
                              borderRadius: BorderRadius.circular(PulseRadii.sm),
                            ),
                            child: Text(_error!, style: PulseTheme.dataSm(color: PulseColors.crimson)),
                          ),
                        ],
                        const SizedBox(height: PulseSpace.x8),
                        Center(
                          child: Text(
                            'Demo OTP is 654321 · Phone hashed\nAntigravity redesign build',
                            textAlign: TextAlign.center,
                            style: PulseTheme.dataXs(color: PulseColors.mist),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool mono;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PulseTheme.label()),
        const SizedBox(height: PulseSpace.x2),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: mono ? PulseTheme.data(size: 14) : null,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RoleSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const roles = [
      ('citizen', 'CITIZEN'),
      ('responder', 'RESPONDER'),
      ('command', 'COMMAND'),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: PulseColors.hairline),
        borderRadius: BorderRadius.circular(PulseRadii.xl),
        color: PulseColors.ink900.withValues(alpha: 0.5),
      ),
      child: Row(
        children: roles.map((r) {
          final active = value == r.$1;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(r.$1),
              borderRadius: BorderRadius.circular(PulseRadii.xl),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: PulseSpace.x3),
                decoration: BoxDecoration(
                  color: active ? PulseColors.signal.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(PulseRadii.xl),
                  border: Border.all(
                    color: active ? PulseColors.signal : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    r.$2,
                    style: PulseTheme.label(color: active ? PulseColors.signal : PulseColors.mist)
                        .copyWith(fontSize: 11),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
