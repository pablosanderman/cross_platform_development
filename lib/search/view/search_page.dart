import 'package:flutter/material.dart';
import 'package:cross_platform_development/shared/utils/platform_utils.dart';
import 'event_search_view.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      body: SafeArea(
        child: Padding(
          padding: PlatformUtils.isMobile 
            ? const EdgeInsets.all(16.0)
            : const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Search Events',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: PlatformUtils.isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: PlatformUtils.isMobile ? 16 : 24),
              
              // Search functionality
              const Expanded(
                child: EventSearchView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}