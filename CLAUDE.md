# Claude Development Guidelines for HealthMap AI

## Project Overview
HealthMap AI is a Flutter application that provides personalized air quality recommendations and mapping functionality. This file contains guidelines for future development and code contributions.

## Core Development Principles

### 1. Component Architecture
- **Always containerize components**: Create reusable, self-contained widgets in the `/lib/widgets/` directory
- **Single Responsibility**: Each widget should have one clear purpose
- **Composition over Inheritance**: Prefer composition patterns when building complex UI components
- **State Management**: Use StatefulWidget only when necessary; prefer StatelessWidget for UI-only components

### 2. Material Design 3 Compliance
Follow Material Design 3 (Material You) guidelines strictly:

#### Colors & Theming
- Use `Theme.of(context).colorScheme` for all color references
- Never hardcode colors - always use theme-based colors
- Primary colors: `colorScheme.primary`, `colorScheme.onPrimary`
- Surface colors: `colorScheme.surface`, `colorScheme.surfaceContainer`, `colorScheme.surfaceContainerHighest`
- Error colors: `colorScheme.error`, `colorScheme.onError`

#### Typography
- Use `Theme.of(context).textTheme` for all text styling
- Standard text styles: `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`

#### Components
- Use Material 3 components: `FilledButton`, `OutlinedButton`, `TextButton`, `Card`, `TextField` with filled styling
- Apply proper border radius: 12px for cards, 8px for buttons, 28px for dialogs
- Use appropriate elevation and shadows as per Material 3 specifications

#### Spacing & Layout
- Follow 8dp grid system
- Standard padding: 8, 12, 16, 24, 32px
- Use `SizedBox` for consistent spacing
- Apply consistent margins between components

### 3. Code Standards

#### File Organization
```
lib/
├── main.dart
├── models/           # Data models and DTOs
├── services/         # Business logic and API services
├── screens/          # Full screen widgets
│   ├── main/        # Main app screens
│   └── onboarding/  # Onboarding flow screens
├── widgets/          # Reusable UI components
└── utils/           # Helper functions and utilities
```

#### Widget Development
- Create widgets in `/lib/widgets/` directory
- Use descriptive naming: `AddLocationDialog`, `PinnedLocationSheet`
- Include proper documentation and parameter validation
- Handle loading states and error cases gracefully

#### State Management
- Use `setState()` for simple local state
- Consider `ChangeNotifier` or `Provider` for shared state
- Always dispose of controllers and listeners in `dispose()`

#### Error Handling
- Use try-catch blocks for async operations
- Provide user-friendly error messages via SnackBar
- Never leave users in broken states - always provide fallbacks

### 4. Accessibility Guidelines
- Include semantic labels for interactive elements
- Use proper contrast ratios (4.5:1 minimum)
- Support keyboard navigation where applicable
- Test with screen readers and accessibility tools

### 5. Performance Best Practices
- Use `const` constructors wherever possible
- Implement proper `dispose()` methods for stateful widgets
- Avoid rebuilding expensive widgets unnecessarily
- Use `ListView.builder()` for long lists

## Specific Implementation Guidelines

### Maps Integration
- Use Google Maps Flutter plugin
- Implement proper marker clustering for performance
- Handle location permissions gracefully
- Provide offline fallbacks where possible

### API Integration
- Use proper error handling for network requests
- Implement retry logic for failed requests
- Cache data locally when appropriate
- Show loading indicators during API calls

### Database Operations
- Use SQLite for local data persistence
- Implement proper migrations for schema changes
- Handle database errors gracefully
- Use transactions for complex operations

## Code Quality Standards

### Linting & Formatting
- Follow Flutter/Dart linting rules
- Use `flutter analyze` to check code quality
- Format code with `dart format`
- Run tests before committing changes

### Testing
- Write unit tests for business logic
- Include widget tests for UI components
- Test error scenarios and edge cases
- Maintain test coverage above 80%

### Documentation
- Document public APIs and complex logic
- Include examples in widget documentation
- Update this file when adding new patterns
- Use meaningful variable and function names

## Common Patterns

### Dialog Implementation
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    child: // Your dialog content
  ),
);
```

### BottomSheet Implementation
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: // Your sheet content
  ),
);
```

### SnackBar Usage
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Your message'),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
);
```

## Deprecated Patterns to Avoid

### DO NOT USE:
- `withOpacity()` - Use `withValues(alpha: value)` instead
- Hardcoded colors - Always use theme colors
- `value` parameter in form fields - Use `initialValue` instead
- `print()` statements - Use proper logging framework
- Direct database queries in UI - Use service layer

## Development Workflow

1. **Before Making Changes**
   - Review existing code patterns
   - Check if similar components already exist
   - Ensure changes align with Material Design 3

2. **During Development**
   - Follow the component architecture
   - Use proper state management
   - Handle errors gracefully
   - Test on multiple screen sizes

3. **Before Committing**
   - Run `flutter analyze`
   - Run `flutter test`
   - Verify accessibility compliance
   - Update documentation if needed

## AI Assistant Guidelines

When helping with this project:
1. Always suggest creating reusable components in `/lib/widgets/`
2. Ensure Material Design 3 compliance in all UI suggestions
3. Provide error handling and loading states
4. Use theme-based styling throughout
5. Follow the established file organization pattern
6. Include proper documentation in suggested code
7. Suggest performance optimizations when applicable

---

**Note**: This document should be updated as the project evolves and new patterns emerge. Always refer to the latest Flutter and Material Design documentation for current best practices.