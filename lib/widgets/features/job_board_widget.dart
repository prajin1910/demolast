import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../models/job.dart';

class JobBoardWidget extends StatefulWidget {
  const JobBoardWidget({super.key});

  @override
  State<JobBoardWidget> createState() => _JobBoardWidgetState();
}

class _JobBoardWidgetState extends State<JobBoardWidget> {
  List<Job> _jobs = [];
  bool _isLoading = true;
  bool _showCreateForm = false;
  Job? _editingJob;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _applicationUrlController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  JobType _selectedJobType = JobType.FULL_TIME;
  String _selectedWorkMode = 'On-site';
  String _selectedCurrency = 'INR';
  String _selectedExperienceLevel = 'Mid';

  List<String> _requirements = [''];
  List<String> _responsibilities = [''];
  List<String> _benefits = [''];
  List<String> _skills = [''];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _descriptionController.dispose();
    _applicationUrlController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final response = await ApiService.getAllJobs();
      setState(() {
        _jobs = response.map((json) => Job.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to load jobs', ToastType.error);
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final jobData = {
        'title': _titleController.text,
        'company': _companyController.text,
        'location': _locationController.text,
        'workMode': _selectedWorkMode,
        'type': _selectedJobType.name.toUpperCase(),
        'salaryMin': _salaryMinController.text,
        'salaryMax': _salaryMaxController.text,
        'currency': _selectedCurrency,
        'description': _descriptionController.text,
        'requirements': _requirements.where((r) => r.trim().isNotEmpty).toList(),
        'responsibilities': _responsibilities.where((r) => r.trim().isNotEmpty).toList(),
        'benefits': _benefits.where((b) => b.trim().isNotEmpty).toList(),
        'skillsRequired': _skills.where((s) => s.trim().isNotEmpty).toList(),
        'experienceLevel': _selectedExperienceLevel,
        'applicationUrl': _applicationUrlController.text,
        'contactEmail': _contactEmailController.text,
        'contactPhone': _contactPhoneController.text,
      };

      if (_editingJob != null) {
        await ApiService.updateJob(_editingJob!.id, jobData);
      } else {
        await ApiService.createJob(jobData);
      }

      await _loadJobs();
      _resetForm();
      setState(() => _showCreateForm = false);

      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast(
        _editingJob != null ? 'Job updated successfully!' : 'Job posted successfully!',
        ToastType.success,
      );
    } catch (e) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to save job', ToastType.error);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _companyController.clear();
    _locationController.clear();
    _salaryMinController.clear();
    _salaryMaxController.clear();
    _descriptionController.clear();
    _applicationUrlController.clear();
    _contactEmailController.clear();
    _contactPhoneController.clear();
    
    setState(() {
      _selectedJobType = JobType.FULL_TIME;
      _selectedWorkMode = 'On-site';
      _selectedCurrency = 'INR';
      _selectedExperienceLevel = 'Mid';
      _requirements = [''];
      _responsibilities = [''];
      _benefits = [''];
      _skills = [''];
      _editingJob = null;
    });
  }

  void _editJob(Job job) {
    setState(() {
      _editingJob = job;
      _titleController.text = job.title;
      _companyController.text = job.company;
      _locationController.text = job.location;
      _salaryMinController.text = job.salaryMin ?? '';
      _salaryMaxController.text = job.salaryMax ?? '';
      _descriptionController.text = job.description;
      _applicationUrlController.text = job.applicationUrl ?? '';
      _contactEmailController.text = job.contactEmail ?? '';
      _contactPhoneController.text = job.contactPhone ?? '';
      _selectedJobType = job.type;
      _selectedWorkMode = job.workMode ?? 'On-site';
      _selectedCurrency = job.currency ?? 'INR';
      _selectedExperienceLevel = job.experienceLevel ?? 'Mid';
      _requirements = job.requirements.isNotEmpty ? job.requirements : [''];
      _responsibilities = job.responsibilities?.isNotEmpty == true ? job.responsibilities! : [''];
      _benefits = job.benefits?.isNotEmpty == true ? job.benefits! : [''];
      _skills = job.skillsRequired?.isNotEmpty == true ? job.skillsRequired! : [''];
      _showCreateForm = true;
    });
  }

  Future<void> _deleteJob(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job posting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteJob(jobId);
        await _loadJobs();
        
        final toastProvider = Provider.of<ToastProvider>(context, listen: false);
        toastProvider.showToast('Job deleted successfully', ToastType.success);
      } catch (e) {
        final toastProvider = Provider.of<ToastProvider>(context, listen: false);
        toastProvider.showToast('Failed to delete job', ToastType.error);
      }
    }
  }

  Future<void> _applyToJob(Job job) async {
    final Uri uri;
    
    if (job.applicationUrl != null && job.applicationUrl!.isNotEmpty) {
      uri = Uri.parse(job.applicationUrl!);
    } else {
      final email = job.contactEmail ?? job.postedByEmail;
      final subject = Uri.encodeComponent('Application for ${job.title}');
      final body = Uri.encodeComponent(
        'Dear ${job.postedByName},\n\n'
        'I am interested in applying for the ${job.title} position at ${job.company}.\n\n'
        'Please find my resume attached.\n\n'
        'Thank you for your consideration.\n\n'
        'Best regards'
      );
      uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Could not open application link', ToastType.error);
    }
  }

  Widget _buildJobCard(Job job) {
    final user = Provider.of<AuthProvider>(context).user;
    final canEdit = user?.role == 'ALUMNI' && user?.id == job.postedBy;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getJobTypeColor(job.type),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              job.type.displayName,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (job.workMode != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.textSecondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                job.workMode!,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (canEdit) ...[
                  IconButton(
                    onPressed: () => _editJob(job),
                    icon: const Icon(LucideIcons.edit, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteJob(job.id),
                    icon: const Icon(LucideIcons.trash2, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Company & Location
            Row(
              children: [
                const Icon(LucideIcons.building, size: 16, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(job.company, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (job.companyWebsite != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(job.companyWebsite!)),
                    child: const Icon(LucideIcons.externalLink, size: 14, color: AppTheme.primaryColor),
                  ),
                ],
                const Spacer(),
                const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(job.location, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),

            // Salary & Experience
            if (job.salaryMin != null && job.salaryMax != null) ...[
              Row(
                children: [
                  const Icon(LucideIcons.dollarSign, size: 16, color: AppTheme.successColor),
                  const SizedBox(width: 4),
                  Text(
                    '${job.salaryMin}-${job.salaryMax} ${job.currency}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (job.experienceLevel != null) ...[
                    const Spacer(),
                    const Icon(LucideIcons.award, size: 16, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(job.experienceLevel!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Company Description
            if (job.companyDescription != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.companyDescription!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Job Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Requirements
            if (job.requirements.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirements:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...job.requirements.take(2).map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $req',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    )),
                    if (job.requirements.length > 2)
                      Text(
                        '+${job.requirements.length - 2} more',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Responsibilities
            if (job.responsibilities?.isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Responsibilities:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...job.responsibilities!.take(2).map((resp) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $resp',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                        ),
                      ),
                    )),
                    if (job.responsibilities!.length > 2)
                      Text(
                        '+${job.responsibilities!.length - 2} more',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Benefits
            if (job.benefits?.isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benefits:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...job.benefits!.take(2).map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $benefit',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    )),
                    if (job.benefits!.length > 2)
                      Text(
                        '+${job.benefits!.length - 2} more',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Skills
            if (job.skillsRequired?.isNotEmpty == true) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Skills: ',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ...job.skillsRequired!.take(6).map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      skill,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                  if (job.skillsRequired!.length > 6)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${job.skillsRequired!.length - 6}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Contact Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.contactEmail ?? job.postedByEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                  if (job.contactPhone != null)
                    Text(
                      job.contactPhone!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _applyToJob(job),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Apply Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getJobTypeColor(JobType type) {
    switch (type) {
      case JobType.FULL_TIME:
        return AppTheme.successColor;
      case JobType.PART_TIME:
        return AppTheme.warningColor;
      case JobType.INTERNSHIP:
        return AppTheme.primaryColor;
      case JobType.CONTRACT:
        return AppTheme.secondaryColor;
    }
  }

  Widget _buildCreateJobForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingJob != null ? 'Edit Job' : 'Post a New Job',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title *',
                  prefixIcon: Icon(LucideIcons.briefcase),
                ),
                validator: (value) => value?.isEmpty == true ? 'Please enter job title' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company *',
                        prefixIcon: Icon(LucideIcons.building),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Please enter company' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        prefixIcon: Icon(LucideIcons.mapPin),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Please enter location' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Job Type and Work Mode
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<JobType>(
                      value: _selectedJobType,
                      decoration: const InputDecoration(
                        labelText: 'Job Type',
                        prefixIcon: Icon(LucideIcons.clock),
                      ),
                      items: JobType.values.map((type) => 
                        DropdownMenuItem(value: type, child: Text(type.displayName))
                      ).toList(),
                      onChanged: (value) => setState(() => _selectedJobType = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedWorkMode,
                      decoration: const InputDecoration(
                        labelText: 'Work Mode',
                        prefixIcon: Icon(LucideIcons.home),
                      ),
                      items: ['On-site', 'Remote', 'Hybrid'].map((mode) => 
                        DropdownMenuItem(value: mode, child: Text(mode))
                      ).toList(),
                      onChanged: (value) => setState(() => _selectedWorkMode = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Salary Range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMinController,
                      decoration: const InputDecoration(
                        labelText: 'Min Salary',
                        prefixIcon: Icon(LucideIcons.dollarSign),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Max Salary',
                        prefixIcon: Icon(LucideIcons.dollarSign),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                      ),
                      items: ['INR', 'USD', 'EUR'].map((currency) => 
                        DropdownMenuItem(value: currency, child: Text(currency))
                      ).toList(),
                      onChanged: (value) => setState(() => _selectedCurrency = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description *',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
                maxLines: 4,
                validator: (value) => value?.isEmpty == true ? 'Please enter job description' : null,
              ),
              const SizedBox(height: 16),

              // Contact Information
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email *',
                        prefixIcon: Icon(LucideIcons.mail),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value?.isEmpty == true ? 'Please enter contact email' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        prefixIcon: Icon(LucideIcons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Application URL
              TextFormField(
                controller: _applicationUrlController,
                decoration: const InputDecoration(
                  labelText: 'Application URL',
                  prefixIcon: Icon(LucideIcons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _resetForm();
                        setState(() => _showCreateForm = false);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitJob,
                      child: Text(_editingJob != null ? 'Update Job' : 'Post Job'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Column(
      children: [
        // Header
        Row(
          children: [
            const Icon(LucideIcons.briefcase, color: AppTheme.accentColor),
            const SizedBox(width: 8),
            Text(
              'Job Board',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (user?.role == 'ALUMNI')
              ElevatedButton.icon(
                onPressed: () => setState(() => _showCreateForm = !_showCreateForm),
                icon: Icon(_showCreateForm ? LucideIcons.x : LucideIcons.plus),
                label: Text(_showCreateForm ? 'Cancel' : 'Post Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showCreateForm ? AppTheme.errorColor : AppTheme.accentColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Create Job Form
        if (_showCreateForm) ...[
          _buildCreateJobForm(),
          const SizedBox(height: 16),
        ],

        // Jobs List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _jobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.briefcase,
                            size: 64,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Jobs Posted',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to share a job opportunity!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _jobs.length,
                      itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
                    ),
        ),
      ],
    );
  }
}