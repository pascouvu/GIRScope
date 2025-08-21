import 'package:flutter/material.dart';
import 'package:girscope/models/site.dart';

class SiteCard extends StatefulWidget {
  final Site site;
  final bool compact;

  const SiteCard({super.key, required this.site, this.compact = false});

  @override
  State<SiteCard> createState() => _SiteCardState();
}

class _SiteCardState extends State<SiteCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.compact; // collapsed by default when compact is true
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(widget.compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: widget.compact ? 16 : 20,
                  ),
                ),
                SizedBox(width: widget.compact ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.site.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: widget.compact ? 14 : null,
                        ),
                      ),
                      SizedBox(height: widget.compact ? 4 : 6),
                      Row(
                        children: [
                          Icon(
                            Icons.gps_fixed,
                            size: widget.compact ? 12 : 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          SizedBox(width: widget.compact ? 4 : 6),
                          Text(
                            widget.site.coordinates,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: widget.compact ? 12 : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: _toggleExpanded,
                  tooltip: _expanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),
            if (_expanded && (widget.site.tanks.isNotEmpty || widget.site.pumps.isNotEmpty || widget.site.controllers.isNotEmpty)) ...[
              SizedBox(height: widget.compact ? 10 : 16),
              const Divider(),
              SizedBox(height: widget.compact ? 10 : 16),
            ],
            if (_expanded && widget.site.tanks.isNotEmpty) ...[
              _buildTankSection(context, widget.site.tanks),
              SizedBox(height: widget.compact ? 8 : 12),
            ],
            if (_expanded && widget.site.pumps.isNotEmpty) ...[
              _buildPumpSection(context, widget.site.pumps),
              SizedBox(height: widget.compact ? 8 : 12),
            ],
            if (_expanded && widget.site.controllers.isNotEmpty) ...[
              _buildControllerSection(context, widget.site.controllers),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTankSection(BuildContext context, List<Tank> tanks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.water_drop,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tanks',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: tanks.map((tank) {
            final vol = tank.volume != null ? '${tank.volume!.toStringAsFixed(0)}L' : '—';
            final capacity = tank.capacity != null ? '${tank.capacity!.toStringAsFixed(0)}L' : '—';
            final product = tank.product?.name ?? 'Unknown';
            final date = tank.volumeDate != null ? tank.volumeDate!.toLocal().toString() : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tank.name} — $product',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$vol / $capacity', style: Theme.of(context).textTheme.bodySmall),
                      if (date.isNotEmpty) Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPumpSection(BuildContext context, List<Pump> pumps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_gas_station,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Pumps',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: pumps.map((pump) {
            final product = pump.product?.name ?? 'Unknown';
            final tank = pump.tank?.name ?? '';
            final state = pump.pumping ? 'Pumping' : (pump.blocked ? 'Blocked' : (pump.manual ? 'Manual' : 'Idle'));
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pump.name, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$product${tank.isNotEmpty ? ' • $tank' : ''}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(state, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildControllerSection(BuildContext context, List<Controller> controllers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.settings,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Controllers',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: controllers.map((c) {
            final online = c.online == true;
            final date = c.date != null ? c.date!.toLocal().toString() : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(online ? Icons.radio_button_on : Icons.radio_button_off, color: online ? Colors.green : Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c.name, style: Theme.of(context).textTheme.bodyMedium)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (c.sn != null && c.sn!.isNotEmpty) Text(c.sn!, style: Theme.of(context).textTheme.bodySmall),
                      if (date.isNotEmpty) Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}