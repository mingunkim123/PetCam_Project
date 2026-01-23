import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/gallery/presentation/gallery_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/store/presentation/store_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
    GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
    GoRoute(path: '/store', builder: (context, state) => const StoreScreen()),
  ],
);
