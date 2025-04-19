import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class ReviewDialog extends StatefulWidget {
  final String doctorName;
  final Function(int rating, String comment) onSubmit;

  const ReviewDialog({
    Key? key,
    required this.doctorName,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _ReviewDialogState createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate your experience',
              style: AppStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              'How was your appointment with ${widget.doctorName}?',
              style: AppStyles.bodyText1,
            ),
            const SizedBox(height: 24),
            
            // Rating stars
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: AppColors.warning,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            
            // Comment section
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            
            // Submit button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _rating > 0
                      ? () {
                          widget.onSubmit(_rating, _commentController.text);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Submit Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}