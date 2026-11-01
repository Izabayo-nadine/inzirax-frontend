import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzirax/features/navigation/active_navigation_screen.dart';
import 'package:inzirax/features/navigation/driver_map.dart';
import 'package:inzirax/features/navigation/navigation_controller.dart';
import 'package:inzirax/features/navigation/route_carousel.dart';
import 'package:inzirax/features/settings/settings_screen.dart';
import 'package:inzirax/models/place_suggestion.dart';

// ──────────────────────────────────────────────────────────────
// CONSTANTS
// ──────────────────────────────────────────────────────────────
const _bg = Color(0xff0d0f14);
const _surface = Color(0xff161b22);
const _surfaceVar = Color(0xff1e2530);
const _border = Color(0xff30363d);
const _primary = Color(0xff6c63ff);
const _secondary = Color(0xff00d4aa);
const _textDim = Color(0xff8b949e);
const _originDot = Color(0xff00d4aa);
const _destDot = Color(0xffff9f43);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── controllers ──────────────────────────────────────────────
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  Timer? _debounce;

  // ── UI state ──────────────────────────────────────────────────
  bool _showMap = false;          // map only visible once routes are loaded
  bool _fromFocused = false;
  bool _toFocused = false;
  List<PlaceSuggestion> _fromSuggestions = const [];
  List<PlaceSuggestion> _toSuggestions = const [];
  bool _isSearchingFrom = false;
  bool _isSearchingTo = false;
  PlaceSuggestion? _fromPlace;   // locked origin
  PlaceSuggestion? _toPlace;     // locked destination

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── search helpers ────────────────────────────────────────────
  void _onFromChanged(String value) {
    _fromPlace = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearchingFrom = true);
      try {
        final results = await ref
            .read(navigationProvider.notifier)
            .search(value);
        if (mounted) setState(() => _fromSuggestions = results);
      } catch (_) {
        if (mounted) setState(() => _fromSuggestions = const []);
      } finally {
        if (mounted) setState(() => _isSearchingFrom = false);
      }
    });
  }

  void _onToChanged(String value) {
    _toPlace = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearchingTo = true);
      try {
        final results = await ref
            .read(navigationProvider.notifier)
            .search(value);
        if (mounted) setState(() => _toSuggestions = results);
      } catch (_) {
        if (mounted) setState(() => _toSuggestions = const []);
      } finally {
        if (mounted) setState(() => _isSearchingTo = false);
      }
    });
  }

  void _pickFrom(PlaceSuggestion s) {
    setState(() {
      _fromPlace = s;
      _fromCtrl.text = s.name;
      _fromSuggestions = const [];
      _fromFocused = false;
    });
  }

  void _pickTo(PlaceSuggestion s) {
    setState(() {
      _toPlace = s;
      _toCtrl.text = s.name;
      _toSuggestions = const [];
      _toFocused = false;
    });
  }

  bool get _canSearch => _fromPlace != null && _toPlace != null;

  Future<void> _findRoutes() async {
    final from = _fromPlace;
    final to = _toPlace;
    if (from == null || to == null) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(navigationProvider.notifier)
        .selectDestinationWithOrigin(from, to);
    if (!mounted) return;
    setState(() => _showMap = true);
    _fadeController.forward();
  }

  // ── build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(navigationProvider);
    ref.listen<String?>(
      navigationProvider.select((v) => v.error),
      (_, error) {
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: const Color(0xffff6b6b),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: _bg,
      body: _showMap
          ? _MapView(state: state, onStop: _resetToPlanner)
          : _PlannerView(
              fromCtrl: _fromCtrl,
              toCtrl: _toCtrl,
              fromFocused: _fromFocused,
              toFocused: _toFocused,
              fromSuggestions: _fromSuggestions,
              toSuggestions: _toSuggestions,
              isSearchingFrom: _isSearchingFrom,
              isSearchingTo: _isSearchingTo,
              canSearch: _canSearch,
              isLoading: state.isLoading,
              onFromChanged: _onFromChanged,
              onToChanged: _onToChanged,
              onPickFrom: _pickFrom,
              onPickTo: _pickTo,
              onFindRoutes: _findRoutes,
              onFromFocus: (v) => setState(() => _fromFocused = v),
              onToFocus: (v) => setState(() => _toFocused = v),
            ),
    );
  }

  void _resetToPlanner() {
    setState(() {
      _showMap = false;
      _fromPlace = null;
      _toPlace = null;
      _fromCtrl.clear();
      _toCtrl.clear();
    });
    _fadeController.reset();
  }
}

// ══════════════════════════════════════════════════════════════
// PLANNER VIEW  (the "before-map" screen)
// ══════════════════════════════════════════════════════════════
class _PlannerView extends StatelessWidget {
  const _PlannerView({
    required this.fromCtrl,
    required this.toCtrl,
    required this.fromFocused,
    required this.toFocused,
    required this.fromSuggestions,
    required this.toSuggestions,
    required this.isSearchingFrom,
    required this.isSearchingTo,
    required this.canSearch,
    required this.isLoading,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onFindRoutes,
    required this.onFromFocus,
    required this.onToFocus,
  });

  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final bool fromFocused;
  final bool toFocused;
  final List<PlaceSuggestion> fromSuggestions;
  final List<PlaceSuggestion> toSuggestions;
  final bool isSearchingFrom;
  final bool isSearchingTo;
  final bool canSearch;
  final bool isLoading;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;
  final ValueChanged<PlaceSuggestion> onPickFrom;
  final ValueChanged<PlaceSuggestion> onPickTo;
  final VoidCallback onFindRoutes;
  final ValueChanged<bool> onFromFocus;
  final ValueChanged<bool> onToFocus;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── App bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            child: Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text(
                    'Inzirax',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'Smart driver navigation',
                    style: TextStyle(color: _textDim, fontSize: 12),
                  ),
                ]),
                const Spacer(),
                _IconBtn(
                  icon: Icons.settings_outlined,
                  onTap: () => Navigator.pushNamed(
                      context, SettingsScreen.routeName),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Trip planner card ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan Your Trip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Search for your origin and destination',
                    style: TextStyle(color: _textDim, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Route input card
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // dot + line
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: _originDot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              ...List.generate(
                                  5,
                                  (_) => Container(
                                        width: 2,
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _border,
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      )),
                              const SizedBox(height: 20),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: _destDot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // inputs
                        Expanded(
                          child: Column(
                            children: [
                              _SearchField(
                                controller: fromCtrl,
                                hint: 'From — origin',
                                isSearching: isSearchingFrom,
                                isFocused: fromFocused,
                                onChanged: onFromChanged,
                                onFocusChange: onFromFocus,
                                dotColor: _originDot,
                              ),
                              if (fromSuggestions.isNotEmpty)
                                _SuggestionList(
                                  items: fromSuggestions,
                                  onPick: onPickFrom,
                                ),
                              const SizedBox(height: 12),
                              _SearchField(
                                controller: toCtrl,
                                hint: 'To — destination',
                                isSearching: isSearchingTo,
                                isFocused: toFocused,
                                onChanged: onToChanged,
                                onFocusChange: onToFocus,
                                dotColor: _destDot,
                              ),
                              if (toSuggestions.isNotEmpty)
                                _SuggestionList(
                                  items: toSuggestions,
                                  onPick: onPickTo,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Find routes button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: canSearch ? 1.0 : 0.4,
                      child: _GradientButton(
                        label: isLoading ? 'Finding routes…' : 'Find Routes',
                        icon: isLoading
                            ? null
                            : Icons.route_rounded,
                        loading: isLoading,
                        onTap: canSearch && !isLoading ? onFindRoutes : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Feature pills
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _FeaturePill(
                          icon: Icons.camera_alt_outlined,
                          label: 'Camera alerts'),
                      _FeaturePill(
                          icon: Icons.warning_amber_rounded,
                          label: 'Live incidents'),
                      _FeaturePill(
                          icon: Icons.record_voice_over_outlined,
                          label: 'Voice guidance'),
                      _FeaturePill(
                          icon: Icons.alt_route_rounded,
                          label: 'Alternate routes'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAP VIEW  (shown after routes are loaded)
// ══════════════════════════════════════════════════════════════
class _MapView extends ConsumerWidget {
  const _MapView({required this.state, required this.onStop});
  final NavigationState state;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // full-screen map
        Positioned.fill(
          child: DriverMap(
            position: state.position,
            route: state.selectedRoute,
          ),
        ),

        // top bar with destination name
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onStop,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _surface.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      state.destination?.name ?? 'Select a route below',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // route carousel at the bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: RouteCarousel(
            routes: state.routes,
            selected: state.selectedRoute,
            onSelect: ref.read(navigationProvider.notifier).selectRoute,
            onStart: () async {
              await ref.read(navigationProvider.notifier).startNavigation();
              if (context.mounted) {
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const ActiveNavigationScreen()));
              }
            },
          ),
        ),

        if (state.isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.isSearching,
    required this.isFocused,
    required this.onChanged,
    required this.onFocusChange,
    required this.dotColor,
  });
  final TextEditingController controller;
  final String hint;
  final bool isSearching;
  final bool isFocused;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onFocusChange;
  final Color dotColor;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => widget.onFocusChange(_focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _surfaceVar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isFocused ? widget.dotColor : _border,
          width: widget.isFocused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: _textDim, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: widget.isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: _primary),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.items, required this.onPick});
  final List<PlaceSuggestion> items;
  final ValueChanged<PlaceSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: _surfaceVar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: items.map((s) {
          final isLast = s == items.last;
          return InkWell(
            onTap: () => onPick(s),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: _border, width: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 16, color: _textDim),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.name,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  colors: [Color(0xff6c63ff), Color(0xff9b59b6)],
                )
              : null,
          color: onTap == null ? _surfaceVar : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: const Color(0xff6c63ff).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceVar,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _secondary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
