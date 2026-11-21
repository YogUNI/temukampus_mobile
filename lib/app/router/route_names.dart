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

  // Panel panitia (padanan /panitia di web).
  static const String panitia = '/panitia';
  static const String panitiaRegistrants = '/panitia/acara/:eventId/peserta';
  static String panitiaRegistrantsPath(int eventId) =>
      '/panitia/acara/$eventId/peserta';
  static const String panitiaEventCreate = '/panitia/acara/baru';
  static const String panitiaEventEdit = '/panitia/acara/:eventId/edit';
  static String panitiaEventEditPath(int eventId) =>
      '/panitia/acara/$eventId/edit';
  static const String panitiaOrganization = '/panitia/organisasi';
  static const String panitiaMembers = '/panitia/organisasi/anggota';

  // Direktori organisasi kampus (padanan /organisasi di web).
  static const String organizations = '/organisasi';
  static const String organizationDetail = '/organisasi/:slug';
  static String organizationDetailPath(String slug) => '/organisasi/$slug';

  static const String myTickets = '/my-tickets';
  static const String ticketDetail = '/tickets/:code';
  static String ticketDetailPath(String code) => '/tickets/$code';

  static const String scanner = '/scanner';
  static const String scannerSelectEvent = '/scanner/select-event';
  static const String scannerGate = '/scanner/:eventId';
  static String scannerGatePath(int eventId) => '/scanner/$eventId';

  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
}

