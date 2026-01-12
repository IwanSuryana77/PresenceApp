import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const primaryBlue = Color(0xFF242484);

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(); // bisa jadi username/email
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _isLoginMode = true; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Tombol utama, login atau register
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isLoginMode) {
        // LOGIN EMAIL/PASSWORD (atau username sebagai email)
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil masuk!')),
        );
      } else {
        // REGISTER EMAIL/PASSWORD
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dibuat!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e));
    } catch (e) {
      _showError('Terjadi kesalahan. Coba lagi nanti.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'Pengguna tidak ditemukan. Daftar dulu?';
      case 'wrong-password': return 'Kata sandi salah.';
      case 'invalid-email': return 'Format email salah.';
      case 'email-already-in-use': return 'Email sudah digunakan.';
      case 'weak-password': return 'Kata sandi terlalu lemah.';
      default: return 'Auth error: ${e.code}';
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainFont = 'Georgia';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO/Judul di atas
              const SizedBox(height: 36),
              Text(
                _isLoginMode ? 'Log In Your\nAccount' : 'Register\nYour Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  fontFamily: mainFont,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isLoginMode
                  ? "Already Registered? Log in here."
                  : "Create your account below.",
                style: TextStyle(
                  color: primaryBlue.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontFamily: mainFont,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // USERNAME/EMAIL Title
                    Text(
                      "USERNAME",
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 17,
                        fontFamily: mainFont,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // USERNAME/EMAIL Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFF2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: primaryBlue,
                          fontFamily: mainFont,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          hintText: 'Masukkan email Anda',
                          hintStyle: TextStyle(
                            color: primaryBlue,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Email wajib diisi";
                          final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!pattern.hasMatch(v)) return "Format email tidak valid";
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // PASSWORD TITLE
                    Text(
                      "PASSWORD",
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 17,
                        fontFamily: mainFont,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // PASSWORD FIELD
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFF2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: TextStyle(
                          color: primaryBlue,
                          fontFamily: mainFont,
                          fontSize: 16,
                          letterSpacing: 2.0,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          hintText: '*****',
                          hintStyle: const TextStyle(
                            color: primaryBlue,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                            letterSpacing: 2.0,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Kata sandi wajib diisi";
                          if (v.length < 6) return "Minimal 6 karakter";
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 38),

                    // LOGIN/REGISTER BUTTON
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(_isLoginMode ? "Log in" : "Register"),
                      ),
                    ),
                  ],
                ),
              ),

              // SWITCH LOGIN/REGISTER
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode
                    ? "Belum punya akun? Register."
                    : "Sudah punya akun? Log in.",
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: mainFont,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ModernLoginScreen extends StatefulWidget {
//   const ModernLoginScreen({super.key});

//   @override
//   State<ModernLoginScreen> createState() => _ModernLoginScreenState();
// }

// class _ModernLoginScreenState extends State<ModernLoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscure = true;
//   bool _loading = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _signIn() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _loading = true);
//     try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//       );
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Berhasil masuk')),
//       );
//     } on FirebaseAuthException catch (e) {
//       _showError(_mapAuthError(e));
//     } catch (e) {
//       _showError('Terjadi kesalahan. Coba lagi.');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _register() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _loading = true);
//     try {
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//       );
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Akun berhasil dibuat dan masuk')),
//       );
//     } on FirebaseAuthException catch (e) {
//       _showError(_mapAuthError(e));
//     } catch (e) {
//       _showError('Terjadi kesalahan. Coba lagi.');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _signInAnonymously() async {
//     setState(() => _loading = true);
//     try {
//       await FirebaseAuth.instance.signInAnonymously();
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Masuk sebagai Tamu')),
//       );
//     } on FirebaseAuthException catch (e) {
//       _showError(_mapAuthError(e));
//     } catch (e) {
//       _showError('Terjadi kesalahan. Coba lagi.');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   String _mapAuthError(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'user-not-found':
//         return 'Pengguna tidak ditemukan. Daftar terlebih dahulu.';
//       case 'wrong-password':
//         return 'Kata sandi salah.';
//       case 'invalid-email':
//         return 'Format email tidak valid.';
//       case 'email-already-in-use':
//         return 'Email sudah digunakan.';
//       case 'weak-password':
//         return 'Kata sandi terlalu lemah.';
//       case 'operation-not-allowed':
//         return 'Operasi tidak diizinkan di project Firebase.';
//       default:
//         return 'Auth error: ${e.code}';
//     }
//   }

//   void _showError(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background gradient
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           // Subtle circles
//           Positioned(
//             top: -60,
//             right: -40,
//             child: _bubble(160, Colors.white.withOpacity(0.08)),
//           ),
//           Positioned(
//             bottom: -80,
//             left: -30,
//             child: _bubble(220, Colors.white.withOpacity(0.06)),
//           ),

//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 420),
//                 child: Card(
//                   elevation: 12,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(24.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF3B82F6).withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                               child: const Icon(Icons.lock_outline, size: 28, color: Color(0xFF1E3A8A)),
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               'Masuk Akun',
//                               style: theme.textTheme.headlineSmall?.copyWith(
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),
//                         Form(
//                           key: _formKey,
//                           child: Column(
//                             children: [
//                               TextFormField(
//                                 controller: _emailController,
//                                 decoration: InputDecoration(
//                                   labelText: 'Email',
//                                   prefixIcon: const Icon(Icons.email_outlined),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                 ),
//                                 keyboardType: TextInputType.emailAddress,
//                                 validator: (v) {
//                                   if ((v ?? '').trim().isEmpty) return 'Email wajib diisi';
//                                   final email = v!.trim();
//                                   final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
//                                   if (!regex.hasMatch(email)) return 'Format email tidak valid';
//                                   return null;
//                                 },
//                               ),
//                               const SizedBox(height: 16),
//                               TextFormField(
//                                 controller: _passwordController,
//                                 decoration: InputDecoration(
//                                   labelText: 'Kata Sandi',
//                                   prefixIcon: const Icon(Icons.lock_outline),
//                                   suffixIcon: IconButton(
//                                     onPressed: () => setState(() => _obscure = !_obscure),
//                                     icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                 ),
//                                 obscureText: _obscure,
//                                 validator: (v) {
//                                   if ((v ?? '').isEmpty) return 'Kata sandi wajib diisi';
//                                   if ((v ?? '').length < 6) return 'Minimal 6 karakter';
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         _loading
//                             ? const Center(child: CircularProgressIndicator())
//                             : Column(
//                                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                                 children: [
//                                   SizedBox(
//                                     height: 48,
//                                     child: ElevatedButton(
//                                       onPressed: _signIn,
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: const Color(0xFF1E3A8A),
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(12),
//                                         ),
//                                       ),
//                                       child: const Text('Masuk'),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 12),
//                                   SizedBox(
//                                     height: 48,
//                                     child: OutlinedButton(
//                                       onPressed: _register,
//                                       style: OutlinedButton.styleFrom(
//                                         side: const BorderSide(color: Color(0xFF1E3A8A)),
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(12),
//                                         ),
//                                       ),
//                                       child: const Text('Daftar Akun Baru'),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 12),
//                                   TextButton(
//                                     onPressed: _signInAnonymously,
//                                     child: const Text('Masuk sebagai Tamu'),
//                                   ),
//                                 ],
//                               ),
//                         const SizedBox(height: 8),
//                         const Divider(height: 24),
//                         Text(
//                           'Dengan masuk, Anda menyetujui kebijakan privasi dan ketentuan penggunaan.',
//                           textAlign: TextAlign.center,
//                           style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _bubble(double size, Color color) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: color,
//       ),
//     );
//   }
// }
