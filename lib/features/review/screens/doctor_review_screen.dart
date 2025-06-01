import 'package:flutter/material.dart';
import 'package:mediconnect/features/review/widgets/review_card.dart';
import 'package:mediconnect/features/review/widgets/stars_rating.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';

class DoctorReviewsScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorReviewsScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load reviews when screen opens
    _loadReviews();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    // Check if we're near the bottom of the list
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReviews();
    }
  }
  
  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      await reviewProvider.loadDoctorReviews(widget.doctorId, refresh: true);
      await reviewProvider.loadDoctorReviewAnalytics(widget.doctorId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadMoreReviews() async {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    if (!reviewProvider.hasMorePages || reviewProvider.isLoading) return;
    
    await reviewProvider.loadMoreReviews(widget.doctorId);
  }
  
  Future<void> _handleResponseSubmit(String reviewId, String response) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      final success = await reviewProvider.addDoctorResponse(
        reviewId: reviewId,
        response: response,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Response submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reviewProvider.error ?? 'Failed to submit response'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background like Google Play
      appBar: AppBar(
        elevation: 0, // Modern no-shadow look
        title: Text(
          'Reviews for Dr. ${widget.doctorName.split(' ').last}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3.0,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'REVIEWS'),
                Tab(text: 'ANALYTICS'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading ? const Center(child: LoadingIndicator()) : TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }
  
  Widget _buildReviewsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.doctorReviews.isEmpty) {
          return const Center(child: LoadingIndicator());
        }
        
        if (provider.error != null && provider.doctorReviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadReviews,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (provider.doctorReviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[350]),
                const SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to review Dr. ${widget.doctorName.split(' ').last}',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadReviews,
              color: AppColors.primary,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 24),
                children: [
                  // Summary at the top - Play Store style card
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Rating number with circular background
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    provider.averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'out of 5',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StarRating(
                                  rating: provider.averageRating,
                                  size: 22,
                                  spacing: 4,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${provider.totalReviews} reviews',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to see detailed analytics',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Reviews header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: Text(
                      'REVIEWS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  // Reviews list
                  ...provider.doctorReviews.map((review) {
                    return ReviewCard(
                      review: review,
                      isDoctorView: true, // Only doctors can respond to reviews
                      onResponseSubmit: (response) => _handleResponseSubmit(review.id, response),
                    );
                  }),
                  
                  // Loading indicator at the bottom if loading more
                  if (provider.isLoading && provider.doctorReviews.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                    
                  // No more items indicator
                  if (!provider.hasMorePages && provider.doctorReviews.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: Text(
                        'You\'ve reached the end',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Show loading indicator overlay when submitting a response
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: LoadingIndicator()),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildAnalyticsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.analytics == null) {
          return const Center(child: LoadingIndicator());
        }
        
        if (provider.error != null && provider.analytics == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadDoctorReviewAnalytics(widget.doctorId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (provider.analytics == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[350]),
                const SizedBox(height: 16),
                Text(
                  'No analytics available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Display analytics
        final analytics = provider.analytics!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall stats card - Modern card appearance
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Statistics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          _buildStatBox(
                            title: 'Total Reviews',
                            value: analytics.overall['totalReviews'].toString(),
                            icon: Icons.rate_review,
                          ),
                          const SizedBox(width: 12),
                          _buildStatBox(
                            title: 'Average Rating',
                            value: analytics.overall['averageRating'].toStringAsFixed(1),
                            icon: Icons.star,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          _buildStatBox(
                            title: 'Anonymous',
                            value: '${analytics.overall['anonymousPercentage']}%',
                            icon: Icons.person_off,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Rating distribution - Section Title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'RATING DISTRIBUTION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              // Rating distribution card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildRatingBar(
                        label: '5',
                        count: analytics.ratingDistribution['5_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildRatingBar(
                        label: '4',
                        count: analytics.ratingDistribution['4_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.lightGreen,
                      ),
                      const SizedBox(height: 12),
                      _buildRatingBar(
                        label: '3',
                        count: analytics.ratingDistribution['3_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 12),
                      _buildRatingBar(
                        label: '2',
                        count: analytics.ratingDistribution['2_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildRatingBar(
                        label: '1',
                        count: analytics.ratingDistribution['1_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Monthly trends - Section Title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'MONTHLY TRENDS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              // Monthly trends card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ...analytics.monthlyStats.entries.map((entry) {
                        final month = entry.key;
                        final stats = entry.value;
                        return _buildMonthlyStatRow(
                          month: _formatMonthYear(month),
                          average: stats['average'],
                          count: stats['count'],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              
              // Last updated timestamp
              Center(
                child: Text(
                  'Last updated: ${_formatDate(analytics.lastUpdated)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    Color color = AppColors.primary,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRatingBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final double percentage = total > 0 ? count / total : 0;
    
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.star, size: 16, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              // Background bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Foreground bar with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuart,
                height: 8,
                width: MediaQuery.of(context).size.width * 0.55 * percentage,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            count.toString(),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMonthlyStatRow({
    required String month,
    required double average,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              month,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                StarRating(
                  rating: average,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$count reviews',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatMonthYear(String monthYear) {
    final parts = monthYear.split('-');
    if (parts.length == 2) {
      final year = parts[0];
      final month = parts[1];
      
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      final monthInt = int.tryParse(month);
      if (monthInt != null && monthInt >= 1 && monthInt <= 12) {
        return '${months[monthInt]} $year';
      }
    }
    
    return monthYear;
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}