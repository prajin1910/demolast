import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _batchController = TextEditingController();
  final _companyController = TextEditingController();
  
  String _selectedRole = 'student';
  String? _selectedDepartment;
  String? _selectedClass;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _departments = [
    'Computer Science Engineering',
    'Information Technology',
    'Electronics and Communication',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
  ];

  final List<String> _classes = ['I', 'II', 'III', 'IV'];
  final List<String> _years = ['2018', '2019', '2020', '2021', '2022', '2023', '2024'];
  final List<String> _batches = ['A', 'B', 'C'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _graduationYearController.dispose();
    _batchController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);

      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
        'department': _selectedDepartment,
        'role': _selectedRole,
      };

      if (_selectedRole != 'alumni') {
        userData['password'] = _passwordController.text;
        userData['className'] = _selectedClass;
      } else {
        userData['graduationYear'] = _graduationYearController.text;
        userData['batch'] = _batchController.text;
        userData['placedCompany'] = _companyController.text;
      }

      await authProvider.register(userData);
      
      if (_selectedRole == 'alumni') {
        toastProvider.showToast(
          'Alumni registration submitted successfully! Please wait for management approval.',
          ToastType.success,
        );
        context.go('/login');
      } else {
        toastProvider.showToast('Registration successful! Please verify your email.', ToastType.success);
        context.go('/verify-otp', extra: _emailController.text);
      }
    } catch (e) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast(e.toString().replaceFirst('Exception: ', ''), ToastType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F9FF),
              Color(0xFFFFFFFF),
              Color(0xFFF0F4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Title
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      LucideIcons.bookOpen,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Join the smart assessment platform',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Registration Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Role Selection
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(LucideIcons.user),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'student', child: Text('Student')),
                            DropdownMenuItem(value: 'professor', child: Text('Professor')),
                            DropdownMenuItem(value: 'alumni', child: Text('Alumni')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedRole = value!);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a role';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(LucideIcons.user),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: _selectedRole == 'alumni' 
                                ? 'Enter your email' 
                                : 'Enter your college email',
                            prefixIcon: const Icon(LucideIcons.mail),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (_selectedRole != 'alumni' && !value.endsWith('@stjosephstechnology.ac.in')) {
                              return 'Please use your college email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field (not for alumni)
                        if (_selectedRole != 'alumni') ...[
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Create a password (min 6 characters)',
                              prefixIcon: const Icon(LucideIcons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                            prefixIcon: Icon(LucideIcons.phone),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Department Field
                        DropdownButtonFormField<String>(
                          value: _selectedDepartment,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(LucideIcons.building),
                          ),
                          items: _departments.map((dept) => 
                            DropdownMenuItem(value: dept, child: Text(dept))
                          ).toList(),
                          onChanged: (value) {
                            setState(() => _selectedDepartment = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a department';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Class Field (for students only)
                        if (_selectedRole == 'student') ...[
                          DropdownButtonFormField<String>(
                            value: _selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              prefixIcon: Icon(LucideIcons.graduationCap),
                            ),
                            items: _classes.map((cls) => 
                              DropdownMenuItem(value: cls, child: Text('Class $cls'))
                            ).toList(),
                            onChanged: (value) {
                              setState(() => _selectedClass = value);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a class';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Alumni specific fields
                        if (_selectedRole == 'alumni') ...[
                          DropdownButtonFormField<String>(
                            value: _graduationYearController.text.isEmpty ? null : _graduationYearController.text,
                            decoration: const InputDecoration(
                              labelText: 'Graduation Year',
                              prefixIcon: Icon(LucideIcons.calendar),
                            ),
                            items: _years.map((year) => 
                              DropdownMenuItem(value: year, child: Text(year))
                            ).toList(),
                            onChanged: (value) {
                              _graduationYearController.text = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select graduation year';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _batchController.text.isEmpty ? null : _batchController.text,
                            decoration: const InputDecoration(
                              labelText: 'Batch',
                              prefixIcon: Icon(LucideIcons.users),
                            ),
                            items: _batches.map((batch) => 
                              DropdownMenuItem(value: batch, child: Text('Batch $batch'))
                            ).toList(),
                            onChanged: (value) {
                              _batchController.text = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select batch';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Current Company',
                              hintText: 'Enter your current company name',
                              prefixIcon: Icon(LucideIcons.building),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your current company';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 16),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Create Account'),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text(
                                'Sign in',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}