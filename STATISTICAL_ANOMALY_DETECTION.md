# Statistical Anomaly Detection System

## Overview

The new statistical anomaly detection system analyzes fuel transaction patterns to identify incoherent data within selected periods compared to usual historical data. This replaces the previous simple rule-based approach with sophisticated statistical analysis.

## Key Features

### 1. Historical Pattern Analysis
- **Baseline Period**: Uses 90 days of historical data as baseline for comparison
- **Minimum Samples**: Requires at least 5 historical samples for reliable statistical analysis
- **Vehicle-Specific**: Each vehicle's patterns are analyzed independently

### 2. Statistical Anomaly Types

#### Consumption Anomalies
- Analyzes fuel consumption (L/100km) patterns
- Compares current consumption against historical average
- Detects both unusually high and low consumption rates

#### Volume Anomalies
- Analyzes fuel volume patterns per transaction
- Identifies unusually large or small fuel volumes
- Considers vehicle-specific fueling patterns

#### Frequency Anomalies
- Analyzes time intervals between fueling events
- Detects unusually long or short periods between fuelings
- Helps identify irregular fueling schedules

#### Timing Anomalies
- Analyzes hour-of-day fueling patterns
- Identifies fueling at unusual times compared to historical patterns
- Useful for detecting after-hours or irregular fueling

### 3. Severity Classification

Each anomaly is classified by severity based on statistical deviation:

- **Critical**: ≥3.0 standard deviations from mean
- **High**: ≥2.5 standard deviations from mean
- **Medium**: ≥2.0 standard deviations from mean
- **Low**: <2.0 standard deviations from mean

### 4. Z-Score Analysis

The system calculates Z-scores for each metric:
```
Z-Score = (Actual Value - Historical Mean) / Standard Deviation
```

This provides a standardized measure of how unusual a value is compared to historical patterns.

## Implementation Details

### Core Components

1. **AnomalyDetectionService** (`lib/services/anomaly_detection_service.dart`)
   - Main service for statistical analysis
   - Handles baseline calculation and anomaly detection
   - Provides detailed statistical summaries

2. **Enhanced FuelTransaction Model** (`lib/models/fuel_transaction.dart`)
   - Extended to support statistical anomalies
   - Maintains backward compatibility with traditional anomalies
   - Provides methods to merge statistical and traditional anomalies

3. **Updated UI Components**
   - **AnomaliesTab**: Toggle for statistical analysis
   - **AnomalyCard**: Displays both traditional and statistical anomalies
   - **AnomalyDetailScreen**: Detailed explanations with statistical context

### Statistical Analysis Process

1. **Data Collection**: Gather historical transactions for baseline period
2. **Statistical Calculation**: Calculate mean, standard deviation, min/max for each metric
3. **Anomaly Detection**: Compare current values against statistical thresholds
4. **Severity Assessment**: Classify anomalies based on Z-score magnitude
5. **Description Generation**: Create human-readable explanations

### Configuration Parameters

```dart
// Statistical thresholds
static const double _standardDeviationThreshold = 2.0;
static const int _minimumHistoricalSamples = 5;
static const int _baselineDays = 90; // 3 months baseline
```

## Usage

### Enabling Statistical Analysis

In the Anomalies tab, users can toggle statistical analysis on/off:

```dart
Switch(
  value: _useStatisticalAnalysis,
  onChanged: (value) {
    setState(() {
      _useStatisticalAnalysis = value;
    });
    _loadTransactions();
  },
)
```

### Viewing Statistical Anomalies

Statistical anomalies appear alongside traditional anomalies with:
- Distinct visual styling (different colors and icons)
- Severity indicators (color-coded badges)
- Detailed statistical information (Z-scores, expected vs actual values)

### Filtering by Anomaly Type

The system supports filtering by both traditional and statistical anomaly types:
- Traditional: Manual, Forced Meter, Max Volume, Meter Reset, High Consumption
- Statistical: Statistical Consumption, Statistical Volume, Statistical Frequency, Statistical Timing

## Benefits

### 1. Intelligent Detection
- Adapts to each vehicle's unique patterns
- Reduces false positives from hardcoded thresholds
- Provides context-aware anomaly detection

### 2. Detailed Insights
- Explains why something is anomalous
- Provides statistical context (Z-scores, deviations)
- Helps users understand data patterns

### 3. Scalable Analysis
- Works with any amount of historical data
- Automatically adjusts to data availability
- Gracefully handles insufficient data scenarios

### 4. Backward Compatibility
- Maintains existing traditional anomaly detection
- Users can choose between approaches
- Seamless integration with existing UI

## Example Output

### Statistical Consumption Anomaly
```
📊 Statistical Consumption Anomaly [HIGH]
Fuel consumption of 89.7 L/100km is 156% higher than the typical 35.2 L/100km for this vehicle.

Statistical Details:
Actual: 89.7    Expected: 35.2
Z-Score: 2.8 (2.8σ from mean)
```

### Statistical Volume Anomaly
```
📈 Statistical Volume Anomaly [MEDIUM]
Fuel volume of 85.2L is 47% larger than the typical 58.1L for this vehicle.

Statistical Details:
Actual: 85.2    Expected: 58.1
Z-Score: 2.1 (2.1σ from mean)
```

## Future Enhancements

1. **Machine Learning Integration**: Use ML models for more sophisticated pattern recognition
2. **Seasonal Adjustments**: Account for seasonal variations in fuel consumption
3. **Driver-Specific Analysis**: Analyze patterns by driver in addition to vehicle
4. **Predictive Anomalies**: Predict potential future anomalies based on trends
5. **Custom Thresholds**: Allow users to configure sensitivity levels
6. **Anomaly Clustering**: Group related anomalies for better insights

## Technical Notes

- The system requires sufficient historical data (minimum 5 samples) for reliable analysis
- Statistical calculations use standard statistical formulas for mean, standard deviation, and Z-scores
- The service is designed to be performant and can handle large datasets
- Error handling ensures the system gracefully falls back to traditional anomalies if statistical analysis fails

## Testing

A demo widget (`StatisticalAnomalyDemo`) is available to test the statistical analysis functionality with sample data. This helps verify the system works correctly and demonstrates the types of anomalies that can be detected.