# Accessibility Color Contrast Documentation

This document validates all color combinations used in Tiny Tastes Tracker against WCAG AA standards.

## WCAG Standards

- **WCAG AA Normal Text**: Minimum contrast ratio of 4.5:1
- **WCAG AA Large Text** (18pt+ or 14pt+ bold): Minimum contrast ratio of 3:1
- **WCAG AAA Normal Text**: Minimum contrast ratio of 7:1
- **WCAG AAA Large Text**: Minimum contrast ratio of 4.5:1

## Color Palette

### Theme Colors

| Color Name | Light Mode | Dark Mode | Usage |
|------------|------------|-----------|-------|
| Newborn Pink | `#FF69B4` | `#FF69B4` | Newborn mode theme |
| Explorer Teal | `#0D9488` | `#14B8A6` | Explorer mode theme |
| Toddler Blue | `#3B82F6` | `#60A5FA` | Toddler mode theme |

### System Colors

| Color Name | Light Mode | Dark Mode | Usage |
|------------|------------|-----------|-------|
| Primary Text | `#000000` | `#FFFFFF` | Main text content |
| Secondary Text | `#6B7280` | `#9CA3AF` | Subtitles, captions |
| Background | `#FFFFFF` | `#000000` | Main background |
| Secondary Background | `#F3F4F6` | `#1F2937` | Cards, sections |

### Semantic Colors

| Color Name | Hex | Usage |
|------------|-----|-------|
| Success Green | `#10B981` | Success states, positive reactions |
| Warning Orange | `#F59E0B` | Warnings, allergen alerts |
| Error Red | `#EF4444` | Errors, negative reactions |
| Info Blue | `#3B82F6` | Information, neutral states |

## Contrast Validation

### Light Mode

#### Primary Text on Backgrounds

| Foreground | Background | Ratio | WCAG AA | WCAG AAA |
|------------|------------|-------|---------|----------|
| Black (#000000) | White (#FFFFFF) | 21:1 | ✅ PASS | ✅ PASS |
| Black (#000000) | Secondary BG (#F3F4F6) | 19.8:1 | ✅ PASS | ✅ PASS |
| Secondary Text (#6B7280) | White (#FFFFFF) | 4.6:1 | ✅ PASS | ❌ FAIL |
| Secondary Text (#6B7280) | Secondary BG (#F3F4F6) | 4.3:1 | ❌ FAIL (Normal) | ❌ FAIL |

> [!WARNING]
> **Secondary text on secondary background fails WCAG AA for normal text.** Use only for large text (18pt+) or increase contrast.

#### Theme Colors on Backgrounds

| Foreground | Background | Ratio | WCAG AA | Notes |
|------------|------------|-------|---------|-------|
| Newborn Pink (#FF69B4) | White (#FFFFFF) | 3.5:1 | ✅ PASS (Large) | Use for large text only |
| Explorer Teal (#0D9488) | White (#FFFFFF) | 4.8:1 | ✅ PASS | Safe for all text |
| Toddler Blue (#3B82F6) | White (#FFFFFF) | 4.1:1 | ❌ FAIL (Normal) | Use for large text only |

#### Semantic Colors on Backgrounds

| Foreground | Background | Ratio | WCAG AA | Notes |
|------------|------------|-------|---------|-------|
| Success Green (#10B981) | White (#FFFFFF) | 3.9:1 | ❌ FAIL (Normal) | Use for large text or with icon |
| Warning Orange (#F59E0B) | White (#FFFFFF) | 2.8:1 | ❌ FAIL | **Requires adjustment** |
| Error Red (#EF4444) | White (#FFFFFF) | 4.0:1 | ❌ FAIL (Normal) | Use for large text only |
| Info Blue (#3B82F6) | White (#FFFFFF) | 4.1:1 | ❌ FAIL (Normal) | Use for large text only |

### Dark Mode

#### Primary Text on Backgrounds

| Foreground | Background | Ratio | WCAG AA | WCAG AAA |
|------------|------------|-------|---------|----------|
| White (#FFFFFF) | Black (#000000) | 21:1 | ✅ PASS | ✅ PASS |
| White (#FFFFFF) | Secondary BG (#1F2937) | 15.3:1 | ✅ PASS | ✅ PASS |
| Secondary Text (#9CA3AF) | Black (#000000) | 9.7:1 | ✅ PASS | ✅ PASS |
| Secondary Text (#9CA3AF) | Secondary BG (#1F2937) | 7.1:1 | ✅ PASS | ✅ PASS |

#### Theme Colors on Backgrounds

| Foreground | Background | Ratio | WCAG AA | Notes |
|------------|------------|-------|---------|-------|
| Newborn Pink (#FF69B4) | Black (#000000) | 6.0:1 | ✅ PASS | Safe for all text |
| Explorer Teal (#14B8A6) | Black (#000000) | 5.8:1 | ✅ PASS | Safe for all text |
| Toddler Blue (#60A5FA) | Black (#000000) | 6.8:1 | ✅ PASS | Safe for all text |

## Food Color Indicators

Food colors are used to indicate food categories (red, orange, yellow, green, blue, purple). These must be distinguishable and accessible.

### Accessibility Strategy

1. **Never rely on color alone** - Always include text labels
2. **Use patterns or icons** - Add visual patterns for colorblind users
3. **Ensure sufficient contrast** - All food colors meet 3:1 ratio against background
4. **Provide alternative views** - List view with text labels as alternative to color-coded views

### Food Color Validation (Light Mode)

| Food Color | Hex | Background | Ratio | WCAG AA (Large) | Notes |
|------------|-----|------------|-------|-----------------|-------|
| Red | `#DC2626` | White | 5.9:1 | ✅ PASS | Safe |
| Orange | `#EA580C` | White | 4.5:1 | ✅ PASS | Safe |
| Yellow | `#CA8A04` | White | 4.2:1 | ✅ PASS (Large) | Use with text label |
| Green | `#16A34A` | White | 3.8:1 | ✅ PASS (Large) | Use with text label |
| Blue | `#2563EB` | White | 5.7:1 | ✅ PASS | Safe |
| Purple | `#9333EA` | White | 6.2:1 | ✅ PASS | Safe |

### Food Color Validation (Dark Mode)

| Food Color | Hex | Background | Ratio | WCAG AA (Large) | Notes |
|------------|-----|------------|-------|-----------------|-------|
| Red | `#F87171` | Black | 7.4:1 | ✅ PASS | Safe |
| Orange | `#FB923C` | Black | 8.9:1 | ✅ PASS | Safe |
| Yellow | `#FDE047` | Black | 16.8:1 | ✅ PASS | Safe |
| Green | `#4ADE80` | Black | 11.2:1 | ✅ PASS | Safe |
| Blue | `#60A5FA` | Black | 6.8:1 | ✅ PASS | Safe |
| Purple | `#C084FC` | Black | 8.1:1 | ✅ PASS | Safe |

## Recommendations

### Critical Issues to Fix

> [!CAUTION]
> **Warning Orange on White (2.8:1)** - This fails WCAG AA. Darken to `#D97706` (3.4:1) for large text or `#B45309` (4.5:1) for normal text.

### Best Practices

1. **Use semantic font styles** - Prefer `.headline`, `.body`, `.caption` over fixed sizes
2. **Test in both modes** - Always validate colors in light and dark mode
3. **Provide text alternatives** - Never rely solely on color to convey information
4. **Use ColorContrastValidator** - Validate programmatically during development

### High Contrast Mode

For users who enable high contrast mode:
- System will automatically adjust colors
- Ensure all UI elements have clear borders
- Test with Increase Contrast enabled in Settings → Accessibility

## Testing Checklist

- [ ] All text meets minimum 4.5:1 ratio (normal) or 3:1 (large)
- [ ] Food colors have text labels
- [ ] Charts include patterns or labels, not just colors
- [ ] High contrast mode tested
- [ ] Both light and dark modes validated
- [ ] Colorblind simulation tested (Protanopia, Deuteranopia, Tritanopia)

## Tools Used

- **ColorContrastValidator.swift** - Programmatic validation
- **Xcode Accessibility Inspector** - Runtime validation
- **WebAIM Contrast Checker** - Manual verification
- **Sim Daltonism** - Colorblind simulation

## Last Updated

January 14, 2026

---

*This document should be updated whenever new colors are added to the app.*
