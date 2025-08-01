import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:intl/intl.dart';

class RefuelingCard extends StatelessWidget {
  final FuelTransaction transaction;

  const RefuelingCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header: Date + Time on left, Volume on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateFormat('MMM dd, yyyy').format(transaction.date)} ${DateFormat('HH:mm').format(transaction.date)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${transaction.volume.toStringAsFixed(1)}L',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Compact info: Driver on left, Location on right
          Row(
            children: [
              // Driver info
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 12, color: Colors.blue),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        transaction.driverName.isEmpty ? 'Unknown Driver' : transaction.driverName,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              
              // Location info
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.red),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        transaction.siteName.isEmpty ? 'Unknown Site' : transaction.siteName,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Anomalies (if any)
          if (transaction.hasAnomalies) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 3,
              children: transaction.anomalies.map((anomaly) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${anomaly.emoji} ${anomaly.label}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.orange,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}