import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import './main.dart'; // Ensure this points to main.dart or home screen file

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';

  void _showRegistrationForm() {
    // Controllers for form fields
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController interestController = TextEditingController();

    // Track user interests
    List<String> userInterests = [];

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Register New Account'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add your interests:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: interestController,
                              decoration: InputDecoration(
                                hintText: 'Enter an interest',
                                isDense: true,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              if (interestController.text.trim().isNotEmpty) {
                                setState(() {
                                  userInterests.add(interestController.text.trim());
                                  interestController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (userInterests.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Your interests:',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: userInterests.map((interest) {
                            return Chip(
                              label: Text(interest),
                              deleteIcon: Icon(Icons.clear, size: 16),
                              onDeleted: () {
                                setState(() {
                                  userInterests.remove(interest);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: 8),
                      if (userInterests.isEmpty)
                        Text(
                          'Please add at least one interest',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate interests
                    if (userInterests.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add at least one interest')),
                      );
                      return;
                    }

                    // Validate form
                    if (formKey.currentState!.validate()) {
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(child: CircularProgressIndicator());
                          },
                        );

                        // Create user with email and password
                        final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                        );

                        // Store additional user data in Firestore
                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(userCredential.user!.uid)
                            .set({
                          'Name': nameController.text.trim(),
                          'email_Id': emailController.text.trim(),
                          'Password': passwordController.text, // Note: Storing passwords in plaintext is not recommended
                          'Interests': userInterests,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        // Hide loading indicator and dialog
                        Navigator.pop(context); // Pop loading dialog
                        Navigator.pop(context); // Pop registration dialog

                        // Navigate to LoginPage

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('user_email', _emailController as String);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage(emailId: _emailController.text.trim())) // Change LoginPage() if needed
                        );

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registration successful!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        // Hide loading indicator
                        Navigator.pop(context);

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.code == 'email-already-in-use'
                                  ? 'The email address is already in use.'
                                  : e.code == 'weak-password'
                                  ? 'The password is too weak.'
                                  : 'An error occurred: ${e.message}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        // Hide loading indicator
                        Navigator.pop(context);

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('An error occurred: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Register'),
                ),

              ],
            );
          },
        );
      },
    );
  }

  Future<void> _launchIRCTCWebsite() async {
    final Uri irctcUrl = Uri.parse('https://www.irctc.co.in/');
    try {
      bool launched = await launchUrl(
        irctcUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showSnackBar('Could not launch IRCTC website');
      }
    } catch (e) {
      print('Error launching URL: $e');
      _showSnackBar('An error occurred while launching website');
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _emailController.text.trim());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(emailId: _emailController.text.trim())),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Wrong password provided for that user.';
        } else {
          _errorMessage = e.message ?? 'An error occurred';
        }
      });
      _showSnackBar(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/peoples.jpg', // Ensure this exists in assets
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Welcome to\nTrain Social',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showSnackBar('Forgot Password Clicked');
                                },
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: _launchIRCTCWebsite,
                                child: const Text('Train Booking (IRCTC)'),
                              ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  _showRegistrationForm();
                                },
                                child: const Text('New user? Register here'),
                              ),
                            ),
                          ],
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
    );
  }
}
