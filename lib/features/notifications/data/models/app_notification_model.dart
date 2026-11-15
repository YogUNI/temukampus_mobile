/// Satu notifikasi in-app dari tabel `notifications` backend.
///
/// Bentuk JSON mengikuti `NotificationResource`: `title`, `message`,
/// `category`, `icon`, `action{label, route}`, `is_read`, `created_at`.
class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String category; // registration | event | organization | account
  final String icon;
  final String? actionLabel;
  final String? actionRoute;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.category = 'account',
    this.icon = 'bell',
    this.actionLabel,
    this.actionRoute,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final action = json['action'];

    return AppNotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notifikasi',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? 'account',
      icon: json['icon'] as String? ?? 'bell',
      actionLabel: action is Map<String, dynamic> ? action['label'] as String? : null,
      actionRoute: action is Map<String, dynamic> ? action['route'] as String? : null,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'category': category,
        'icon': icon,
        'action': actionLabel != null
            ? {'label': actionLabel, 'route': actionRoute}
            : null,
        'is_read': isRead,
        'created_at': createdAt?.toIso8601String(),
      };

  AppNotificationModel copyWith({bool? isRead}) => AppNotificationModel(
        id: id,
        title: title,
        message: message,
        category: category,
        icon: icon,
        actionLabel: actionLabel,
        actionRoute: actionRoute,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  /// Label waktu ringkas berbahasa Indonesia ("Baru saja", "3 jam lalu").
  String get relativeTime {
    final created = createdAt;
    if (created == null) return '';

    final diff = DateTime.now().difference(created);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '$weeks minggu lalu';

    return '${created.day}/${created.month}/${created.year}';
  }
}
