/// Endpoint REST API backend Laravel 13 (`temukampus`).
/// Sesuai spesifikasi resmi di docs/03-API-CONTRACT.md.
class ApiEndpoints {
  ApiEndpoints._();

  // === Autentikasi ===
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String verifyEmailCode = '/auth/verify-email-code';
  static const String resendEmailCode = '/auth/resend-email-code';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String updateProfile = '/profile';
  static const String changePassword = '/profile/password';

  // === Katalog Acara ===
  static const String events = '/events';
  static String eventDetail(String slug) => '/events/$slug';
  static String eventEligibility(String slug) => '/events/$slug/eligibility';
  static const String categories = '/categories';

  /// Direktori organisasi kampus (padanan halaman /organisasi di web).
  static const String organizations = '/organizations';
  static String organizationDetail(String slug) => '/organizations/$slug';

  // === Panel panitia ===
  static const String panitiaDashboard = '/panitia/dashboard';
  static String panitiaRegistrations(int eventId) =>
      '/panitia/events/$eventId/registrations';
  static String panitiaProof(int registrationId) =>
      '/panitia/registrations/$registrationId/proof';
  static String panitiaApprove(int id) => '/panitia/registrations/$id/approve';
  static String panitiaRevise(int id) => '/panitia/registrations/$id/revise';
  static String panitiaReject(int id) => '/panitia/registrations/$id/reject';
  static String panitiaCheckIn(int id) => '/panitia/registrations/$id/check-in';
  static String panitiaBulkApprove(int eventId) =>
      '/panitia/events/$eventId/registrations/bulk-approve';
  static String panitiaPublish(int eventId) => '/panitia/events/$eventId/publish';
  static String panitiaUnpublish(int eventId) => '/panitia/events/$eventId/unpublish';
  static String panitiaCancel(int eventId) => '/panitia/events/$eventId/cancel';

  // === Pendaftaran & Pembayaran ===
  static String registerEvent(String slug) => '/events/$slug/register';
  static String uploadProof(int registrationId) => '/registrations/$registrationId/proof';
  static String cancelRegistration(int registrationId) => '/registrations/$registrationId/cancel';

  // === Tiket Peserta ===
  static const String myTickets = '/tickets';
  static String ticketDetail(String code) => '/tickets/$code';
  static String ticketProofImage(String code) => '/tickets/$code/proof';

  // === Scanner Panitia (Organizer) ===
  static const String organizerEvents = '/organizer/events';
  static String scanTicket(int eventId) => '/organizer/events/$eventId/scan';
  static String manualCheckin(int eventId) => '/organizer/events/$eventId/manual-checkin';
  static String eventAttendance(int eventId) => '/organizer/events/$eventId/attendance';
}

