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
      appBar: AppBar(
        title: Text('Reviews for ${widget.doctorName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reviews'),
            Tab(text: 'Analytics'),
          ],
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
                const Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No reviews yet'),
              ],
            ),
          );
        }
        
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadReviews,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary at the top
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              StarRating(
                                rating: provider.averageRating,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Based on ${provider.totalReviews} reviews',
                                  style: AppStyles.bodyText1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to see detailed analytics',
                                  style: AppStyles.bodyText2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
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
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    
                  // No more items indicator
                  if (!provider.hasMorePages && provider.doctorReviews.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No more reviews to load',
                          style: TextStyle(color: Colors.grey),
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
                const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No analytics available'),
              ],
            ),
          );
        }
        
        // Display analytics
        final analytics = provider.analytics!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall stats card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Statistics',
                        style: AppStyles.heading2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatBox(
                            title: 'Total Reviews',
                            value: analytics.overall['totalReviews'].toString(),
                            icon: Icons.rate_review,
                          ),
                          const SizedBox(width: 16),
                          _buildStatBox(
                            title: 'Average Rating',
                            value: analytics.overall['averageRating'].toStringAsFixed(1),
                            icon: Icons.star,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 16),
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
              
              const SizedBox(height: 24),
              
              // Rating distribution
              Text(
                'Rating Distribution',
                style: AppStyles.heading2,
              ),
              const SizedBox(height: 16),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildRatingBar(
                        label: '5 stars',
                        count: analytics.ratingDistribution['5_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.green,
                      ),
                      _buildRatingBar(
                        label: '4 stars',
                        count: analytics.ratingDistribution['4_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.lightGreen,
                      ),
                      _buildRatingBar(
                        label: '3 stars',
                        count: analytics.ratingDistribution['3_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.amber,
                      ),
                      _buildRatingBar(
                        label: '2 stars',
                        count: analytics.ratingDistribution['2_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.orange,
                      ),
                      _buildRatingBar(
                        label: '1 star',
                        count: analytics.ratingDistribution['1_star'] ?? 0,
                        total: analytics.overall['totalReviews'] ?? 1,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Monthly trends
              Text(
                'Monthly Rating Trends',
                style: AppStyles.heading2,
              ),
              const SizedBox(height: 16),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
              
              const SizedBox(height: 16),
              
              // Last updated timestamp
              Center(
                child: Text(
                  'Last updated: ${_formatDate(analytics.lastUpdated)}',
                  style: AppStyles.bodyText2.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: AppStyles.bodyText2,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width * 0.6 * percentage,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              count.toString(),
              textAlign: TextAlign.end,
              style: AppStyles.bodyText2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthlyStatRow({
    required String month,
    required double average,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              month,
              style: AppStyles.bodyText1,
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
                  style: AppStyles.bodyText1,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$count reviews',
              style: AppStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
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