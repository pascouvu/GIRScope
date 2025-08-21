import 'package:flutter/material.dart';
import 'package:girscope/models/user.dart' as girscope_user;
import 'package:girscope/services/auth_service.dart';
import 'package:girscope/widgets/responsive_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<girscope_user.User>> _usersFuture;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Search and sorting state
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'email', 'role'
  bool _sortAscending = true;
  
  // Filtered and sorted users
  List<girscope_user.User> _allUsers = [];
  List<girscope_user.User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<girscope_user.User>> _fetchUsers() async {
    print('*** DEBUG: UserManagementScreen._fetchUsers started');
    try {
      // Get current user's profile
      final currentUser = await AuthService.getUserProfile();
      print('*** DEBUG: UserManagementScreen current user: ${currentUser?.fullName} with role ${currentUser?.role}');
      
      if (currentUser == null) {
        print('*** DEBUG: UserManagementScreen no current user');
        return [];
      }

      // Check if current user has permission to view users
      final userRole = currentUser.role.trim().toLowerCase();
      final isManagerOrAbove = userRole == 'manager' || 
                              userRole == 'admin' || 
                              userRole == 'superadmin';
      
      if (!isManagerOrAbove) {
        print('*** DEBUG: UserManagementScreen user does not have permission to view other users');
        return [];
      }

      // Super admins can see all users
      if (userRole == 'superadmin') {
        print('*** DEBUG: UserManagementScreen super admin - fetching all users');
        final response = await _supabase
            .from('users')
            .select('id, email, full_name, business_id, role, created_at, updated_at');
        
        print('*** DEBUG: UserManagementScreen fetched all users count: ${response.length}');
        return response.map((e) => girscope_user.User.fromJson(e)).toList();
      }

      // Regular managers and admins can only see users in their company
      // For regular users, business_id is required
      if (currentUser.businessId == null) {
        print('*** DEBUG: UserManagementScreen current user has no business ID');
        return [];
      }

      // Fetch users from the same business
      final response = await _supabase
          .from('users')
          .select('id, email, full_name, business_id, role, created_at, updated_at')
          .eq('business_id', currentUser.businessId!);

      print('*** DEBUG: UserManagementScreen fetched users from same business count: ${response.length}');
      return response.map((e) => girscope_user.User.fromJson(e)).toList();
    } catch (e, stackTrace) {
      print('*** DEBUG: UserManagementScreen error in _fetchUsers: $e');
      print('*** DEBUG: UserManagementScreen stack trace: $stackTrace');
      // Handle error
      return [];
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  void _updateFilteredUsers() {
    // Filter users based on search query
    _filteredUsers = _allUsers.where((user) {
      final query = _searchQuery.toLowerCase();
      return user.fullName.toLowerCase().contains(query) ||
             user.email.toLowerCase().contains(query) ||
             user.role.toLowerCase().contains(query);
    }).toList();

    // Sort users
    _filteredUsers.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'role':
          comparison = a.role.compareTo(b.role);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _sortByColumn(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = true;
      }
      _updateFilteredUsers();
    });
  }

  Future<void> _editUser(girscope_user.User user) async {
    // Get current user to check permissions
    final currentUser = await AuthService.getUserProfile();
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to verify your permissions')),
        );
      }
      return;
    }

    final userRole = currentUser.role.trim().toLowerCase();
    final isSuperAdmin = userRole == 'superadmin';
    final isAdmin = userRole == 'admin';
    
    // Check if user has permission to edit this user
    if (!isSuperAdmin && !isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have permission to edit users')),
        );
      }
      return;
    }

    // If admin (not super admin), check if they're editing someone in their company
    if (isAdmin && !isSuperAdmin) {
      if (currentUser.businessId != user.businessId) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only edit users in your company')),
          );
        }
        return;
      }
    }

    // Show a dialog to edit user role
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) {
        String selectedRole = user.role;
        return AlertDialog(
          title: Text('Edit User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Editing role for ${user.fullName}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: [
                  const DropdownMenuItem(value: 'user', child: Text('User')),
                  const DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  if (isSuperAdmin)
                    const DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedRole = value;
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(selectedRole),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    // If user pressed Save and selected a new role
    if (newRole != null && newRole != user.role) {
      try {
        // Update user role directly in the users table
        await _supabase
            .from('users')
            .update({'role': newRole})
            .eq('id', user.id);

        // Refresh the user list
        _refreshUsers();
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User role updated successfully')),
          );
        }
      } catch (e) {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating user role: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: const Text('Manage Users'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
          ),
        ],
      ),
      body: FutureBuilder<List<girscope_user.User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final users = snapshot.data ?? [];
          _allUsers = users;
          _updateFilteredUsers();

          if (users.isEmpty) {
            return const Center(
              child: Text('No users found in your company.'),
            );
          }

          return Column(
            children: [
              // Search and filter section
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search users by name, email, or role...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _updateFilteredUsers();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Results count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${_filteredUsers.length} of ${users.length} users',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _updateFilteredUsers();
                              });
                            },
                            child: const Text('Clear', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Users table
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataTextStyle: const TextStyle(fontSize: 13),
                    headingTextStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    columns: [
                      DataColumn(
                        label: const Text('Name'),
                        onSort: (columnIndex, ascending) => _sortByColumn('name'),
                      ),
                      DataColumn(
                        label: const Text('Email'),
                        onSort: (columnIndex, ascending) => _sortByColumn('email'),
                      ),
                      DataColumn(
                        label: const Text('Role'),
                        onSort: (columnIndex, ascending) => _sortByColumn('role'),
                      ),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: _filteredUsers.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    user.fullName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              user.email,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user.role),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _editUser(user),
                              tooltip: 'Edit user role',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'manager':
        return Colors.blue;
      case 'user':
      default:
        return Colors.grey;
    }
  }
}
