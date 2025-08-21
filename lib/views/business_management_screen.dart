import 'dart:math';
import 'package:flutter/material.dart';
import 'package:girscope/models/business.dart';
import 'package:girscope/services/auth_service.dart';
import 'package:girscope/services/file_upload_service.dart';
import 'package:girscope/widgets/responsive_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  State<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen> {
  late Future<List<Business>> _businessesFuture;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Search and sorting state
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'api_url'
  bool _sortAscending = true;
  
  // Filtered and sorted businesses
  List<Business> _allBusinesses = [];
  List<Business> _filteredBusinesses = [];

  @override
  void initState() {
    super.initState();
    _businessesFuture = _fetchBusinesses();
  }

  Future<List<Business>> _fetchBusinesses() async {
    print('*** DEBUG: BusinessManagementScreen._fetchBusinesses started');
    try {
      // Get current user's profile to check role
      final currentUser = await AuthService.getUserProfile();
      print('*** DEBUG: BusinessManagementScreen current user: ${currentUser?.fullName} with role ${currentUser?.role}');
      
      if (currentUser == null) {
        print('*** DEBUG: BusinessManagementScreen no current user');
        return [];
      }

      // Only super admins should be able to see all businesses
      final userRole = currentUser.role.trim().toLowerCase();
      final isSuperAdmin = userRole == 'superadmin';
      
      if (!isSuperAdmin) {
        print('*** DEBUG: BusinessManagementScreen user is not super admin, cannot view all businesses');
        return [];
      }

      print('*** DEBUG: BusinessManagementScreen user is super admin - fetching all businesses');
      final response = await _supabase
          .from('businesses')
          .select('id, business_name, api_key, api_url, created_at, updated_at, logo_url')
          .order('business_name');
      
      print('*** DEBUG: BusinessManagementScreen fetched businesses count: ${response.length}');
      
      return response.map((e) => Business.fromJson(e)).toList();
    } catch (e, stackTrace) {
      print('*** DEBUG: BusinessManagementScreen error fetching businesses: $e');
      print('*** DEBUG: BusinessManagementScreen stack trace: $stackTrace');
      // Handle error
      return [];
    }
  }

  Future<void> _refreshBusinesses() async {
    setState(() {
      _businessesFuture = _fetchBusinesses();
    });
  }

  void _updateFilteredBusinesses() {
    // Filter businesses based on search query
    _filteredBusinesses = _allBusinesses.where((business) {
      final query = _searchQuery.toLowerCase();
      return business.businessName.toLowerCase().contains(query) ||
             business.apiUrl.toLowerCase().contains(query);
    }).toList();

    // Sort businesses
    _filteredBusinesses.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.businessName.compareTo(b.businessName);
          break;
        case 'api_url':
          comparison = a.apiUrl.compareTo(b.apiUrl);
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
      _updateFilteredBusinesses();
    });
  }

  String _maskApiKey(String apiKey) {
    if (apiKey.length <= 4) return apiKey;
    return '${apiKey.substring(0, 4)}...';
  }

  String _truncateApiUrl(String apiUrl) {
    if (apiUrl.length <= 10) return apiUrl;
    return '${apiUrl.substring(0, 10)}...';
  }

  Future<void> _createBusiness() async {
    // Show a dialog to create a new business
    await showDialog(
      context: context,
      builder: (context) {
        return const _CreateBusinessDialog();
      },
    );

    // Refresh the business list after creating a new business
    _refreshBusinesses();
  }

  Future<void> _editBusiness(Business business) async {
    // Show a dialog to edit an existing business
    await showDialog(
      context: context,
      builder: (context) {
        return _EditBusinessDialog(business: business);
      },
    );

    // Refresh the business list after editing
    _refreshBusinesses();
  }

  Future<void> _deleteBusiness(Business business) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Business'),
        content: Text('Are you sure you want to delete "${business.businessName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase
            .from('businesses')
            .delete()
            .eq('id', business.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Business "${business.businessName}" deleted successfully')),
          );
        }

        // Refresh the business list
        _refreshBusinesses();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting business: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: const Text('Business Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createBusiness,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBusinesses,
          ),
        ],
      ),
      body: FutureBuilder<List<Business>>(
        future: _businessesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final businesses = snapshot.data ?? [];
          _allBusinesses = businesses;
          _updateFilteredBusinesses();

          if (businesses.isEmpty) {
            return const Center(
              child: Text('No businesses found.'),
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
                        hintText: 'Search businesses by name or API URL...',
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
                          _updateFilteredBusinesses();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Results count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${_filteredBusinesses.length} of ${businesses.length} businesses',
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
                                _updateFilteredBusinesses();
                              });
                            },
                            child: const Text('Clear', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Businesses table
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
                        label: const Text('Business'),
                        onSort: (columnIndex, ascending) => _sortByColumn('name'),
                      ),
                      DataColumn(
                        label: const Text('API Key'),
                      ),
                      DataColumn(
                        label: const Text('API URL'),
                        onSort: (columnIndex, ascending) => _sortByColumn('api_url'),
                      ),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: _filteredBusinesses.map((business) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  backgroundImage: business.logoUrl != null
                                      ? NetworkImage(business.logoUrl!)
                                      : null,
                                  child: business.logoUrl == null
                                      ? Text(
                                          business.businessName.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    business.businessName,
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _maskApiKey(business.apiKey),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 16),
                                  onPressed: () {
                                    _showApiKeyDialog(business);
                                  },
                                  tooltip: 'View API Key',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _truncateApiUrl(business.apiUrl),
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  onPressed: () {
                                    _showApiUrlDialog(business);
                                  },
                                  tooltip: 'View full URL',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  onPressed: () => _editBusiness(business),
                                  tooltip: 'Edit business',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  onPressed: () => _deleteBusiness(business),
                                  tooltip: 'Delete business',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
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

  void _showApiKeyDialog(Business business) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business: ${business.businessName}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                business.apiKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showApiUrlDialog(Business business) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business: ${business.businessName}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                business.apiUrl,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _CreateBusinessDialog extends StatefulWidget {
  const _CreateBusinessDialog();

  @override
  State<_CreateBusinessDialog> createState() => _CreateBusinessDialogState();
}

class _CreateBusinessDialogState extends State<_CreateBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _apiUrlController = TextEditingController();
  XFile? _selectedImage;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await FileUploadService.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Validate the image
        final isValid = await FileUploadService.validateImage(image);
        if (!isValid) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid image file (JPG, PNG, GIF, WebP) under 5MB'),
              ),
            );
          }
          return;
        }
        
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? logoUrl;
      if (_selectedImage != null) {
        print('*** DEBUG: Uploading logo for new business');
        logoUrl = await FileUploadService.uploadImage(_selectedImage!);
        if (logoUrl == null) {
          throw Exception('Failed to upload logo');
        }
        print('*** DEBUG: Logo uploaded successfully: $logoUrl');
      }

      // Generate a random API key if not provided
      final apiKey = _apiKeyController.text.isNotEmpty
          ? _apiKeyController.text
          : _generateRandomApiKey();
      
      print('*** DEBUG: Generated API key: $apiKey');

      // Prepare insert data
      final Map<String, dynamic> insertData = {
        'business_name': _businessNameController.text,
        'api_key': apiKey,
        'api_url': _apiUrlController.text,
      };
      
      if (logoUrl != null) {
        insertData['logo_url'] = logoUrl;
      }
      
      print('*** DEBUG: Inserting new business with data: $insertData');

      // Insert new business
      final response = await _supabase.from('businesses').insert(insertData);
      print('*** DEBUG: Insert response: $response');

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business created successfully')),
        );
      }
    } catch (e, stackTrace) {
      print('*** DEBUG: Error creating business: $e');
      print('*** DEBUG: Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating business: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateRandomApiKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return List.generate(32, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Business'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiUrlController,
                decoration: const InputDecoration(
                  labelText: 'API URL',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an API URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Select Logo'),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedImage != null)
                    Text(path.basename(_selectedImage!.path))
                  else
                    const Text('No image selected'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _EditBusinessDialog extends StatefulWidget {
  final Business business;

  const _EditBusinessDialog({required this.business});

  @override
  State<_EditBusinessDialog> createState() => _EditBusinessDialogState();
}

class _EditBusinessDialogState extends State<_EditBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _apiUrlController;
  XFile? _selectedImage;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.business.businessName);
    _apiKeyController = TextEditingController(text: widget.business.apiKey);
    _apiUrlController = TextEditingController(text: widget.business.apiUrl);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await FileUploadService.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Validate the image
        final isValid = await FileUploadService.validateImage(image);
        if (!isValid) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid image file (JPG, PNG, GIF, WebP) under 5MB'),
              ),
            );
          }
          return;
        }
        
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? logoUrl = widget.business.logoUrl;
      if (_selectedImage != null) {
        print('*** DEBUG: Uploading new logo');
        logoUrl = await FileUploadService.uploadImage(_selectedImage!);
        if (logoUrl == null) {
          throw Exception('Failed to upload logo');
        }
        print('*** DEBUG: Logo uploaded successfully: $logoUrl');
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'business_name': _businessNameController.text,
        'api_key': _apiKeyController.text,
        'api_url': _apiUrlController.text,
      };
      
      // Only update logo_url if it's different
      if (logoUrl != null && logoUrl != widget.business.logoUrl) {
        updateData['logo_url'] = logoUrl;
      }
      
      print('*** DEBUG: Updating business with data: $updateData');
      
      // Update business
      final response = await _supabase.from('businesses').update(updateData).eq('id', widget.business.id);
      print('*** DEBUG: Update response: $response');
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business updated successfully')),
        );
      }
    } catch (e, stackTrace) {
      print('*** DEBUG: Error updating business: $e');
      print('*** DEBUG: Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating business: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Business'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiUrlController,
                decoration: const InputDecoration(
                  labelText: 'API URL',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an API URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Select Logo'),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedImage != null)
                    Text(path.basename(_selectedImage!.path))
                  else if (widget.business.logoUrl != null)
                    const Text('Using existing logo')
                  else
                    const Text('No image selected'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}