/// Model Pratinjau Pembayaran Manual dengan Kode Unik 3 Digit.
class PaymentPreviewModel {
  final int ticketPrice;
  final int uniqueCode;
  final int totalAmountDue;
  final String formattedTotal;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String? qrisUrl;

  const PaymentPreviewModel({
    required this.ticketPrice,
    required this.uniqueCode,
    required this.totalAmountDue,
    required this.formattedTotal,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.qrisUrl,
  });

  bool get hasBankInfo =>
      bankName != null && accountNumber != null && accountNumber!.isNotEmpty;
  bool get hasQris => qrisUrl != null && qrisUrl!.isNotEmpty;

  factory PaymentPreviewModel.fromJson(Map<String, dynamic> json) {
    return PaymentPreviewModel(
      ticketPrice: json['ticket_price'] as int? ?? 0,
      uniqueCode: json['unique_code'] as int? ?? 0,
      totalAmountDue: json['total_amount_due'] as int? ?? (json['ticket_price'] as int? ?? 0),
      formattedTotal: json['formatted_total'] as String? ?? 'Rp ${json['total_amount_due'] ?? 0}',
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      accountName: json['account_name'] as String?,
      qrisUrl: json['qris_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_price': ticketPrice,
      'unique_code': uniqueCode,
      'total_amount_due': totalAmountDue,
      'formatted_total': formattedTotal,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'qris_url': qrisUrl,
    };
  }
}

/// Model Hasil Pendaftaran Acara Sukses (`POST /events/{slug}/register`).
class RegistrationResultModel {
  final String ticketCode;
  final String status;
  final String statusLabel;
  final int amountDue;
  final DateTime registeredAt;

  const RegistrationResultModel({
    required this.ticketCode,
    required this.status,
    required this.statusLabel,
    required this.amountDue,
    required this.registeredAt,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isPendingVerification => status == 'pending_verification';

  factory RegistrationResultModel.fromJson(Map<String, dynamic> json) {
    return RegistrationResultModel(
      ticketCode: json['ticket_code'] as String? ?? 'TK-XXXXXX',
      status: json['status'] as String? ?? 'pending_verification',
      statusLabel: json['status_label'] as String? ?? 'Menunggu Verifikasi',
      amountDue: json['amount_due'] as int? ?? 0,
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_code': ticketCode,
      'status': status,
      'status_label': statusLabel,
      'amount_due': amountDue,
      'registered_at': registeredAt.toIso8601String(),
    };
  }
}
