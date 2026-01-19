/// Summary of user's rewards
class RewardSummary {
  final int totalEarned;
  final int pending;
  final int credited;
  final String unit;

  RewardSummary({
    required this.totalEarned,
    required this.pending,
    required this.credited,
    required this.unit,
  });

  factory RewardSummary.fromJson(Map<String, dynamic> json) {
    return RewardSummary(
      totalEarned: json['total_earned'] ?? 0,
      pending: json['pending'] ?? 0,
      credited: json['credited'] ?? 0,
      unit: json['unit'] ?? 'POINTS',
    );
  }

  /// Helper to check if user has any rewards
  bool get hasRewards => totalEarned > 0;
  
  /// Helper to check if there are pending rewards
  bool get hasPending => pending > 0;
  
  /// Helper to get percentage of credited rewards
  double get creditedPercentage {
    if (totalEarned == 0) return 0;
    return (credited / totalEarned) * 100;
  }
}

/// Individual reward transaction item
class RewardItem {
  final int id;
  final String? username;           // ✅ ADDED - User who received reward
  final String? referrerUsername;   // ✅ ADDED - Person who referred them
  final String rewardType;
  final int rewardValue;
  final String rewardUnit;
  final String status;
  final String createdAt;

  RewardItem({
    required this.id,
    this.username,
    this.referrerUsername,
    required this.rewardType,
    required this.rewardValue,
    required this.rewardUnit,
    required this.status,
    required this.createdAt,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'] ?? 0,
      username: json['username'],                     // ✅ ADDED
      referrerUsername: json['referrer_username'],    // ✅ ADDED
      rewardType: json['reward_type'] ?? '',
      rewardValue: json['reward_value'] ?? 0,
      rewardUnit: json['reward_unit'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Helper to check if reward is pending
  bool get isPending => status == 'PENDING';
  
  /// Helper to check if reward is credited
  bool get isCredited => status == 'CREDITED';
  
  /// Helper to check if reward is revoked
  bool get isRevoked => status == 'REVOKED';
  
  /// Helper to get user-friendly reward type name
  String get rewardTypeDisplay {
    switch (rewardType) {
      case 'SIGNUP':
        return 'Referral Signup';
      case 'WELCOME_BONUS':
        return 'Welcome Bonus';
      case 'FIRST_ORDER':
        return 'First Order';
      default:
        return rewardType;
    }
  }
  
  /// Helper to get reward source description
  String get sourceDescription {
    if (rewardType == 'WELCOME_BONUS' && referrerUsername != null) {
      return 'Referred by $referrerUsername';
    } else if (rewardType == 'SIGNUP' && username != null) {
      return 'For referring someone';
    }
    return 'Reward earned';
  }
  
  /// Helper to format full reward description
  String get fullDescription {
    return '$rewardValue $rewardUnit - $rewardTypeDisplay';
  }
}