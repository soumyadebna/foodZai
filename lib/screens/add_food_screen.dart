import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/food_item.dart';
import '../services/user_service.dart';
import '../services/food_recognition_service.dart';
import '../utils/m3_animations.dart'; // For M3 animation constants

class AddFoodScreen extends StatefulWidget {
  final String? initialMealType;

  const AddFoodScreen({Key? key, this.initialMealType}) : super(key: key);

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final UserService _userService = UserService();
  final FoodRecognitionService _foodRecognitionService = FoodRecognitionService();

  String _selectedMealType = 'Breakfast';
  List<FoodItem> _suggestedFoods = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMealType != null && _mealTypes.contains(widget.initialMealType)) {
      _selectedMealType = widget.initialMealType!;
    }
    _loadSuggestedFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSuggestedFoods() {
    setState(() {
      _isLoading = true;
    });

    final suggestedFoods = _foodRecognitionService.getSuggestedFoods(_selectedMealType);

    setState(() {
      _suggestedFoods = suggestedFoods;
      _isLoading = false;
    });
  }

  void _addFoodItem(FoodItem foodItem) async {
    setState(() {
      _isLoading = true;
    });

    await _userService.addFoodItem(foodItem);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${foodItem.name} added to your diary',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating, // M3 style
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // M3 radius
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Add Food',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface, // M3 AppBar color
        elevation: 0, // M3 typically has 0 elevation for non-scrolled app bars
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface), // M3 back icon
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: colorScheme.onSurface), // M3 icon
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Camera functionality coming soon',
                     style: textTheme.bodyMedium?.copyWith(color: colorScheme.onInverseSurface),
                  ),
                  backgroundColor: colorScheme.inverseSurface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMealTypeSelector(context),
          const SizedBox(height: 16),
          _buildSearchBar(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested Foods',
              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
            ).animate().fadeIn(delay: M3Animations.shortDelay * 2, duration: M3Animations.medium),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _suggestedFoods.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _suggestedFoods.length,
                        itemBuilder: (context, index) {
                          final foodItem = _suggestedFoods[index];
                          return _buildFoodItemCard(context, foodItem, index)
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 50 * index) + M3Animations.mediumDelay, duration: M3Animations.medium)
                              .slideY(begin: 0.1, curve: Curves.easeOut);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select Meal Type',
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48, // Adjusted height for FilterChip
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12), // Padding for chips
              itemCount: _mealTypes.length,
              itemBuilder: (context, index) {
                final mealType = _mealTypes[index];
                final isSelected = mealType == _selectedMealType;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0), // Spacing between chips
                  child: FilterChip(
                    label: Text(mealType),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedMealType = mealType;
                      });
                      _loadSuggestedFoods();
                    },
                    backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: textTheme.labelLarge?.copyWith(
                      color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                    ),
                    checkmarkColor: isSelected ? colorScheme.onPrimaryContainer : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // M3 radius
                      side: BorderSide(
                        color: isSelected ? colorScheme.primaryContainer : colorScheme.outline.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: M3Animations.medium).slideY(begin: -0.1, curve: Curves.easeOut);
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search for food...',
          hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    // Optionally, reload suggested foods or clear search results
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), // M3 radius
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // M3 typical padding
        ),
        onChanged: (value) {
           // Update suffix icon visibility
          setState(() {});
          // Implement search logic if needed, or rely on onSubmitted
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Food search coming soon', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onInverseSurface)),
                backgroundColor: colorScheme.inverseSurface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    ).animate().fadeIn(delay: M3Animations.shortDelay, duration: M3Animations.medium).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined, // M3 icon
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No suggested foods',
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different meal type or use search.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: M3Animations.long),
    );
  }

  Widget _buildFoodItemCard(BuildContext context, FoodItem foodItem, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card( // Using M3 Card
      elevation: 0.5, // Subtle elevation for M3 cards
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // M3 radius
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias, // For InkWell ripple
      child: InkWell(
        onTap: () => _addFoodItem(foodItem),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12), // M3 radius
                child: Image.network(
                  foodItem.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.image_not_supported_outlined, // M3 icon
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodItem.name,
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${foodItem.calories} kcal',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P: ${foodItem.protein.toInt()}g · C: ${foodItem.carbs.toInt()}g · F: ${foodItem.fat.toInt()}g',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline_rounded, size: 28), // M3 icon
                color: colorScheme.primary,
                onPressed: () => _addFoodItem(foodItem),
                tooltip: 'Add ${foodItem.name}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
