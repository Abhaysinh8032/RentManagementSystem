import 'package:flutter/material.dart';

/// Registered as a navigatorObserver in main.dart. Screens kept alive inside
/// HomeScreen's bottom-nav IndexedStack (Properties, My Rentals, the admin
/// lists) mix in RouteAware and subscribe to this so they automatically
/// refetch when the user navigates BACK to them - e.g. after creating a
/// rental request, or adding/editing a property - instead of only picking up
/// the change on the next full app restart (which is what logging out and
/// back in was forcing before this fix).
final RouteObserver<PageRoute<dynamic>> appRouteObserver = RouteObserver<PageRoute<dynamic>>();
