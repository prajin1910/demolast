class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String? className;
  final String? phoneNumber;
  final bool verified;
  final String? profilePicture;
  final String? bio;
  final List<String>? skills;
  final String? location;
  final DateTime? lastActive;
  
  // Student specific
  final String? studentId;
  final String? course;
  final String? year;
  final String? semester;
  final double? cgpa;
  
  // Professor specific
  final String? employeeId;
  final String? designation;
  final int? experience;
  final List<String>? subjectsTeaching;
  final List<String>? researchInterests;
  final int? publications;
  final int? studentsSupervised;
  
  // Alumni specific
  final int? graduationYear;
  final String? currentCompany;
  final String? currentPosition;
  final int? workExperience;
  final List<String>? achievements;
  final bool? mentorshipAvailable;
  
  // Statistics
  final int? aiAssessmentCount;
  final int? connectionCount;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.className,
    this.phoneNumber,
    this.verified = false,
    this.profilePicture,
    this.bio,
    this.skills,
    this.location,
    this.lastActive,
    this.studentId,
    this.course,
    this.year,
    this.semester,
    this.cgpa,
    this.employeeId,
    this.designation,
    this.experience,
    this.subjectsTeaching,
    this.researchInterests,
    this.publications,
    this.studentsSupervised,
    this.graduationYear,
    this.currentCompany,
    this.currentPosition,
    this.workExperience,
    this.achievements,
    this.mentorshipAvailable,
    this.aiAssessmentCount,
    this.connectionCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      department: json['department'],
      className: json['className'],
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      verified: json['verified'] ?? false,
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      location: json['location'],
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
      studentId: json['studentId'],
      course: json['course'],
      year: json['year'],
      semester: json['semester'],
      cgpa: json['cgpa']?.toDouble(),
      employeeId: json['employeeId'],
      designation: json['designation'],
      experience: json['experience'],
      subjectsTeaching: json['subjectsTeaching'] != null ? List<String>.from(json['subjectsTeaching']) : null,
      researchInterests: json['researchInterests'] != null ? List<String>.from(json['researchInterests']) : null,
      publications: json['publications'],
      studentsSupervised: json['studentsSupervised'],
      graduationYear: json['graduationYear'],
      currentCompany: json['currentCompany'],
      currentPosition: json['currentPosition'],
      workExperience: json['workExperience'],
      achievements: json['achievements'] != null ? List<String>.from(json['achievements']) : null,
      mentorshipAvailable: json['mentorshipAvailable'],
      aiAssessmentCount: json['aiAssessmentCount'],
      connectionCount: json['connectionCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'className': className,
      'phoneNumber': phoneNumber,
      'verified': verified,
      'profilePicture': profilePicture,
      'bio': bio,
      'skills': skills,
      'location': location,
      'lastActive': lastActive?.toIso8601String(),
      'studentId': studentId,
      'course': course,
      'year': year,
      'semester': semester,
      'cgpa': cgpa,
      'employeeId': employeeId,
      'designation': designation,
      'experience': experience,
      'subjectsTeaching': subjectsTeaching,
      'researchInterests': researchInterests,
      'publications': publications,
      'studentsSupervised': studentsSupervised,
      'graduationYear': graduationYear,
      'currentCompany': currentCompany,
      'currentPosition': currentPosition,
      'workExperience': workExperience,
      'achievements': achievements,
      'mentorshipAvailable': mentorshipAvailable,
      'aiAssessmentCount': aiAssessmentCount,
      'connectionCount': connectionCount,
    };
  }
}