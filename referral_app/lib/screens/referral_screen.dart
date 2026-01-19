import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../models/referral.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _referralCodeController = TextEditingController();
  
  ReferralSummary? _summary;
  List<ReferralItem> _referralList = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isApplying = false;

  // ✅ Keep state alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return; // Prevent duplicate calls
    
    setState(() => _isLoading = true);
    
    try {
      final summary = await _apiService.getReferralSummary();
      final list = await _apiService.getReferralList();
      
      if (mounted) {
        setState(() {
          _summary = summary;
          _referralList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Failed to load data: $e', Colors.red);
      }
    }
  }

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);
    
    try {
      final result = await _apiService.generateReferralCode();
      
      if (mounted) {
        setState(() => _isGenerating = false);
        
        if (result['success']) {
          _showMessage('Referral code generated successfully!', Colors.green);
          await _loadData(); // Reload to show new code
        } else {
          _showMessage(result['message'] ?? 'Failed to generate code', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        _showMessage('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _applyCode() async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) {
      _showMessage('Please enter a referral code', Colors.orange);
      return;
    }

    setState(() => _isApplying = true);
    
    try {
      final result = await _apiService.applyReferralCode(code);
      
      if (mounted) {
        setState(() => _isApplying = false);
        
        if (result['success']) {
          _showMessage(result['message'] ?? 'Success!', Colors.green);
          _referralCodeController.clear();
          
          // Show success dialog with rewards info
          _showSuccessDialog();
          
          await _loadData(); // Reload data
        } else {
          _showMessage(result['message'] ?? 'Failed', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        _showMessage('Error: $e', Colors.red);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 12),
            const Text('Success!', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Referral code applied successfully!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'You earned a welcome bonus!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'The referrer will also receive rewards!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check the Rewards tab to see your bonus!',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showMessage('Copied to clipboard!', Colors.green);
  }

  void _shareCode(String code) {
    Share.share(
      'Join me using my referral code: $code\n\nYou\'ll get a welcome bonus when you sign up!',
      subject: 'Referral Code',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Summary Card
            if (_summary != null && _summary!.hasGeneratedCode)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildSummaryCard(),
                ),
              ),
            
            // My Referral Code Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMyCodeCard(),
              ),
            ),
            
            // Apply Referral Code Card (only if user hasn't used one)
            if (_summary != null && !_summary!.hasUsedReferral)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildApplyCodeCard(),
                ),
              ),
            
            // Referral History Header
            if (_summary != null && _summary!.hasGeneratedCode)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Referral History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_referralList.length} total',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Referral List
            if (_summary != null && _summary!.hasGeneratedCode)
              _buildReferralList(),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Your Referral Stats',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  '${_summary!.totalReferrals}',
                  Icons.people,
                  Colors.white,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  'Successful',
                  '${_summary!.successfulReferrals}',
                  Icons.check_circle,
                  Colors.white,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  'Rate',
                  _summary!.conversionRate,
                  Icons.trending_up,
                  Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMyCodeCard() {
    final hasCode = _summary?.hasGeneratedCode ?? false;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'My Referral Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (hasCode)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade300,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _summary!.myReferralCode!,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: Colors.blue.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(_summary!.myReferralCode!),
                          icon: const Icon(Icons.copy, size: 20),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareCode(_summary!.myReferralCode!),
                          icon: const Icon(Icons.share, size: 20),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share this code to earn rewards when people sign up!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    'Generate your unique referral code to start earning rewards!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateCode,
                      icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add_circle_outline),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate My Code'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyCodeCard() {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Have a Referral Code?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a referral code to get your welcome bonus!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referralCodeController,
              decoration: const InputDecoration(
                labelText: 'Enter Code',
                hintText: 'SVH-XXXXXX',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
              enabled: !_isApplying,
              onSubmitted: (_) => _applyCode(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isApplying ? null : _applyCode,
                icon: _isApplying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle),
                label: Text(_isApplying ? 'Applying...' : 'Apply Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_referralList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No referrals yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your referral code to get started!',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final referral = _referralList[index];
            return _buildReferralCard(referral);
          },
          childCount: _referralList.length,
        ),
      ),
    );
  }

  Widget _buildReferralCard(ReferralItem referral) {
    final isSuccess = referral.isSuccess;
    final color = isSuccess ? Colors.green : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSuccess ? Icons.check_circle : Icons.pending,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          referral.referralCode,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              referral.usedByDisplay,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSuccess ? FontWeight.w500 : FontWeight.normal,
                color: isSuccess ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              referral.formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            referral.status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }
}