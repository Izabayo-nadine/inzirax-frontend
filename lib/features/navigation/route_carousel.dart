import 'package:flutter/material.dart';
import 'package:inzirax/models/route_candidate.dart';

class RouteCarousel extends StatelessWidget {
  const RouteCarousel({
    super.key,
    required this.routes,
    required this.selected,
    required this.onSelect,
    required this.onStart,
  });
  final List<RouteCandidate> routes;
  final RouteCandidate? selected;
  final ValueChanged<RouteCandidate> onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 205,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          scrollDirection: Axis.horizontal,
          itemCount: routes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final route = routes[index];
            final chosen = selected?.id == route.id;
            return SizedBox(
              width: 285,
              child: Card(
                elevation: chosen ? 5 : 1,
                color: chosen ? Theme.of(context).colorScheme.primaryContainer : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(route),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(route.isRecommended ? 'Recommended' : route.summary, style: Theme.of(context).textTheme.titleMedium)),
                        if (route.isRecommended) const Icon(Icons.star, color: Colors.amber),
                      ]),
                      const SizedBox(height: 8),
                      Text('${route.durationMins.round()} min • ${route.distanceKm.toStringAsFixed(1)} km'),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, children: [
                        _Badge(icon: Icons.camera_alt_outlined, label: '${route.speedCameraCount} Cameras'),
                        _Badge(
                          icon: route.hasCongestion ? Icons.traffic : Icons.check_circle_outline,
                          label: route.hasCongestion ? 'Congested' : 'Clear',
                          color: route.hasCongestion ? Colors.orange : Colors.green,
                        ),
                      ]),
                      const Spacer(),
                      if (chosen) SizedBox(width: double.infinity, child: FilledButton(onPressed: onStart, child: const Text('Start Navigation'))),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(label),
        visualDensity: VisualDensity.compact,
      );
}
