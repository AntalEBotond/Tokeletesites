library menu_screen;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/models/menu_item_data.dart';
import '/profil/framed_avatar.dart';
import '/profil/profile_page.dart';
import '/services/api_service.dart';
import '/utils/i18n.dart';
import '/widgets/left_side_menu.dart';
import '/widgets/settings_screen.dart';
import '/widgets/skeleton_post.dart';

part 'menu/feed_section.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with _FeedSection {
  int _selectedIndex = 0;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    initFeed();
  }

  @override
  void dispose() {
    disposeFeed();
    super.dispose();
  }

  /// Bal oldali menü tételek
  List<MenuItemData> _items(BuildContext context) => [
        MenuItemData(icon: Icons.home_outlined, title: I18n.t(context, 'home')),
        MenuItemData(icon: Icons.person_outline, title: I18n.t(context, 'profile')),
        // === ÚJ: Fogadás menüpont
        MenuItemData(icon: Icons.sports_esports_outlined, title: I18n.t(context, 'Bets')),
        MenuItemData(icon: Icons.settings_outlined, title: I18n.t(context, 'settings')),
        MenuItemData(icon: Icons.help_outline, title: I18n.t(context, 'help')),
        MenuItemData(icon: Icons.logout, title: 'Logout'),
      ];

  Future<void> _logout(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('auth_token');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Widget _helpPlaceholder(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          I18n.t(context, 'help_placeholder'),
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// === ÚJ: Fogadás oldal placeholder
  Widget _betsPlaceholder(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Fogadás',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Itt lesznek a fogadások funkciói. Hamarosan…',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// A címek sorrendje igazodik a pageFor switch-hez
    final titles = [
      I18n.t(context, 'home'),     // index 0
      I18n.t(context, 'profile'),  // index 1
      I18n.t(context, 'Bets'),                   // index 2 (ÚJ)
      I18n.t(context, 'settings'), // index 3
      I18n.t(context, 'help'),     // index 4
    ];

    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 720;
    final menuItems = _items(context);
    final logoutIndex = menuItems.length - 1;

    /// Oldalválasztó
    Widget pageFor(int index) {
      switch (index) {
        case 0:
          return _buildFeed(context, theme);
        case 1:
          return const ProfilePage();
        case 2:
          return _betsPlaceholder(theme);      // === ÚJ: Fogadás oldal
        case 3:
          return const SettingsScreen();
        default:
          return _helpPlaceholder(theme);
      }
    }

    final safeIndex = _selectedIndex.clamp(0, titles.length - 1);
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: pageFor(safeIndex),
    );

    if (isCompact) {
      // Mobil / keskeny nézet: Drawer
      return Scaffold(
        appBar: AppBar(
          title: Text(titles[safeIndex]),
          actions: safeIndex == 0 ? buildHomeActions(context) : null,
        ),
        drawer: Drawer(
          child: LeftSideMenu(
            items: menuItems,
            selectedIndex: _selectedIndex,
            onItemSelected: (i) {
              Navigator.of(context).pop();
              if (i == logoutIndex) {
                _logout(context);
                return;
              }
              setState(() => _selectedIndex = i.clamp(0, titles.length - 1));
            },
            collapsed: false,
          ),
        ),
        body: content,
      );
    }

    // Desktop / széles nézet: bal oldali fix menü
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[safeIndex]),
        actions: safeIndex == 0 ? buildHomeActions(context) : null,
      ),
      body: Row(
        children: [
          LeftSideMenu(
            items: menuItems,
            selectedIndex: _selectedIndex,
            collapsed: _collapsed,
            onCollapseToggle: (value) => setState(() => _collapsed = value),
            onItemSelected: (i) {
              if (i == logoutIndex) {
                _logout(context);
                return;
              }
              setState(() => _selectedIndex = i.clamp(0, titles.length - 1));
            },
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
