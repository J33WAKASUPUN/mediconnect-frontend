import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';

class StarRating extends StatefulWidget {
  final double rating;
  final double size;
  final Color color;
  final Color unratedColor;
  final bool allowHalf;
  final bool editable;
  final double spacing;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 24.0,
    this.color = AppColors.warning,
    this.unratedColor = Colors.grey,
    this.allowHalf = true,
    this.editable = false,
    this.spacing = 2.0,
    this.onRatingChanged,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  double _hoverRating = 0;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _sizeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index < 4 ? widget.spacing : 0),
          child: MouseRegion(
            cursor: widget.editable ? SystemMouseCursors.click : SystemMouseCursors.basic,
            onEnter: widget.editable ? (_) => _updateHoverRating(index + 1) : null,
            onHover: widget.editable ? (event) => _updatePreciseHoverRating(event, index) : null,
            onExit: widget.editable ? (_) => _clearHoverRating() : null,
            child: GestureDetector(
              onTap: widget.editable ? () => _handleTap(index + 1) : null,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final displayRating = _isHovering ? _hoverRating : widget.rating;
                  final isActive = index < displayRating;
                  final isHalf = widget.allowHalf && index + 0.5 == displayRating;
                  final scale = isActive && _isHovering ? _sizeAnimation.value : 1.0;
                  
                  return Transform.scale(
                    scale: scale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background star (empty)
                        Icon(
                          Icons.star_rounded,
                          color: widget.unratedColor.withOpacity(0.3),
                          size: widget.size,
                        ),
                        
                        // Foreground star (filled or half-filled)
                        if (isActive || isHalf)
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: isHalf ? [0.0, 0.5, 0.5, 1.0] : [0.0, 1.0],
                                colors: isHalf
                                    ? [widget.color, widget.color, widget.unratedColor.withOpacity(0.3), widget.unratedColor.withOpacity(0.3)]
                                    : [widget.color, widget.color],
                              ).createShader(bounds);
                            },
                            child: Icon(
                              Icons.star_rounded,
                              color: widget.color,
                              size: widget.size,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  void _updateHoverRating(int index) {
    if (!widget.editable) return;
    setState(() {
      _hoverRating = index.toDouble();
      _isHovering = true;
    });
    _controller.forward();
  }

  void _updatePreciseHoverRating(PointerEvent event, int index) {
    if (!widget.editable) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final starWidth = widget.size + widget.spacing;
    final localPosition = box.globalToLocal(event.position);
    final starStart = index * starWidth;
    final position = (localPosition.dx - starStart) / widget.size;
    
    if (position >= 0 && position <= 1) {
      final halfStar = position < 0.5 && widget.allowHalf;
      setState(() {
        _hoverRating = halfStar ? index + 0.5 : index + 1.0;
      });
    }
  }

  void _clearHoverRating() {
    if (!widget.editable) return;
    setState(() {
      _isHovering = false;
    });
    _controller.reverse();
  }

  void _handleTap(int index) {
    if (!widget.editable) return;
    final newRating = index.toDouble();
    setState(() {
      _isHovering = false;
    });
    widget.onRatingChanged?.call(newRating);
  }
}