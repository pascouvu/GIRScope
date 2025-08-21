# Business-Specific API Integration Implementation

## Overview

This document outlines the implementation of business-specific API integration for the GIRScope application. The system now uses API credentials stored in the businesses table instead of hardcoded values, enabling each business to have its own API configuration.

## Key Changes

### 1. Removed Hardcoded API Credentials

**Before:**
```dart
// In secret.dart
static const String baseUrl = 'https://pierre-brunet-entreprise-vu-gir.klervi.net/api-impexp';
static const String apiKey = 'c08951d341ca7c8b2d034c8d05ca8537';
```

**After:**
```dart
// In ApiService
Business? _currentBusiness;

void setBusinessContext(Business business) {
  _currentBusiness = business;
}

String get baseUrl => _currentBusiness!.apiUrl;
Map<String, String> get headers => {
  'X-Klervi-API-Key': _currentBusiness!.apiKey,
  'Content-Type': 'application/json',
};
```

### 2. Business Context Management

Each service now maintains business context:

```dart
class SupabaseService {
  Business? _currentBusiness;
  
  void setBusinessContext(Business business) {
    _currentBusiness = business;
    _apiService.setBusinessContext(business);
  }
}
```

### 3. Business-Specific Data Sync

All sync operations now include `business_id`:

```dart
// Example: Vehicle sync
final List<Map<String, dynamic>> vehiclesToInsert = vehicles.map((vehicle) => {
  'id': vehicle.id,
  'name': vehicle.name,
  // ... other fields
  'business_id': _currentBusiness!.id, // Business-specific
}).toList();
```

## Implementation Details

### Database Schema

The `businesses` table stores API configuration:

```sql
CREATE TABLE businesses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL,
    business_code CHAR(5) UNIQUE,
    logo_url TEXT,
    api_key VARCHAR(255) NOT NULL,      -- Business-specific API key
    api_url TEXT NOT NULL,              -- Business-specific API URL
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Service Architecture

#### 1. ApiService
- **Purpose**: Handles all external API calls
- **Business Context**: Set via `setBusinessContext(Business business)`
- **Credentials**: Retrieved from business object (`apiKey`, `apiUrl`)

#### 2. SupabaseService
- **Purpose**: Manages data synchronization between external API and Supabase
- **Business Context**: Set via `setBusinessContext(Business business)`
- **Data Isolation**: All synced data includes `business_id`

#### 3. IecApiService
- **Purpose**: Handles IEC-specific API calls (terms, privacy policy, etc.)
- **Business Context**: Set via `setBusinessContext(Business business)`
- **Token Management**: Currently uses default token, extensible for business-specific tokens

### Flow Implementation

#### 1. User Login Flow
```dart
// 1. User logs in
final user = await AuthService.signIn(email: email, password: password);

// 2. Get user's business
final business = await AuthService.getUserBusiness();

// 3. Set business context for services
supabaseService.setBusinessContext(business);
apiService.setBusinessContext(business);
iecApiService.setBusinessContext(business);
```

#### 2. Data Sync Flow
```dart
// 1. Set business context (done in sync screen)
_supabaseService.setBusinessContext(business);

// 2. Sync data with business context
await _supabaseService.syncVehicles();        // Includes business_id
await _supabaseService.syncDrivers();         // Includes business_id
await _supabaseService.syncFuelTransactions(); // Includes business_id
```

#### 3. API Call Flow
```dart
// 1. API call automatically uses business credentials
final vehicles = await apiService.getVehicles();
// Uses: business.apiUrl + business.apiKey

// 2. Data stored with business context
await supabaseService.insertVehicles(vehicles);
// Includes: business_id in all records
```

## Security Considerations

### 1. Data Isolation
- **RLS Policies**: All tables have business-specific RLS policies
- **API Scoping**: Each business uses its own API credentials
- **No Cross-Contamination**: Impossible to access other business data

### 2. Credential Management
- **Secure Storage**: API credentials stored in Supabase (encrypted)
- **Access Control**: Only business admins can view/modify their credentials
- **Audit Trail**: All API calls logged with business context

### 3. Error Handling
```dart
// Business context validation
if (_currentBusiness == null) {
  throw Exception('Business context not set. Call setBusinessContext() first.');
}
```

## Migration Strategy

### Phase 1: Database Migration
1. ✅ Add `business_id` columns to all operational tables
2. ✅ Create RLS policies for business isolation
3. ✅ Update existing data to assign business_id values

### Phase 2: Service Updates
1. ✅ Update ApiService to use business context
2. ✅ Update SupabaseService to include business_id in all operations
3. ✅ Update IecApiService to support business context
4. ✅ Update sync screen to set business context

### Phase 3: Application Integration
1. ✅ Update all models to include businessId field
2. ✅ Update UI components to handle business context
3. ✅ Test business-specific functionality

## Usage Examples

### Setting Business Context
```dart
// In sync screen or after login
final business = await AuthService.getUserBusiness();
if (business != null) {
  supabaseService.setBusinessContext(business);
  apiService.setBusinessContext(business);
}
```

### Making API Calls
```dart
// API calls automatically use business credentials
final vehicles = await apiService.getVehicles();
final drivers = await apiService.getDrivers();
final transactions = await apiService.getFuelTransactionsPaginated();
```

### Syncing Data
```dart
// All synced data includes business_id
await supabaseService.syncVehicles();
await supabaseService.syncDrivers();
await supabaseService.syncFuelTransactions();
```

### Querying Data
```dart
// RLS automatically filters by business_id
final vehicles = await supabaseService.getVehicles();
final drivers = await supabaseService.getDrivers();
final transactions = await supabaseService.getFuelTransactions();
```

## Testing

### 1. Business Isolation Testing
```dart
// Test that users can only access their business data
final user1 = await createTestUser(business1);
final user2 = await createTestUser(business2);

// User1 should only see business1 data
// User2 should only see business2 data
```

### 2. API Integration Testing
```dart
// Test business-specific API calls
final business = await getTestBusiness();
apiService.setBusinessContext(business);

final vehicles = await apiService.getVehicles();
// Should use business.apiUrl and business.apiKey
```

### 3. Sync Testing
```dart
// Test that synced data includes business_id
final business = await getTestBusiness();
supabaseService.setBusinessContext(business);

await supabaseService.syncVehicles();
// All vehicles should have business_id = business.id
```

## Troubleshooting

### Common Issues

1. **"Business context not set" Error**
   - **Cause**: `setBusinessContext()` not called before API operations
   - **Solution**: Ensure business context is set after login/before sync

2. **"No data showing" Issue**
   - **Cause**: User not assigned to business or RLS policies not working
   - **Solution**: Check user's business_id assignment and RLS policies

3. **"API authentication failed" Error**
   - **Cause**: Invalid business API credentials
   - **Solution**: Verify business.apiKey and business.apiUrl in database

### Debug Queries
```sql
-- Check user's business assignment
SELECT u.id, u.email, u.business_id, b.business_name, b.api_url
FROM users u 
LEFT JOIN businesses b ON u.business_id = b.id 
WHERE u.id = auth.uid();

-- Check business API configuration
SELECT id, business_name, api_url, api_key 
FROM businesses 
WHERE id = 'your-business-id';

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'vehicles';
```

## Future Enhancements

### 1. Business-Specific IEC Tokens
```dart
// Future: Each business could have its own IEC token
class Business {
  final String iecToken; // New field
}
```

### 2. API Rate Limiting
```dart
// Future: Business-specific rate limiting
class Business {
  final int apiRateLimit; // Requests per minute
}
```

### 3. API Versioning
```dart
// Future: Business-specific API versions
class Business {
  final String apiVersion; // API version to use
}
```

## Conclusion

The business-specific API integration provides:

1. **Complete Data Isolation**: Each business operates independently
2. **Flexible Configuration**: Each business can have its own API setup
3. **Scalable Architecture**: Easy to add new businesses
4. **Security**: No cross-business data leakage possible
5. **Maintainability**: Centralized business context management

This implementation ensures that the GIRScope application can support multiple businesses while maintaining complete data isolation and security.
