# GIRViewer - Architecture & Implementation Plan

## Overview
GIRScope is a read-only mobile app built with Flutter/Dart that connects to the GIR W150 fuel management system via REST API. The app displays fuel management data across four main tabs: Sites, Drivers, Vehicles, and Anomalies.

## Technical Architecture

### API Configuration
- Base URL: `https://pierre-brunet-entreprise-vu-gir.klervi.net/api-impexp/`
- Authentication: Header `X-Klervi-API-Key: c08951d341ca7c8b2d034c8d05ca8537`
- All endpoints are GET requests for read-only access

### Core Endpoints
1. **Sites**: `/rcm/sites` - Site information with tanks, pumps, controllers
2. **Drivers**: `/drivers` - Driver details with search/filter capabilities
3. **Vehicles**: `/vehicles` - Vehicle data with fuel usage information
4. **Anomalies**: `/transac_fuels` - Transaction anomalies with date filtering

### File Structure
```
/lib
├── models/
│   ├── site.dart
│   ├── driver.dart
│   ├── vehicle.dart
│   └── fuel_transaction.dart
├── services/
│   └── api_service.dart
├── views/
│   ├── home_screen.dart
│   ├── sites_tab.dart
│   ├── drivers_tab.dart
│   ├── vehicles_tab.dart
│   └── anomalies_tab.dart
├── widgets/
│   ├── site_card.dart
│   ├── driver_card.dart
│   ├── vehicle_card.dart
│   └── anomaly_card.dart
├── theme.dart
└── main.dart
```

## Implementation Features

### 1. Sites Tab
- Display site cards with name and GPS coordinates
- Show tanks (name & volume), pumps, and controllers
- Pull-to-refresh functionality

### 2. Drivers Tab
- Searchable driver list with department filtering
- Driver cards showing name, badge, code, department
- Chip-based department filters

### 3. Vehicles Tab
- Vehicle cards with name, badge/code, department, model
- Odometer and hour meter display
- Fuel products (vtanks) list
- Search bar with department/model filters

### 4. Anomalies Tab
- Date range filters (3 days, 7 days, 30 days, custom)
- Color-coded anomaly types:
  - 🟠 Manual fueling
  - 🔴 Forced meter
  - ⚪ Max volume reached
  - 🟡 Odometer/hmeter reset
  - 🟣 High consumption
- Pagination support with infinite scroll
- Detailed anomaly cards with vehicle, driver, site info

## UI/UX Design Principles
- Modern card-based design with rounded corners
- Color-coded tags for different data types
- Smooth animations and transitions
- Material 3 design system
- Dark/light theme support
- Intuitive search and filtering
- Pull-to-refresh on all tabs

## Error Handling
- Network error states with retry buttons
- Loading indicators during API calls
- Empty state designs for no data
- Offline capability considerations

## Performance Optimizations
- Lazy loading for large lists
- Pagination for anomalies data
- Efficient search implementation
- Minimal API calls with caching strategies