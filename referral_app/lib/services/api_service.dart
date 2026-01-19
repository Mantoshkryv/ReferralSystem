import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/referral.dart';
import '../models/reward.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  // Get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== REFERRAL APIs ====================

  // Generate referral code
  Future<Map<String, dynamic>> generateReferralCode() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.generateReferral),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'referral_code': data['referral_code'],
        };
      } else {
        return {'success': false, 'message': 'Failed to generate code'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Apply referral code
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.applyReferral),
        headers: headers,
        body: jsonEncode({'referral_code': code}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Referral applied successfully'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['error'] ?? 'Failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get referral summary
  Future<ReferralSummary?> getReferralSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.referralSummary),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReferralSummary.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching referral summary: $e');
      return null;
    }
  }

  // Get referral list
  Future<List<ReferralItem>> getReferralList() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.referralList),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ReferralItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching referral list: $e');
      return [];
    }
  }

  // ==================== REWARD APIs ====================

  // Get reward summary
  Future<RewardSummary?> getRewardSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.rewardSummary),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RewardSummary.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching reward summary: $e');
      return null;
    }
  }

  // Get reward history
  Future<List<RewardItem>> getRewardHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.rewardHistory),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RewardItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching reward history: $e');
      return [];
    }
  }

  // ==================== ADMIN APIs ====================

  // Credit reward (admin only)
  Future<Map<String, dynamic>> creditReward(int rewardId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.creditReward(rewardId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Reward credited successfully'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['error'] ?? 'Failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get top referrers (admin only)
  Future<List<Map<String, dynamic>>> getTopReferrers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.topReferrers),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching top referrers: $e');
      return [];
    }
  }
}