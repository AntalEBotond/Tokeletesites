import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class BejelentkezesPage extends StatefulWidget {
  const BejelentkezesPage({super.key});

  @override
  State<BejelentkezesPage> createState() => _BejelentkezesPageState();
}

class _BejelentkezesPageState extends State<BejelentkezesPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _remember = false;

  static const Color green = Color(0xFF00C853);
  static const Color dark = Color(0xFF0B1210);
  static const Color darkCard = Color(0xFF121A18);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te rugam sa completezi toate campurile.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ApiService();
      final (token, user) = await api.login(username: email, password: pass);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('auth_token', token);
      await sp.setString('auth_username', user['username']?.toString() ?? email);
      final uid = (user['id'] is int) ? user['id'] as int : int.tryParse(user['id']?.toString() ?? '');
      if (uid != null) {
        await sp.setInt('auth_user_id', uid);
      }
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushReplacementNamed('/menu');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autentificare esuata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      body: SafeArea(
        child: Stack(
          children: [
            // glow sus-dreapta
            Positioned(
              right: -120,
              top: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [green.withOpacity(0.22), Colors.transparent],
                    radius: 0.7,
                  ),
                ),
              ),
            ),
            // glow jos-stanga
            Positioned(
              left: -140,
              bottom: -120,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [green.withOpacity(0.14), Colors.transparent],
                    radius: 0.7,
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    color: darkCard,
                    elevation: 14,
                    shadowColor: green.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: green.withOpacity(0.18), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: green.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.vpn_key,
                                  color: green,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Autentificare',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Conecteaza-te la contul tau',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: green.withOpacity(0.12),
                              hintText: 'Nume de utilizator',
                              hintStyle:
                                  const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.10),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: green,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Parola
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: green.withOpacity(0.12),
                              hintText: 'Parola',
                              hintStyle:
                                  const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.10),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: green,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _remember = !_remember),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: _remember ? green : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.white54, width: 1.2),
                                      ),
                                      child: _remember
                                          ? const Icon(Icons.check,
                                              size: 14, color: Colors.black)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Tine-ma minte',
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Resetare parola...')),
                                  );
                                },
                                child: const Text(
                                  'Ai uitat parola?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Buton de conectare
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 8,
                                shadowColor: green.withOpacity(0.4),
                                textStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation(Colors.black),
                                      ),
                                    )
                                  : const Text('Conectare'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Acces alternativ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Autentificare cu amprenta (exemplu)'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.fingerprint,
                                    color: Colors.white70),
                                tooltip: 'Cu amprenta',
                                splashRadius: 22,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Alt mod de autentificare',
                                    style: TextStyle(color: Colors.white60)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
