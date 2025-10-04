import 'dart:convert';

class JobTypeEntry {
  final String jobType;
  JobTypeEntry({required this.jobType});
  factory JobTypeEntry.fromJson(Map<String, dynamic> json) => JobTypeEntry(jobType: (json['job_type'] ?? '').toString());
  Map<String, dynamic> toJson() => { 'job_type': jobType };
}

class JobImageEntry {
  final String url;
  JobImageEntry({required this.url});
  factory JobImageEntry.fromJson(Map<String, dynamic> json) => JobImageEntry(url: (json['url'] ?? '').toString());
  Map<String, dynamic> toJson() => { 'url': url };
}

class JobSkillEntry {
  final String skill;
  JobSkillEntry({required this.skill});
  factory JobSkillEntry.fromJson(Map<String, dynamic> json) => JobSkillEntry(skill: (json['skill'] ?? '').toString());
  Map<String, dynamic> toJson() => { 'skill': skill };
}

class Job {
  final int? id;
  final int organisationId;
  final String title;
  final String description;
  final String qualification;
  final int? experienceYears;
  final String salary;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String phone;
  final String email;
  final bool isSubscribed;
  final List<JobTypeEntry> jobTypes;
  final List<JobImageEntry> jobImages;
  final List<JobSkillEntry> jobSkills;

  Job({
    this.id,
    required this.organisationId,
    required this.title,
    required this.description,
    required this.qualification,
    required this.experienceYears,
    required this.salary,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.phone,
    required this.email,
    required this.isSubscribed,
    required this.jobTypes,
    required this.jobImages,
    required this.jobSkills,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: () {
        final raw = json['id'] ?? json['job_id'];
        if (raw == null) return null;
        if (raw is int) return raw;
        return int.tryParse(raw.toString());
      }(),
      organisationId: json['organisation_id'] is int ? json['organisation_id'] : int.tryParse(json['organisation_id']?.toString() ?? '0') ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      qualification: (json['qualification'] ?? '').toString(),
      experienceYears: () {
        final v = json['experience_years'];
        if (v == null) return null;
        if (v is int) return v;
        return int.tryParse(v.toString());
      }(),
      salary: (json['salary'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      isSubscribed: json['is_subscribed'] == true || json['is_subscribed'] == 1 || json['is_subscribed'] == 'true',
      jobTypes: (json['job_types'] as List? ?? []).map((e) => JobTypeEntry.fromJson(e as Map<String, dynamic>)).toList(),
      jobImages: (json['job_images'] as List? ?? []).map((e) => JobImageEntry.fromJson(e as Map<String, dynamic>)).toList(),
      jobSkills: (json['job_skills'] as List? ?? []).map((e) => JobSkillEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'organisation_id': organisationId,
    'title': title,
    'description': description,
    'qualification': qualification,
    'experience_years': experienceYears,
    'salary': salary,
    'city': city,
    'state': state,
    'country': country,
    'pincode': pincode,
    'phone': phone,
    'email': email,
    'is_subscribed': isSubscribed,
    'job_types': jobTypes.map((e) => e.toJson()).toList(),
    'job_images': jobImages.map((e) => e.toJson()).toList(),
    'job_skills': jobSkills.map((e) => e.toJson()).toList(),
  };

  static List<Job> listFromJson(dynamic data) {
    if (data is List) {
      return data.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }
}
