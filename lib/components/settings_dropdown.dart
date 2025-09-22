// components/settings_dropdown.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsDropdown extends StatelessWidget {
  final VoidCallback? onClose;

  const SettingsDropdown({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration:  BoxDecoration(
        color: Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User info section with unlock premium - single container
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // User info part
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                decoration: TextDecoration.none,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[200],
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // Unlock Premium Features
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildMenuItem(
                    assetPath: 'assets/icons/Lock.png',
                    title: 'Unlock Premium Features',
                    onTap: () {
                      onClose?.call();
                      // Handle unlock premium
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Main menu items container
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _buildMenuItem(
                    assetPath: 'assets/icons/Magazine.png',
                    title: 'Manage Notebook Templates',
                    onTap: () {
                      onClose?.call();
                      // Handle manage notebook templates
                    },
                  ),
                  _buildMenuItem(
                    assetPath: 'assets/icons/Tune.png',
                    title: 'Settings',
                    onTap: () {
                      onClose?.call();
                      // Handle settings
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_outline,
                    title: 'Trash',
                    onTap: () {
                      onClose?.call();
                      // Handle trash
                    },
                  ),
                  _buildMenuItem(
                    assetPath: 'assets/icons/User Manual.png',
                    title: 'User Guide',
                    onTap: () {
                      onClose?.call();
                      // Handle user guide
                    },
                  ),
                  _buildMenuItem(
                    assetPath: 'assets/images/organize_splash.png',
                    title: 'About',
                    onTap: () {
                      onClose?.call();
                      // Handle about
                    },
                  ),
                  _buildMenuItem(
                    assetPath: 'assets/icons/Star.png',
                    title: 'Rate on App Store',
                    onTap: () {
                      onClose?.call();
                      // Handle rate on app store
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Separate Report an Issue container
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: _buildMenuItem(
              assetPath: 'assets/icons/Error.png',
              title: 'Report an Issue',
              onTap: () {
                onClose?.call();
                // Handle report issue
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    IconData? icon,
    String? assetPath,
    required String title,
    required VoidCallback onTap,
    bool hasBackground = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasBackground ? const Color(0xFFE8D5F0) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              assetPath != null
                  ? Image.asset(
                assetPath,
                width: 18,
                height: 18,
                color: Colors.black,
              )
                  : Icon(
                icon,
                size: 18,
                color: Colors.black,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}