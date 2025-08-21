import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:girscope/models/user.dart' as girscope_user;
import 'package:girscope/models/business.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static girscope_user.User? get currentUser {
    // This is a simplified version that doesn't fetch from database
    // For real implementation, use getUserProfile()
    return null;
  }

  // Check if user is authenticated
  static bool get isAuthenticated {
    final currentUser = _supabase.auth.currentUser;
    print('*** DEBUG: isAuthenticated check, currentUser: $currentUser');
    return currentUser != null;
  }

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String businessCode,
  }) async {
    print('*** DEBUG: Starting signup process');
    print('*** DEBUG: Business code: "$businessCode"');
    
    // First, check if email already exists in auth.users
    try {
      final existingUserResponse = await _supabase.auth.admin.listUsers();
      final existingUsers = existingUserResponse.where((user) => user.email == email).toList();
      
      if (existingUsers.isNotEmpty) {
        print('*** DEBUG: Email already exists: $email');
        throw Exception('An account with this email already exists. Please sign in instead.');
      }
    } catch (e) {
      // If admin access is not available, try alternative check
      print('*** DEBUG: Admin check failed, trying alternative method: $e');
      
      // Check if email exists in public.users (fallback method)
      try {
        final existingPublicUser = await _supabase
            .from('users')
            .select('id, email')
            .eq('email', email)
            .maybeSingle();
        
        if (existingPublicUser != null) {
          print('*** DEBUG: Email already exists in public.users: $email');
          throw Exception('An account with this email already exists. Please sign in instead.');
        }
      } catch (checkError) {
        print('*** DEBUG: Email existence check failed: $checkError');
        // Continue with signup if check fails
      }
    }
    
    // Validate the business code exists
    final businessResponse = await _supabase
        .from('businesses')
        .select('id')
        .eq('business_code', businessCode)
        .limit(1);
    
    print('*** DEBUG: Business validation response: $businessResponse');
    
    if (businessResponse.isEmpty) {
      throw Exception('Invalid business code');
    }
    
    final businessId = businessResponse.first['id'];
    print('*** DEBUG: Found business ID: $businessId');
    
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'business_code': businessCode, // Store for later use in trigger
      },
    );
    
    print('*** DEBUG: Auth signup response: ${response.user?.id}');
    
    // Wait a moment for the trigger to complete
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Verify the user record was created properly by the trigger
    if (response.user != null) {
      try {
        // Check if the user record exists and has the correct business_id
        final userRecord = await _supabase
            .from('users')
            .select('id, business_id, email, full_name')
            .eq('id', response.user!.id)
            .maybeSingle();
        
        print('*** DEBUG: User record after trigger: $userRecord');
        
        if (userRecord == null) {
          print('*** DEBUG: WARNING - User record not found after trigger');
          print('*** DEBUG: Attempting manual user creation via RPC...');
          
          // Try manual user creation using RPC function
          try {
            final rpcResult = await _supabase.rpc('create_user_manual', params: {
              'user_id': response.user!.id,
              'user_email': email,
              'user_full_name': fullName,
              'business_code': businessCode,
            });
            
            print('*** DEBUG: RPC user creation result: $rpcResult');
            
            if (rpcResult == true) {
              print('*** DEBUG: Manual user creation successful via RPC');
            } else {
              print('*** DEBUG: Manual user creation failed via RPC');
              
              // Fallback to direct insert
              try {
                final insertResult = await _supabase
                    .from('users')
                    .insert({
                      'id': response.user!.id,
                      'email': email,
                      'full_name': fullName,
                      'business_id': businessId,
                      'role': 'user',
                    })
                    .select();
                
                print('*** DEBUG: Direct user creation result: $insertResult');
                print('*** DEBUG: Direct user creation successful');
                
              } catch (directError) {
                print('*** DEBUG: Error during direct user creation: $directError');
                throw Exception('Failed to create user record. Please contact support.');
              }
            }
            
          } catch (rpcError) {
            print('*** DEBUG: Error during RPC user creation: $rpcError');
            
            // Fallback to direct insert
            try {
              final insertResult = await _supabase
                  .from('users')
                  .insert({
                    'id': response.user!.id,
                    'email': email,
                    'full_name': fullName,
                    'business_id': businessId,
                    'role': 'user',
                  })
                  .select();
              
              print('*** DEBUG: Direct user creation result: $insertResult');
              print('*** DEBUG: Direct user creation successful');
              
            } catch (directError) {
              print('*** DEBUG: Error during direct user creation: $directError');
              throw Exception('Failed to create user record. Please contact support.');
            }
          }
          
        } else if (userRecord['business_id'] == null) {
          print('*** DEBUG: WARNING - User record exists but business_id is null');
          print('*** DEBUG: Attempting to fix business_id...');
          
          // Try to update the business_id manually
          try {
            final updateResult = await _supabase
                .from('users')
                .update({'business_id': businessId})
                .eq('id', response.user!.id);
            
            print('*** DEBUG: Business_id update result: $updateResult');
            
          } catch (updateError) {
            print('*** DEBUG: Error updating business_id: $updateError');
          }
          
        } else {
          print('*** DEBUG: User record created successfully with business_id: ${userRecord['business_id']}');
        }
        
      } catch (e) {
        print('*** DEBUG: Error checking user record: $e');
        print('*** DEBUG: This may be normal if the trigger is still processing');
      }
    }
    
    return response;
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update password
  static Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Get user profile from database
  static Future<girscope_user.User?> getUserProfile() async {
    print('*** DEBUG: getUserProfile started');
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      print('*** DEBUG: getCurrentUser ID: $currentUserId');
      
      // Add authentication state debugging
      final authState = _supabase.auth.currentSession;
      print('*** DEBUG: Current auth session: $authState');
      print('*** DEBUG: Auth state is null: ${authState == null}');
      print('*** DEBUG: User is authenticated: ${isAuthenticated}');
      
      if (currentUserId == null) {
        print('*** DEBUG: No current user ID, returning null');
        return null;
      }
      
      print('*** DEBUG: About to make Supabase query');
      final response = await _supabase
          .from('users')
          .select('id, email, full_name, business_id, role, created_at, updated_at')
          .eq('id', currentUserId)
          .single();
      print('*** DEBUG: Supabase query completed, response: $response');
      
      if (response == null) {
        print('*** DEBUG: Response is null, returning null');
        return null;
      }
      
      print('*** DEBUG: Creating User object from response');
      final user = girscope_user.User.fromJson(response);
      print('*** DEBUG: User object created - fullName: ${user.fullName}, role: "${user.role}", businessId: ${user.businessId}');
      return user;
    } catch (e, stackTrace) {
      print('*** DEBUG: Error in getUserProfile: $e');
      print('*** DEBUG: Stack trace: $stackTrace');
      return null;
    } finally {
      print('*** DEBUG: getUserProfile completed');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String fullName,
    String? businessId,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    await _supabase
        .from('users')
        .update({
          'full_name': fullName,
          if (businessId != null) 'business_id': businessId,
        })
        .eq('id', currentUserId);
  }

  // Remove the updateUserRole method since we're going back to direct updates

  // Get user's business
  static Future<Business?> getUserBusiness() async {
    try {
      final user = await getUserProfile();
      if (user?.businessId == null) return null;

      final businessId = user!.businessId;
      if (businessId == null) return null;

      final response = await _supabase
          .from('businesses')
          .select()
          .eq('id', businessId)
          .single();
      
      return Business.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}

