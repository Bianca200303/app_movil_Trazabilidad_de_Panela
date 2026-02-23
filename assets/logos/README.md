# Assets - Logos Directory

This directory contains logos and branding assets for different cooperatives.

## Structure

```
assets/
└── logos/
    ├── default-logo.png
    ├── cafeteros-unidos.png
    ├── [cooperative-name].png
    └── README.md
```

## Logo Requirements

### File Format
- **Format**: PNG with transparent background
- **Dimensions**: 512x512px minimum (square aspect ratio)
- **Size**: Under 200KB for optimal performance

### Naming Convention
- Use lowercase with hyphens for spacing
- Match the cooperative's shortName from configuration
- Example: `cafeteros-unidos.png` for "CafeterosUnidos"

### Usage in Configuration
Reference logos in cooperative configuration files:

```json
{
  "branding": {
    "logoPath": "assets/logos/cafeteros-unidos.png"
  }
}
```

## Adding New Cooperative Logo

1. **Prepare the logo**:
   - Resize to 512x512px
   - Save as PNG with transparent background
   - Optimize file size

2. **Add to assets**:
   - Place in `flutter/assets/logos/`
   - Use naming convention: `[cooperative-name].png`

3. **Update pubspec.yaml** (if needed):
   ```yaml
   flutter:
     assets:
       - assets/logos/
   ```

4. **Update configuration**:
   - Reference in cooperative's JSON config file
   - Update branding.logoPath field

## Default Logo
- `default-logo.png` is used when no specific logo is provided
- Should contain the generic "Panela System" branding
- Used as fallback for all cooperatives

## Implementation Notes
- Logos are loaded at app startup
- They appear in splash screen, header, and about screens
- Consider different screen densities when creating logos
- Test logo visibility on both light and dark themes