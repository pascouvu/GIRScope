# Multi-Company Architecture Implementation

## Overview

This document outlines the complete multi-company (multi-tenant) architecture implementation for the GIRScope application. The system is designed to support multiple businesses/companies using the same application instance while maintaining complete data isolation.

## Database Schema

### Core Business Structure

#### 1. Businesses Table
```sql
CREATE TABLE businesses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL,
    business_code CHAR(5) UNIQUE,
    logo_url TEXT,
    api_key VARCHAR(255) NOT NULL,
    api_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 2. Users Table
```sql
CREATE TABLE users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    business_id UUID REFERENCES businesses(id) ON DELETE SET NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'manager', 'admin', 'superadmin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Operational Tables with Business Isolation

All operational tables include a `business_id` column for data isolation:

- `vehicles` - Vehicle fleet management
- `drivers` - Driver management
- `fuel_transactions` - Fuel consumption tracking
- `products` - Product catalog (fuel types, etc.)
- `sites` - Site/location management
- `pumps` - Fuel pump management
- `tanks` - Fuel tank management
- `controllers` - Controller management
- `vehicle_products` - Vehicle-product relationships
- `departments` - Department management

## Row Level Security (RLS) Implementation

### Policy Structure

Each table has two types of RLS policies:

1. **Business-Specific Policies**: Users can only access data from their assigned business
2. **Superadmin Policies**: Superadmins can access all data across all businesses

### Example RLS Policy
```sql
-- Users can view vehicles in their business
CREATE POLICY "Users can view vehicles in their business" ON vehicles
    FOR SELECT USING (
        business_id = (
            SELECT business_id FROM users WHERE id = auth.uid()
        )
    );
```

## User Roles and Permissions

### Role Hierarchy
1. **user** - Basic user, can view data in their business
2. **manager** - Can manage data in their business
3. **admin** - Full business management capabilities
4. **superadmin** - Can access and manage all businesses

### Business Assignment
- Users are assigned to a specific business via the `business_id` field
- During registration, users can be assigned via `business_code`
- Superadmins can manage users across all businesses

## Application Flow

### 1. User Authentication
```dart
// User logs in and gets their business context
User user = await authService.getCurrentUser();
Business business = await businessService.getBusiness(user.businessId);
```

### 2. Data Access
```dart
// All data queries automatically filter by business_id via RLS
List<Vehicle> vehicles = await supabaseService.getVehicles();
// Only returns vehicles for the user's business
```

### 3. Business Context
```dart
// The app maintains business context throughout the session
class BusinessContext {
  final String businessId;
  final String businessName;
  final String apiKey;
  final String apiUrl;
}
```

## API Integration

### Business-Specific API Configuration
Each business has its own:
- `api_key` - For external API authentication
- `api_url` - For external API endpoints
- `business_code` - For business identification

### Data Synchronization
```dart
// Sync data for the specific business
await iecApiService.syncVehicles(business.apiUrl, business.apiKey);
await iecApiService.syncDrivers(business.apiUrl, business.apiKey);
await iecApiService.syncFuelTransactions(business.apiUrl, business.apiKey);
```

## Security Considerations

### Data Isolation
- RLS ensures complete data isolation between businesses
- Users cannot access data from other businesses
- All queries automatically filter by business_id

### API Security
- Each business has its own API credentials
- API calls are scoped to the specific business
- No cross-business data leakage possible

### User Management
- Business admins can only manage users within their business
- Superadmins can manage all users and businesses
- User registration can be restricted by business_code

## Implementation Checklist

### Database Changes
- [x] Add `business_id` columns to all operational tables
- [x] Create foreign key constraints
- [x] Enable RLS on all tables
- [x] Create RLS policies for business isolation
- [x] Create RLS policies for superadmin access

### Model Updates
- [x] Update all Dart models to include `businessId` field
- [x] Update JSON serialization/deserialization
- [x] Create new models for missing entities (Department, Product, VehicleProduct)

### Application Logic
- [ ] Update services to handle business context
- [ ] Update API calls to use business-specific credentials
- [ ] Update UI to show business context
- [ ] Implement business switching for superadmins

### Testing
- [ ] Test data isolation between businesses
- [ ] Test user permissions and access control
- [ ] Test API integration with business-specific credentials
- [ ] Test superadmin functionality

## Migration Strategy

### Phase 1: Database Migration
1. Run the `add_business_id_to_tables.sql` script
2. Update existing data to assign business_id values
3. Test RLS policies

### Phase 2: Application Updates
1. Update all models and services
2. Test business context throughout the app
3. Update UI components

### Phase 3: Testing and Deployment
1. Comprehensive testing of multi-company functionality
2. User acceptance testing
3. Production deployment

## Best Practices

### Data Management
- Always include business_id in data operations
- Use RLS policies for automatic filtering
- Implement proper error handling for business context

### Performance
- Index business_id columns for better query performance
- Consider partitioning large tables by business_id
- Monitor query performance with RLS enabled

### Security
- Regularly audit RLS policies
- Monitor for unauthorized access attempts
- Implement proper logging for business operations

## Troubleshooting

### Common Issues
1. **Data not showing**: Check if user has proper business_id assignment
2. **RLS policy errors**: Verify policy syntax and user permissions
3. **API integration issues**: Ensure correct business-specific credentials

### Debug Queries
```sql
-- Check user's business assignment
SELECT u.id, u.email, u.business_id, b.business_name 
FROM users u 
LEFT JOIN businesses b ON u.business_id = b.id 
WHERE u.id = auth.uid();

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'vehicles';
```
