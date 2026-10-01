import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzirax/features/navigation/active_navigation_screen.dart';
import 'package:inzirax/features/navigation/driver_map.dart';
import 'package:inzirax/features/navigation/navigation_controller.dart';
import 'package:inzirax/features/navigation/route_carousel.dart';
import 'package:inzirax/features/settings/settings_screen.dart';
import 'package:inzirax/models/place_suggestion.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      try {
        final results = await ref.read(navigationProvider.notifier).search(value);
        if (mounted) setState(() => _suggestions = results);
      } catch (_) {
        if (mounted) setState(() => _suggestions = const []);
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(navigationProvider);
    ref.listen<String?>(navigationProvider.select((value) => value.error), (_, error) {
      if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    });
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: DriverMap(position: state.position, route: state.selectedRoute)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(14),
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Where to?',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Settings',
                    onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ),
              ]),
              if (_suggestions.isNotEmpty)
                Material(
                  elevation: 5,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          _search.text = item.name;
                          setState(() => _suggestions = const []);
                          await ref.read(navigationProvider.notifier).selectDestination(item);
                        },
                      );
                    },
                  ),
                ),
              const Spacer(),
              if (state.position == null)
                const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Locating your vehicle…'))),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: RouteCarousel(
            routes: state.routes,
            selected: state.selectedRoute,
            onSelect: ref.read(navigationProvider.notifier).selectRoute,
            onStart: () async {
              await ref.read(navigationProvider.notifier).startNavigation();
              if (context.mounted) Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ActiveNavigationScreen()));
            },
          ),
        ),
        if (state.isLoading) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
