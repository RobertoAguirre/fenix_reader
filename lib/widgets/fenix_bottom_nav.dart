import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Bottom Navigation personalizado de Fénix
class FenixBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FenixBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.origen,
        boxShadow: [
          BoxShadow(
            color: AppColors.raizSagrada.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                imagePath: 'assets/images/ankh.png',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                imagePath: 'assets/images/biblioteca.png',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                imagePath: 'assets/images/user.png',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        imagePath,
        width: 28,
        height: 28,
        color: isSelected ? AppColors.ascenso : AppColors.expansionAlquimica,
      ),
    );
  }
}

