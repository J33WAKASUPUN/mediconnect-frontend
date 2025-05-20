import 'package:flutter/material.dart';
import 'package:mediconnect/shared/constants/colors.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Increased height for better spacing
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Center profile button that extends above the nav bar
          Positioned.fill(
            top: -25, // Move it further up to extend more
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () => onTap(2),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 65, // Make it slightly larger
                      width: 65, // Make it slightly larger
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 32, // Larger icon
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Row for the other nav items
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.search_rounded, 'Doctors'),
                // Empty space for center profile button
                const SizedBox(width: 60),
                _buildNavItem(3, Icons.message_rounded, 'Messages'),
                _buildNavItem(4, Icons.calendar_month_rounded, 'Appointments'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isSelected ? 48 : 40, // More dramatic size difference
            width: isSelected ? 48 : 40, // More dramatic size difference
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: isSelected ? 26 : 20, // More dramatic size difference
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}