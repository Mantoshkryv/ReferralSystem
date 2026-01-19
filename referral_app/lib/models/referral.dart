/// Summary of user's referral statistics
class ReferralSummary {
  final String? myReferralCode;
  final int totalReferrals;
  final int successfulReferrals;
  final String conversionRate;
  final bool hasUsedReferral;

  ReferralSummary({
    this.myReferralCode,
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.conversionRate,
    required this.hasUsedReferral,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    return ReferralSummary(
      myReferralCode: json['my_referral_code'],
      totalReferrals: json['total_referrals'] ?? 0,
      successfulReferrals: json['successful_referrals'] ?? 0,
      conversionRate: json['conversion_rate'] ?? '0%',
      hasUsedReferral: json['has_used_referral'] ?? false,
    );
  }

  /// Helper to check if user has generated a code
  bool get hasGeneratedCode => myReferralCode != null && myReferralCode!.isNotEmpty;
  
  /// Helper to calculate pending referrals
  int get pendingReferrals => totalReferrals - successfulReferrals;
}

/// Individual referral item with status
class ReferralItem {
  final String referralCode;
  final String? referredByUsername;  
  final String? usedByUsername;      
  final String? referralUsedAt;
  final String status;

  ReferralItem({
    required this.referralCode,
    this.referredByUsername,
    this.usedByUsername,
    this.referralUsedAt,
    required this.status,
  });

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    return ReferralItem(
      referralCode: json['referral_code'] ?? '',
      referredByUsername: json['referred_by_username'],     
      usedByUsername: json['used_by_username'],              
      referralUsedAt: json['referral_used_at'],
      status: json['status'] ?? 'PENDING',
    );
  }

  /// Helper to check if referral was successful
  bool get isSuccess => status == 'SUCCESS';
  
  /// Helper to check if referral is pending
  bool get isPending => status == 'PENDING';
  
  /// Helper to get display text for used status
  String get usedByDisplay {
    if (usedByUsername != null && usedByUsername!.isNotEmpty) {
      return 'Used by: $usedByUsername';
    }
    return 'Not used yet';
  }
  
  /// Helper to format date nicely
  String get formattedDate {
    if (referralUsedAt == null) return 'Waiting for use';
    try {
      final date = DateTime.parse(referralUsedAt!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return referralUsedAt ?? '';
    }
  }
}