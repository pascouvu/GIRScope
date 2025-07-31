# GIRScope

GIRScope is a read-only mobile app for the GIR W150 fuel management system, built with Flutter. It allows users to view data about sites, drivers, vehicles, and anomalies from the GIR W150 system.

## Features

*   **Sites Tab:** View a list of sites with their tanks, pumps, and controllers.
*   **Drivers Tab:** Search and filter a list of drivers by department.
*   **Vehicles Tab:** View a list of vehicles with their details, including odometer, hour meter, and fuel products.
*   **Anomalies Tab:** View a list of fuel transaction anomalies with date range filtering and color-coded anomaly types.
*   **Pull-to-refresh:** Refresh the data on all tabs.
*   **Modern UI:** A modern, card-based design with Material 3 components.
*   **Dark/Light Theme:** Support for both dark and light themes.

## Technical Stack

*   **Framework:** Flutter
*   **Language:** Dart
*   **API:** REST API
*   **Dependencies:**
    *   `http` for making HTTP requests
    *   `intl` for date formatting
    *   `supabase_flutter` for Supabase integration
    *   `google_fonts` for custom fonts

## Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/GIRScope.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run
    ```

## File Structure

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