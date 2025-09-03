import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'activity_heatmap_widget.dart';

class StudentProfileWidget extends StatefulWidget {
  const StudentProfileWidget({super.key});

  @override
  State<StudentProfileWidget> createState() => _StudentProfileWidgetState();
}

class _StudentProfileWidgetState extends State<StudentProfileWidget> {
  Map<String, dynamic> _profile = {};
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getStudentProfile();
      setState(() {
        _profile = profile;
        _bioController.text = profile['bio'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _locationController.text = profile['location'] ?? '';
        _linkedinController.text = profile['linkedinUrl'] ?? '';
        _githubController.text = profile['githubUrl'] ?? '';
        _portfolioController.text = profile['portfolioUrl'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to load profile', ToastType.error);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final updateData = {
        'bio': _bioController.text,
        'phone': _phoneController.text,
        'location': _locationController.text,
        'linkedinUrl': _linkedinController.text,
        'githubUrl': _githubController.text,
        'portfolioUrl': _portfolioController.text,
      };

      await ApiService.updateStudentProfile(updateData);
      await _loadProfile();
      
      setState(() => _isEditing = false);
      
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Profile updated successfully!', ToastType.success);
    } catch (e) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to update profile', ToastType.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Picture and Basic Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          _profile['name']?.substring(0, 1).toUpperCase() ?? 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile['name'] ?? 'Student',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Student • Class ${_profile['className'] ?? 'N/A'}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(LucideIcons.building, size: 16, color: AppTheme.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  _profile['department'] ?? 'Department',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(LucideIcons.mail, size: 16, color: AppTheme.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  _profile['email'] ?? 'Email',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Edit Button
                      IconButton(
                        onPressed: () {
                          setState(() => _isEditing = !_isEditing);
                        },
                        icon: Icon(_isEditing ? LucideIcons.x : LucideIcons.edit),
                        style: IconButton.styleFrom(
                          backgroundColor: _isEditing ? AppTheme.errorColor : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    // Editable Fields
                    Column(
                      children: [
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            hintText: 'Tell us about yourself...',
                            prefixIcon: Icon(LucideIcons.user),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(LucideIcons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(LucideIcons.mapPin),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _linkedinController,
                          decoration: const InputDecoration(
                            labelText: 'LinkedIn URL',
                            prefixIcon: Icon(LucideIcons.linkedin),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _githubController,
                          decoration: const InputDecoration(
                            labelText: 'GitHub URL',
                            prefixIcon: Icon(LucideIcons.github),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _portfolioController,
                          decoration: const InputDecoration(
                            labelText: 'Portfolio URL',
                            prefixIcon: Icon(LucideIcons.globe),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 24),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Activity Heatmap
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Activity Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ActivityHeatmapWidget(
                      userId: _profile['id'],
                      userName: _profile['name'],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}