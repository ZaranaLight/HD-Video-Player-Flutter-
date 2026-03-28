import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/nav_bloc.dart';
import '../services/ads_service.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavBloc, NavItem>(
      builder: (context, currentItem) {
        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context,
                NavItem.dashboard,
                Icons.grid_view_rounded,
                currentItem == NavItem.dashboard,
              ),
              _buildNavItem(
                context,
                NavItem.wishlist,
                Icons.favorite_outline_outlined,
                currentItem == NavItem.wishlist,
              ),
              _buildNavItem(
                context,
                NavItem.easeCleaner,
                Icons.cleaning_services,
                currentItem == NavItem.easeCleaner,
              ),
              // _buildNavItem(context, NavItem.profile, Icons.person, currentItem == NavItem.profile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavItem item,
    IconData icon,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        if (isSelected) return; // Already on this tab

        AdsService().showInterstitialAd(
          trigger: 'tab_switch_tap',
          onAdClosed: () {
            context.read<NavBloc>().add(item);
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}
