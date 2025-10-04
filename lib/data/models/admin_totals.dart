class AdminTotals {
  final int totalJobProviders;
  final int totalJobSeekers;
  final int totalVacancies;
  final int totalPendingRequests;

  AdminTotals({
    required this.totalJobProviders,
    required this.totalJobSeekers,
    required this.totalVacancies,
    required this.totalPendingRequests,
  });

  factory AdminTotals.fromJson(Map<String, dynamic> json) {
    return AdminTotals(
      totalJobProviders: json['total_job_providers'] ?? 0,
      totalJobSeekers: json['total_job_seekers'] ?? 0,
      totalVacancies: json['total_vacancies'] ?? 0,
      totalPendingRequests: json['total_pending_requests'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_job_providers': totalJobProviders,
      'total_job_seekers': totalJobSeekers,
      'total_vacancies': totalVacancies,
      'total_pending_requests': totalPendingRequests,
    };
  }
}