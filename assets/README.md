# Assets Directory

This directory contains all static assets used by the Panela System application.

## Structure

```
assets/
├── logos/               # Cooperative-specific logos and branding
│   ├── default-logo.png
│   ├── [coop-name].png
│   └── README.md
├── icons/               # Custom icons (if needed)
├── images/              # Static images
└── README.md
```

## Asset Categories

### 1. Logos (`logos/`)
- Cooperative-specific branding
- App icons and headers
- Splash screen graphics
- See `logos/README.md` for details

### 2. Icons (`icons/`)
- Custom vector icons
- UI elements not covered by Flutter's default icons
- Feature-specific iconography

### 3. Images (`images/`)
- Background images
- Illustrations
- Static graphics
- Onboarding visuals

## Asset Management

### Adding Assets
1. Place files in appropriate subdirectory
2. Update `pubspec.yaml` if needed:
   ```yaml
   flutter:
     assets:
       - assets/logos/
       - assets/icons/
       - assets/images/
   ```
3. Reference in code:
   ```dart
   Image.asset('assets/logos/cooperative-logo.png')
   ```

### Asset Optimization
- **Images**: Use WebP or PNG format
- **Size**: Optimize for mobile (keep under 1MB each)
- **Resolution**: Provide 2x and 3x variants for high-DPI screens
- **Compression**: Balance quality vs file size

### Naming Conventions
- Use lowercase with hyphens: `logo-cooperative.png`
- Include size in filename if multiple variants: `icon-32.png`
- Use descriptive names: `background-home-screen.png`

## Usage Guidelines

### Code References
```dart
// Logo usage
Image.asset('assets/logos/${Env.cooperativeName.toLowerCase().replaceAll(' ', '-')}.png')

// Default fallback
Image.asset('assets/logos/default-logo.png')

// Icon usage
Image.asset('assets/icons/custom-icon.png')
```

### Responsive Images
Consider screen density:
```dart
Image.asset(
  'assets/images/background.png',
  fit: BoxFit.cover,
  width: MediaQuery.of(context).size.width,
)
```

## Build Integration
- Assets are bundled into APK during build
- Unused assets are excluded in release builds (tree shaking)
- Large assets impact APK size - optimize accordingly

## Security Notes
- Don't include sensitive information in asset files
- Assets are accessible to anyone who extracts the APK
- Use appropriate licensing for any third-party assets