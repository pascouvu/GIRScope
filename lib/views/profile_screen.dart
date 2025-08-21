import 'package:flutter/material.dart';
import 'package:girscope/views/content_screen.dart';
import 'package:girscope/widgets/responsive_wrapper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:girscope/services/auth_service.dart';
import 'package:girscope/views/auth/login_screen.dart';
import 'package:girscope/models/user.dart' as girscope_user;
import 'package:girscope/views/user_management_screen.dart';
import 'package:girscope/views/business_management_screen.dart';
import 'package:girscope/widgets/business_logo_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _appName = 'GIRScope';
  String _version = '1.0.0';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appName = packageInfo.appName;
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // Keep default values if package info fails to load
      print('Error loading package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            FutureBuilder<girscope_user.User?>(
              future: () async {
                print('*** DEBUG: ProfileScreen header calling AuthService.getUserProfile()');
                final user = await AuthService.getUserProfile();
                print('*** DEBUG: ProfileScreen header got user: ${user?.fullName}');
                return user;
              }(),
              builder: (context, snapshot) {
                print('*** DEBUG: Profile header FutureBuilder called');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('*** DEBUG: Profile header still loading user profile');
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fuel Management System',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
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

                if (snapshot.hasError || !snapshot.hasData) {
                  print('*** DEBUG: Profile header error or no user data: ${snapshot.error}');
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GIRScope User',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fuel Management System',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
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

                final user = snapshot.data!;
                print('*** DEBUG: Profile header user data - fullName: ${user.fullName}, role: ${user.role}');
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BusinessLogoWidget(
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Role: ${user.role.toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Fuel Management System',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Legal & Information Section
            const Text(
              'Legal & Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            
            // About Us
            _buildProfileOption(
              context,
              icon: Icons.info,
              title: 'About Us',
              subtitle: 'Learn more about our company',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContentScreen(
                      title: 'About Us',
                      contentType: 'aboutus',
                    ),
                  ),
                );
              },
            ),
            
            // Privacy Policy
            _buildProfileOption(
              context,
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContentScreen(
                      title: 'Privacy Policy',
                      contentType: 'privacypolicy',
                    ),
                  ),
                );
              },
            ),
            
            // Terms and Conditions
            _buildProfileOption(
              context,
              icon: Icons.description,
              title: 'Terms and Conditions',
              subtitle: 'Terms of service and usage',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContentScreen(
                      title: 'Terms and Conditions',
                      contentType: 'termsandconditions',
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Management Section (only visible for Manager, Admin, or SuperAdmin)
            FutureBuilder<girscope_user.User?>(
              future: () async {
                print('*** DEBUG: ProfileScreen management section calling AuthService.getUserProfile()');
                final user = await AuthService.getUserProfile();
                print('*** DEBUG: ProfileScreen management section got user: ${user?.fullName}');
                return user;
              }(),
              builder: (context, snapshot) {
                print('*** DEBUG: Management section FutureBuilder called');
                print('*** DEBUG: Management section snapshot connectionState: ${snapshot.connectionState}');
                print('*** DEBUG: Management section snapshot hasData: ${snapshot.hasData}');
                print('*** DEBUG: Management section snapshot hasError: ${snapshot.hasError}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('*** DEBUG: Management section still loading user profile');
                  return const SizedBox.shrink();
                }
                
                if (snapshot.hasError) {
                  print('*** DEBUG: Management section error: ${snapshot.error}');
                  return const SizedBox.shrink();
                }
                
                if (!snapshot.hasData) {
                  print('*** DEBUG: Management section no user data');
                  return const SizedBox.shrink();
                }
                
                final user = snapshot.data!;
                print('*** DEBUG: Management section user data - fullName: ${user.fullName}, role: ${user.role}');
                
                final userRole = user.role.trim().toLowerCase();
                final isManagerOrAbove = userRole == 'manager' || 
                                        userRole == 'admin' || 
                                        userRole == 'superadmin';
                final isSuperAdmin = userRole == 'superadmin';
                
                print('*** DEBUG: Management section role processing:');
                print('*** DEBUG:   Original role: "${user.role}"');
                print('*** DEBUG:   Trimmed and lowercased: "$userRole"');
                print('*** DEBUG:   isManagerOrAbove: $isManagerOrAbove');
                print('*** DEBUG:   isSuperAdmin: $isSuperAdmin');
                
                // Super admins should always see management options regardless of business_id
                if (isSuperAdmin) {
                  print('*** DEBUG: User is superadmin, showing management section');
                } else if (!isManagerOrAbove) {
                  print('*** DEBUG: Hiding management section because user is not manager or above');
                  return const SizedBox.shrink();
                }
                
                print('*** DEBUG: Building management section');
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildProfileOption(
                      context,
                      icon: Icons.group,
                      title: 'Manage Users',
                      subtitle: 'View and manage users in your company',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    if (isSuperAdmin) ...[
                      const SizedBox(height: 12),
                      _buildProfileOption(
                        context,
                        icon: Icons.business,
                        title: 'Business Management',
                        subtitle: 'View and manage businesses',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BusinessManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            
            // Account Section
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            
            // Sign Out
            _buildProfileOption(
              context,
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              onTap: () async {
                final shouldSignOut = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                
                if (shouldSignOut == true) {
                  await AuthService.signOut();
                  // Navigate directly to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // App Information Section
            const Text(
              'App Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            
            // Version Info with Developer Logo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildNumber.isNotEmpty 
                                ? 'Version $_version ($_buildNumber)'
                                : 'Version $_version',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // IEC Developer Logo
                    Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.asset(
                              'assets/images/ieclogo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.business,
                                    color: Colors.grey,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'www.iec.vu',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
