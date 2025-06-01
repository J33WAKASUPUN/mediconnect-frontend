import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/review_model.dart';
import 'package:mediconnect/features/review/widgets/stars_rating.dart';
import 'package:mediconnect/shared/constants/styles.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatefulWidget {
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
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final TextEditingController _responseController = TextEditingController();
  bool _isExpanded = false;
  bool _isWritingResponse = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                // Patient avatar
                _buildAvatar(),
                const SizedBox(width: 12),

                // Name and star rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.review.patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Verified badge if not anonymous
                          if (!widget.review.isAnonymous)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user,
                                    size: 12,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StarRating(
                            rating: widget.review.rating.toDouble(),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          // Text(
                          //   _getRelativeTime(widget.review.date),
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     color: Colors.grey[600],
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Review content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Review text
                Text(
                  widget.review.review,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                
                // Show more/less button if needed
                if (_isReviewLong(widget.review.review))
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      _isExpanded ? 'Show less' : 'Show more',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Doctor's response (if available)
          if (widget.review.doctorResponse != null)
            _buildDoctorResponse(widget.review.doctorResponse!),

          // Add response button for doctors if no response yet
          if (widget.isDoctorView && widget.review.doctorResponse == null) ...[
            if (!_isWritingResponse)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isWritingResponse = true;
                    });
                  },
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply to this review'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (_isWritingResponse)
              _buildResponseInput(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: widget.review.isAnonymous
              ? Colors.grey.shade200
              : AppColors.primary.withOpacity(0.1),
          backgroundImage: widget.review.isAnonymous || widget.review.patientProfilePicture == null
              ? null
              : NetworkImage(widget.review.patientProfilePicture!),
          child: widget.review.isAnonymous || widget.review.patientProfilePicture == null
              ? Icon(
                  widget.review.isAnonymous ? Icons.person_off : Icons.person,
                  color: widget.review.isAnonymous ? Colors.grey[500] : AppColors.primary,
                )
              : null,
        ),
        if (widget.review.isAnonymous)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility_off,
                size: 12,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDoctorResponse(DoctorResponse response) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.medical_services_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Doctor\'s Response',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  // Text(
                  //   _getRelativeTime(response.date),
                  //   style: TextStyle(
                  //     fontSize: 11,
                  //     color: Colors.grey[600],
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            response.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Your Response',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
          TextField(
            controller: _responseController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your response here...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isWritingResponse = false;
                    _responseController.clear();
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_responseController.text.trim().isNotEmpty) {
                    widget.onResponseSubmit?.call(_responseController.text.trim());
                    setState(() {
                      _isWritingResponse = false;
                      _responseController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                child: const Text('Submit Response'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isReviewLong(String text) {
    // Check if the text would likely overflow 3 lines
    return text.length > 150;
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }
}