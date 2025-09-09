// screens/planner_screen.dart
import 'package:flutter/material.dart';
import '../components/sidebar_component.dart';
import 'homepage_screen.dart';
import 'search_screen.dart';
import 'favourites_screen.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          SidebarComponent(
            selectedIndex: 3, // Planner is selected
            onNavigationTap: (index) => _handleNavigation(context, index),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Planner',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Handle new planner creation
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Planner'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.upgrade),
                            onPressed: () {},
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter/View Options
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 16),
                                  SizedBox(width: 8),
                                  Text('All Planners', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 16),
                                  SizedBox(width: 8),
                                  Text('Recent', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.sort),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.grid_view),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Planners Grid
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                            children: [
                              _buildNewPlannerCard(),
                              _buildPlannerCard('Daily Planner', Colors.blue[400]!, 'Today\'s tasks and schedule'),
                              _buildPlannerCard('Weekly Goals', Colors.green[400]!, 'Week of Aug 12-18'),
                              _buildPlannerCard('Project Notes', Colors.purple[400]!, 'Development roadmap'),
                              _buildPlannerCard('Meeting Notes', Colors.orange[400]!, 'Team standup notes'),
                              _buildPlannerCard('Personal Journal', Colors.pink[400]!, 'Daily reflections'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPlannerCard() {
    return InkWell(
      onTap: () {
        // Handle new planner creation
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'New Planner',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannerCard(String title, Color color, String subtitle) {
    return InkWell(
      onTap: () {
        // Handle planner tap - open planner detail view
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: PopupMenuButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new, size: 16),
                        SizedBox(width: 8),
                        Text('Open'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 16),
                        SizedBox(width: 8),
                        Text('Add to Favourites'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 16),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  // Handle menu item selection
                  switch (value) {
                    case 'open':
                    // Open planner
                      break;
                    case 'edit':
                    // Edit planner
                      break;
                    case 'favorite':
                    // Add to favourites
                      break;
                    case 'duplicate':
                    // Duplicate planner
                      break;
                    case 'delete':
                    // Show delete confirmation dialog
                      break;
                  }
                },
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '12 Aug2025 at 3:22PM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add the missing navigation function
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomepageScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FavouritesScreen()),
        );
        break;
      case 3:
      // Current screen - do nothing
        break;
    }
  }
}