import 'package:get/get.dart';
import 'package:stackle_admin/controllers/auth_gate.dart';
import 'package:stackle_admin/view/auth/forgot_password_screen.dart';
import 'package:stackle_admin/view/auth/login_screen.dart';
import 'package:stackle_admin/view/main_dashboard.dart';
import 'package:stackle_admin/view/manageHR/hr_details_screen.dart';
import 'package:stackle_admin/view/manageHR/hr_job_details.dart';
import 'package:stackle_admin/data/models/organization.dart';
import 'package:stackle_admin/data/models/job.dart' as job_model;
import 'package:stackle_admin/view/settings/notification_screen.dart';

class AppRoutes {
  static const String authGate = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String hr = '/dashboard/hr';
  static const String professionals = '/dashboard/professionals';
  static const String accounts = '/dashboard/accounts';
  static const String blocked = '/dashboard/blocked';
  static const String settings = '/dashboard/settings';
  static const String hrDetails = '/dashboard/hr/details';
  static const String hrJobDetails = '/dashboard/hr/job-details';
  static const String notificationScreen = '/notifications';


  static List<GetPage> getPages = [
    GetPage(name: authGate, page: () => const AuthGate()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: dashboard, page: () => const MainDashboard(initialIndex: 0)),
    GetPage(name: hr, page: () => const MainDashboard(initialIndex: 1)),
    GetPage(name: professionals, page: () => const MainDashboard(initialIndex: 2)),
    GetPage(name: accounts, page: () => const MainDashboard(initialIndex: 3)),
    GetPage(name: blocked, page: () => const MainDashboard(initialIndex: 4)),
    GetPage(name: settings, page: () => const MainDashboard(initialIndex: 5)),
    GetPage(name: notificationScreen, page: () => const NotificationScreen()),
    GetPage(name: hrDetails, page: () => HrDetailsScreen(organization: Get.arguments as Organization)),
    GetPage(name: hrJobDetails, page: () {
      final args = Get.arguments as Map<String, dynamic>;
      return HRJobDetailScreen(job: args['job'] as job_model.Job, organizationName: args['organizationName'] as String);
    }),
  ];
}