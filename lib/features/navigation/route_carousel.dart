import 'package:flutter/material.dart';
import 'package:inzirax/models/route_candidate.dart';

const _bg = Color(0xff0d0f14);
const _surface = Color(0xff161b22);
const _surfaceVar = Color(0xff1e2530);
const _border = Color(0xff30363d);
const _primary = Color(0xff6c63ff);
const _secondary = Color(0xff00d4aa);
const _textDim = Color(0xff8b949e);
const _warning = Color(0xffff9f43);

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
        height: 210,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          scrollDirection: Axis.horizontal,
          itemCount: routes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final route = routes[index];
            final chosen = selected?.id == route.id;
            return _RouteCard(
              route: route,
              chosen: chosen,
              onTap: () => onSelect(route),
              onStart: chosen ? onStart : null,
            );
          },
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.chosen,
    required this.onTap,
    this.onStart,
  });
  final RouteCandidate route;
  final bool chosen;
  final VoidCallback onTap;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 280,
        decoration: BoxDecoration(
          color: chosen
              ? const Color(0xff1a1840)
              : _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: chosen ? _primary : _border,
            width: chosen ? 1.5 : 1,
          ),
          boxShadow: chosen
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                if (route.isRecommended) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _secondary.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star_rounded,
                            size: 12, color: _secondary),
                        SizedBox(width: 4),
                        Text('Best route',
                            style: TextStyle(
                                color: _secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ] else
                  Text(
                    route.summary,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const Spacer(),
                if (chosen)
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: _primary),
              ],
            ),
            const SizedBox(height: 10),

            // duration + distance
            Row(
              children: [
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: '${route.durationMins.round()} min',
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.straighten_rounded,
                  label: '${route.distanceKm.toStringAsFixed(1)} km',
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // badges
            Row(
              children: [
                _Badge(
                  icon: Icons.camera_alt_outlined,
                  label: '${route.speedCameraCount} Cams',
                  color: route.speedCameraCount > 0
                      ? _warning
                      : _secondary,
                ),
                const SizedBox(width: 6),
                _Badge(
                  icon: route.hasCongestion
                      ? Icons.traffic_rounded
                      : Icons.check_circle_outline_rounded,
                  label: route.hasCongestion ? 'Congested' : 'Clear',
                  color:
                      route.hasCongestion ? const Color(0xffff6b6b) : _secondary,
                ),
              ],
            ),

            const Spacer(),

            // start button only on selected
            if (onStart != null)
              SizedBox(
                width: double.infinity,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff6c63ff), Color(0xff9b59b6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: onStart,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation_rounded,
                            size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Start Navigation',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textDim),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
