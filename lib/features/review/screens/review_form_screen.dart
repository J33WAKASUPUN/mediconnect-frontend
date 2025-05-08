import 'package:flutter/material.dart';
import 'package:mediconnect/features/review/widgets/stars_rating.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';

class ReviewFormScreen extends StatefulWidget {
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String appointmentDate;

  const ReviewFormScreen({
    super.key,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentDate,
  });

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    // Validate input
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      final success = await reviewProvider.createReview(
        appointmentId: widget.appointmentId,
        rating: _rating.toInt(),
        review: _reviewController.text.trim(),
        isAnonymous: _isAnonymous,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reviewProvider.error ?? 'Failed to submit review'),
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor info
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
                      'Write a review for',
                      style: AppStyles.bodyText1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctorName,
                      style: AppStyles.heading2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appointment date: ${widget.appointmentDate}',
                      style: AppStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rating
            Text(
              'Rating',
              style: AppStyles.subtitle1,
            ),
            const SizedBox(height: 8),
            Center(
              child: StarRating(
                rating: _rating,
                size: 40,
                editable: true,
                onRatingChanged: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Review text
            Text(
              'Your Review',
              style: AppStyles.subtitle1,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Write your experience with the doctor...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counter: const SizedBox.shrink(), // Hide the counter
              ),
            ),
            
            const SizedBox(height: 16),

            // Anonymous option
            CheckboxListTile(
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value ?? false;
                });
              },
              title: const Text('Post anonymously'),
              subtitle: const Text('Your name and profile picture will not be visible'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),
            
            // Submit button
            CustomButton(
              text: 'Submit Review',
              icon: Icons.check_circle,
              isLoading: _isSubmitting,
              onPressed: _submitReview,
            ),
          ],
        ),
      ),
    );
  }
}