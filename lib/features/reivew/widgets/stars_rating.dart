import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final Color unratedColor;
  final bool allowHalf;
  final bool editable;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 24.0,
    this.color = AppColors.warning,
    this.unratedColor = Colors.grey,
    this.allowHalf = true,
    this.editable = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: editable ? () => onRatingChanged?.call(index + 1.0) : null,
          child: Icon(
            _getIconData(index),
            color: _getColor(index),
            size: size,
          ),
        );
      }),
    );
  }

  IconData _getIconData(int index) {
    if (rating >= index + 1) {
      return Icons.star;
    } else if (rating >= index + 0.5 && allowHalf) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getColor(int index) {
    if (rating >= index + 0.5) {
      return color;
    } else {
      return unratedColor;
    }
  }
}