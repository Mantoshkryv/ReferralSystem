class ApiConfig {
  // Change this to your Django server IP
  // For Android emulator: http://10.0.2.2:8000
  // For iOS simulator: http://localhost:8000
  // For real device: http://YOUR_COMPUTER_IP:8000
  
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Auth endpoints
  static const String register = '$baseUrl/users/register/';
  static const String login = '$baseUrl/users/login/';
  
  // Referral endpoints
  static const String generateReferral = '$baseUrl/referrals/generate/';
  static const String applyReferral = '$baseUrl/referrals/apply/';
  static const String referralSummary = '$baseUrl/referrals/analytics/summary/';
  static const String referralList = '$baseUrl/referrals/analytics/list/';
  static const String referralTimeline = '$baseUrl/referrals/analytics/timeline/';
  static const String topReferrers = '$baseUrl/referrals/admin/top/';
  
  // Reward endpoints
  static const String rewardSummary = '$baseUrl/rewards/summary/';
  static const String rewardHistory = '$baseUrl/rewards/history/';
  static String creditReward(int rewardId) => '$baseUrl/rewards/admin/credit/$rewardId/';
}