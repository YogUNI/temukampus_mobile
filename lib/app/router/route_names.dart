/// Konstanta nama dan path rute navigasi TemuKampus Mobile.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  static const String home = '/home';
  static const String explore = '/explore';
  static const String eventDetail = '/events/:slug';
  static const String eventRegister = '/events/:slug/register';
  static String eventDetailPath(String slug) => '/events/$slug';
  static String eventRegisterPath(String slug) => '/events/$slug/register';

  static const String myTickets = '/my-tickets';
  static const String ticketDetail = '/tickets/:code';
  static String ticketDetailPath(String code) => '/tickets/$code';

  static const String scanner = '/scanner';
  static const String scannerSelectEvent = '/scanner/select-event';
  static const String scannerGate = '/scanner/:eventId';
  static String scannerGatePath(int eventId) => '/scanner/$eventId';

  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
}

