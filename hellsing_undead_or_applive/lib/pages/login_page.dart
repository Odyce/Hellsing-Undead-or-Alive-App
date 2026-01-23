import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _showLogingForm = false;
  bool _isRegisterMode = false;
  bool _rememberMe = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;

  String? _error;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pseudoController = TextEditingController();

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _signIn() async {
    _safeSetState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
          throw Exception("Accréditation et code secret requis.");
      }

      // Persistance "Remember me"
      if (kIsWeb) {
          await FirebaseAuth.instance.setPersistence(
          _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      }

      // Connexion
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
      ); // :contentReference[oaicite:5]{index=5}
    
      // Côté mobile: on stocke juste le choix "remember"
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      await prefs.setString('remembered_email', email);
  
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "Il semblerait que ton compte n'existe pas.";
      case 'wrong-password':
        return "Code secret incorrect.";
      case 'invalid-email':
        return "Email invalide.";
      case 'user-disabled':
        return "Ce compte est désactivé, envoie un message aux admins.";
      default:
        return "Connexion impossible (${e.code}).";
    }
  }

  Future<void> _signUp() async {
    _safeSetState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirm = _confirmPasswordController.text;
      final pseudo = _pseudoController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception("Accréditation et code secret requis.");
      }
      if (password != confirm) {
        throw Exception("Les codes secrets ne correspondent pas.");
      }
      if (pseudo.isEmpty) {
        throw Exception("Pseudo requis.");
      }

      // Web: persistance avant auth
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(
          _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      }

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = cred.user!.uid; // ✅ ici, l'utilisateur existe

      await cred.user!.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'pseudo': pseudo,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      await prefs.setString('remembered_email', email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Compte créé. Bienvenue, vérifie tes emails s'il te plaît.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlySignUpError(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _friendlySignUpError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Il semblerait que cet email soit déjà utilisé.";
      case 'invalid-email':
        return "Email invalide.";
      case 'operation-not-allowed':
        return "Si tu vois cet erreur, c'est pas normal, contact un admin, code KEBAB.";
      case 'weak-password':
        return "Ton code secret est pas assez secret.";
      default:
        return "Création impossible (${e.code}).";
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            //Breakpoint simple
            final isDesktop = width >= 900;

            final contentMaxWidth = isDesktop ? 520.0 : double.infinity;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Card(
                    elevation: isDesktop ? 6 : 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Service secrets de Sa Majesté",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16,),

                            if (!_showLogingForm) ...[
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showLogingForm = true;
                                    _isRegisterMode = false;
                                    _confirmPasswordController.clear();
                                    _passwordController.clear();
                                    _emailController.clear();
                                  });
                                },
                                child: const Text("Se Connecter"),
                              ),
                              const SizedBox(height: 12,),
                              OutlinedButton(
                                onPressed:() {
                                  setState(() {
                                    _showLogingForm = true;
                                    _isRegisterMode = true;
                                    _confirmPasswordController.clear();
                                    _passwordController.clear();
                                    _emailController.clear();
                                  });
                                }, 
                                child: const Text("Créer un Compte"),
                              ),
                            ] else...[
                              // Formulaire
                              if (_isRegisterMode) ...[
                                TextField(
                                  controller: _pseudoController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Pseudo :',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: "Accréditation (mail) :",
                                  hintText: "ex: abel@hellsing.uk",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12,),

                              TextField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: "Code secret :",
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    tooltip: _hidePassword ? 'Afficher' : 'Masquer',
                                    onPressed: () {
                                      setState(() {
                                        _hidePassword = !_hidePassword;
                                      });
                                    }, 
                                    icon: Icon(
                                      _hidePassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12,),

                              if (_isRegisterMode) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _hideConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: "Veux-tu bien réécrire ton code secret ?",
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      tooltip: _hideConfirmPassword ? 'Afficher' : 'Masquer',
                                      onPressed: () {
                                        setState(() => _hideConfirmPassword = !_hideConfirmPassword);
                                      },
                                      icon: Icon(
                                        _hideConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe, 
                                    onChanged: (v) {
                                      setState(() => _rememberMe = v ?? false);
                                    },
                                  ),
                                  const Expanded(
                                    child: Text("T'as pas intérêt à m'oublier..."),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8,),

                              if (_error != null) ...[
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                              ],

                              ElevatedButton(
                                onPressed: _loading ? null : (_isRegisterMode ? _signUp :  _signIn),
                                child: _loading
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ) 
                                  : Text(_isRegisterMode ? "Embauchez-moi." : "Laisse-moi entrer."),
                              ),
                              const SizedBox(height: 12,),

                              TextButton(
                                onPressed: () {
                                  setState(() { 
                                    _isRegisterMode = !_isRegisterMode;
                                    _confirmPasswordController.clear();
                                    _passwordController.clear();
                                    _emailController.clear();
                                  },);
                                },
                                child: Text(
                                  _isRegisterMode
                                      ? "Je suis déjà embauché"
                                      : "Je dois me faire embaucher",
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  setState(() => _showLogingForm = false);
                                }, 
                                child: const Text("Une autre fois"),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  )
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
