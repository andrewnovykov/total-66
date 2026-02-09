import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = const <Category>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await context.read<CategoryService>().listCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load categories';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  FilledButton(onPressed: _loadCategories, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Browse available categories for your next goal.',
                  style: TextStyle(color: Color(0xFFDDE4FF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_categories.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Icon(Icons.category_outlined, size: 40, color: AppTheme.textSecondary),
                    SizedBox(height: 8),
                    Text('No categories available'),
                  ],
                ),
              ),
            )
          else
            ..._categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.brandIndigoLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_fire_department, color: AppTheme.brandIndigoDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category.description ?? 'No description',
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if ((category.status ?? '').isNotEmpty) Chip(label: Text(category.status!)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
