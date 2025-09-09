// components/sidebar_component.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SidebarComponent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigationTap;

  const SidebarComponent({
    Key? key,
    required this.selectedIndex,
    required this.onNavigationTap,
  }) : super(key: key);

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(icon: Icons.home, label: 'Home', route: '/homepage'),
    NavigationItem(icon: Icons.search, label: 'Search', route: '/search'),
    NavigationItem(icon: Icons.favorite, label: 'Favourites', route: '/favourites'),
    NavigationItem(icon: Icons.calendar_today, label: 'Planner', route: '/planner'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.apps,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Brand Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Organize',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Better',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Discover Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Discover',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigation Items
          ...List.generate(_navigationItems.length, (index) {
            final item = _navigationItems[index];
            final isSelected = selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 2.0,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    onNavigationTap(index);
                    Navigator.of(context).pushReplacementNamed(item.route);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey[100] : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isSelected ? Colors.black : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            color: isSelected ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // User Info and Logout
          Container(
            margin: const EdgeInsets.all(24.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signed in as:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}