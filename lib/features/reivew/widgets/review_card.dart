import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/review_model.dart';
import 'package:mediconnect/features/reivew/widgets/stars_rating.dart';
import 'package:mediconnect/shared/constants/styles.dart';
import 'package:mediconnect/shared/constants/colors.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isDoctorView;
  final Function(String)? onResponseSubmit;
  
  const ReviewCard({
    super.key,
    required this.review,
    this.isDoctorView = false,
    this.onResponseSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review Header
            Row(
              children: [
                // Patient avatar or anonymous icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor: review.isAnonymous 
                      ? Colors.grey.shade300 
                      : AppColors.primary.withOpacity(0.2),
                  backgroundImage: review.isAnonymous || review.patientProfilePicture == null
                      ? null
                      : NetworkImage(review.patientProfilePicture!),
                  child: review.isAnonymous || review.patientProfilePicture == null
                      ? Icon(
                          review.isAnonymous ? Icons.person_off : Icons.person,
                          color: review.isAnonymous ? Colors.grey : AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.patientName,
                        style: AppStyles.subtitle1,
                      ),
                      Text(
                        'Posted on ${review.formattedDate}',
                        style: AppStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Rating stars
                StarRating(
                  rating: review.rating.toDouble(),
                  size: 16,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Review content
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review.review,
                style: AppStyles.bodyText1,
              ),
            ),
            
            // Doctor's response (if available)
            if (review.doctorResponse != null) ...[
              const SizedBox(height: 16),
              _buildDoctorResponse(context, review.doctorResponse!),
            ],
            
            // Add response button for doctors if no response yet
            if (isDoctorView && review.doctorResponse == null) ...[
              const SizedBox(height: 16),
              _buildResponseInput(context),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDoctorResponse(BuildContext context, DoctorResponse response) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_services,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Doctor\'s Response',
                style: AppStyles.subtitle2.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Replied on ${response.formattedDate}',
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            response.content,
            style: AppStyles.bodyText1,
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponseInput(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Write your response to this review...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              onResponseSubmit?.call(controller.text.trim());
              controller.clear();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Submit Response'),
        ),
      ],
    );
  }
}