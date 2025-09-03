import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class AlumniDirectoryWidget extends StatefulWidget {
  final bool excludeCurrentUser;

  const AlumniDirectoryWidget({
    super.key,
    this.excludeCurrentUser = false,
  });

  @override
  State<AlumniDirectoryWidget> createState() => _AlumniDirectoryWidgetState();
}

class _AlumniDirectoryWidgetState extends State<AlumniDirectoryWidget> {
  List<Map<String, dynamic>> _alumni = [];
  List<Map<String, dynamic>> _filteredAlumni = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDepartment;
  String? _selectedYear;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAlumni();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlumni() async {
    try {
      List<dynamic> response;
      
      if (widget.excludeCurrentUser) {
        response = await ApiService.getAllVerifiedAlumniForAlumni();
      } else {
        response = await ApiService.getAllVerifiedAlumni();
      }
      
      setState(() {
        _alumni = response.cast<Map<String, dynamic>>();
        _filteredAlumni = _alumni;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to load alumni directory', ToastType.error);
    }
  }

  void _filterAlumni() {
    setState(() {
      _filteredAlumni = _alumni.where((alumni) {
        final matchesSearch = _searchQuery.isEmpty ||
            alumni['name']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            alumni['email']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            alumni['department']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            alumni['currentCompany']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

        final matchesDepartment = _selectedDepartment == null ||
            alumni['department'] == _selectedDepartment;

        final matchesYear = _selectedYear == null ||
            alumni['graduationYear']?.toString() == _selectedYear;

        return matchesSearch && matchesDepartment && matchesYear;
      }).toList();
    });
  }

  Future<void> _sendConnectionRequest(String alumniId, String alumniName) async {
    try {
      await ApiService.sendConnectionRequest(
        alumniId,
        'Hi $alumniName, I would like to connect with you for mentoring and career guidance. Thank you!',
      );
      
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Connection request sent to $alumniName!', ToastType.success);
    } catch (e) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to send connection request', ToastType.error);
    }
  }

  void _showAlumniProfile(Map<String, dynamic> alumni) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAlumniProfileModal(alumni),
    );
  }

  Widget _buildAlumniProfileModal(Map<String, dynamic> alumni) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accentColor,
                  child: Text(
                    alumni['name']?.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumni['name'] ?? 'Alumni',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        alumni['currentCompany'] ?? 'Company not specified',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (alumni['isAvailableForMentorship'] == true)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Available for Mentorship',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Information
                  _buildProfileSection('Contact Information', [
                    _buildProfileRow(LucideIcons.mail, 'Email', alumni['email'] ?? ''),
                    if (alumni['phoneNumber'] != null)
                      _buildProfileRow(LucideIcons.phone, 'Phone', alumni['phoneNumber']),
                    if (alumni['location'] != null)
                      _buildProfileRow(LucideIcons.mapPin, 'Location', alumni['location']),
                  ]),
                  const SizedBox(height: 24),

                  // Academic Background
                  _buildProfileSection('Academic Background', [
                    _buildProfileRow(LucideIcons.building, 'Department', alumni['department'] ?? ''),
                    _buildProfileRow(LucideIcons.calendar, 'Graduation Year', alumni['graduationYear']?.toString() ?? 'Unknown'),
                    if (alumni['batch'] != null)
                      _buildProfileRow(LucideIcons.users, 'Batch', alumni['batch']),
                  ]),
                  const SizedBox(height: 24),

                  // Professional Information
                  if (alumni['currentCompany'] != null || alumni['currentPosition'] != null) ...[
                    _buildProfileSection('Professional Information', [
                      if (alumni['currentPosition'] != null)
                        _buildProfileRow(LucideIcons.briefcase, 'Position', alumni['currentPosition']),
                      if (alumni['currentCompany'] != null)
                        _buildProfileRow(LucideIcons.building, 'Company', alumni['currentCompany']),
                      if (alumni['workExperience'] != null)
                        _buildProfileRow(LucideIcons.award, 'Experience', '${alumni['workExperience']} years'),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  // Skills
                  if (alumni['skills'] != null && (alumni['skills'] as List).isNotEmpty) ...[
                    Text(
                      'Skills & Expertise',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (alumni['skills'] as List).map((skill) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skill.toString(),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Achievements
                  if (alumni['achievements'] != null && (alumni['achievements'] as List).isNotEmpty) ...[
                    Text(
                      'Achievements',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(alumni['achievements'] as List).map((achievement) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.star, size: 16, color: AppTheme.warningColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              achievement.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sendConnectionRequest(alumni['id'], alumni['name']);
                    },
                    icon: const Icon(LucideIcons.userPlus),
                    label: const Text('Request Mentoring'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Launch email
                    },
                    icon: const Icon(LucideIcons.mail),
                    label: const Text('Send Email'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniCard(Map<String, dynamic> alumni) {
    final isAvailableForMentorship = alumni['isAvailableForMentorship'] == true ||
        alumni['mentorshipAvailable'] == true ||
        alumni['availableForMentorship'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showAlumniProfile(alumni),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.accentColor,
                    child: Text(
                      alumni['name']?.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alumni['name'] ?? 'Alumni',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          alumni['currentCompany'] ?? alumni['placedCompany'] ?? 'Company not specified',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAvailableForMentorship)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        LucideIcons.userCheck,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  const Icon(LucideIcons.building, size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    alumni['department'] ?? 'Department',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.calendar, size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    "Class of ${alumni['graduationYear']?.toString() ?? 'N/A'}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              if (alumni['location'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      alumni['location'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Mentorship Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAvailableForMentorship 
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAvailableForMentorship 
                        ? AppTheme.successColor.withOpacity(0.3)
                        : AppTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAvailableForMentorship ? LucideIcons.userCheck : LucideIcons.x,
                      size: 16,
                      color: isAvailableForMentorship ? AppTheme.successColor : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAvailableForMentorship ? 'Mentoring Available' : 'Not Mentoring',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isAvailableForMentorship ? AppTheme.successColor : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isAvailableForMentorship) ...[
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAlumniProfile(alumni),
                      icon: const Icon(LucideIcons.user, size: 16),
                      label: const Text('Profile'),
                    ),
                  ),
                  if (isAvailableForMentorship) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _sendConnectionRequest(alumni['id'], alumni['name']);
                        },
                        icon: const Icon(LucideIcons.messageCircle, size: 16),
                        label: const Text('Mentoring'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getDepartments() {
    return _alumni
        .map((alumni) => alumni['department']?.toString())
        .where((dept) => dept != null)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _getGraduationYears() {
    return _alumni
        .map((alumni) => alumni['graduationYear']?.toString())
        .where((year) => year != null)
        .cast<String>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Row(
          children: [
            const Icon(LucideIcons.users, color: AppTheme.accentColor),
            const SizedBox(width: 8),
            Text(
              'Alumni Directory',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with ${_alumni.length} verified alumni from our institution',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Search and Filters
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Alumni',
                    hintText: 'Search by name, department, or company...',
                    prefixIcon: Icon(LucideIcons.search),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _filterAlumni();
                  },
                ),
                const SizedBox(height: 16),

                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Departments')),
                          ..._getDepartments().map((dept) => 
                            DropdownMenuItem(value: dept, child: Text(dept))
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDepartment = value);
                          _filterAlumni();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Graduation Year',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Years')),
                          ..._getGraduationYears().map((year) => 
                            DropdownMenuItem(value: year, child: Text(year))
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedYear = value);
                          _filterAlumni();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Results Count
                Text(
                  'Showing ${_filteredAlumni.length} of ${_alumni.length} alumni',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Alumni List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredAlumni.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.users,
                            size: 64,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Alumni Found',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search criteria.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredAlumni.length,
                      itemBuilder: (context, index) => _buildAlumniCard(_filteredAlumni[index]),
                    ),
        ),
      ],
    );
  }
}