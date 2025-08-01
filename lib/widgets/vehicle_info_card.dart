import 'package:flutter/material.dart';
import 'package:girscope/models/vehicle.dart';

class VehicleInfoCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleInfoCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.blue, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  vehicle.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Badge', vehicle.displayBadge),
          _buildInfoRow('Model', vehicle.model),
          _buildInfoRow('Department', vehicle.departmentName),
          if (vehicle.odometer != null)
            _buildInfoRow('Odometer', '${vehicle.odometer!.toStringAsFixed(0)} km'),
          if (vehicle.hourMeter != null)
            _buildInfoRow('Hour Meter', '${vehicle.hourMeter!.toStringAsFixed(1)} h'),
          if (vehicle.vtanks.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Fuel Tanks:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            ...vehicle.vtanks.map((vtank) => Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vtank.product.isEmpty ? 'Unknown Product' : vtank.product,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (vtank.capacity != null) ...[
                    const Text(' - ', style: TextStyle(fontSize: 12)),
                    Text(
                      '${vtank.capacity!.toStringAsFixed(0)}L',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}