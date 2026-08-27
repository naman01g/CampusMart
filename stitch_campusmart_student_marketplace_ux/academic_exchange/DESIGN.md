---
name: Academic Exchange
colors:
  surface: '#fbf9f9'
  surface-dim: '#dbdad9'
  surface-bright: '#fbf9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f3'
  surface-container: '#efeded'
  surface-container-high: '#e9e8e7'
  surface-container-highest: '#e3e2e2'
  on-surface: '#1b1c1c'
  on-surface-variant: '#444748'
  inverse-surface: '#303031'
  inverse-on-surface: '#f2f0f0'
  outline: '#747878'
  outline-variant: '#c4c7c7'
  surface-tint: '#5f5e5e'
  primary: '#080808'
  on-primary: '#ffffff'
  primary-container: '#202020'
  on-primary-container: '#898787'
  inverse-primary: '#c8c6c5'
  secondary: '#8b5000'
  on-secondary: '#ffffff'
  secondary-container: '#fea542'
  on-secondary-container: '#6d3e00'
  tertiary: '#000b06'
  on-tertiary: '#ffffff'
  tertiary-container: '#00261a'
  on-tertiary-container: '#5b937b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1b1c1c'
  on-primary-fixed-variant: '#474746'
  secondary-fixed: '#ffdcbe'
  secondary-fixed-dim: '#ffb870'
  on-secondary-fixed: '#2c1600'
  on-secondary-fixed-variant: '#693c00'
  tertiary-fixed: '#b5efd4'
  tertiary-fixed-dim: '#99d3b8'
  on-tertiary-fixed: '#002115'
  on-tertiary-fixed-variant: '#16503c'
  background: '#fbf9f9'
  on-background: '#1b1c1c'
  surface-variant: '#e3e2e2'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-price:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  container-max: 1280px
  gutter: 20px
---

## Brand & Style

The design system is built on a foundation of "Functional Scholasticism." It rejects the fleeting trends of the broader web in favor of a stable, institutional aesthetic that feels native to a university environment. The personality is reliable and grounded (Charcoal), yet energized by the urgency of campus life (Ochre).

The style is **Modern / Corporate** with a focus on tactile structure. It prioritizes information density and clear hierarchy over decorative flourishes. Key characteristics include:
- **High Utility:** Every element serves a specific navigation or transactional purpose.
- **Structural Integrity:** Use of visible borders and distinct surface tiers to organize content.
- **Community Trust:** A "slightly premium" feel achieved through sophisticated color pairings (Cream/Charcoal) and generous whitespace within containers.

## Colors

The palette is rooted in a "Paper and Ink" philosophy, utilizing a warm, non-white base to reduce eye strain during late-night study sessions.

- **Primary (Charcoal):** #202020. Used for all structural elements, headers, and primary navigation. It provides the "institutional" weight.
- **Accent (Ochre):** #E38F2D. Reserved exclusively for conversion points—specifically the 'SELL' flow, primary CTAs, and active notification indicators. This replaces the previous Vermilion for a more balanced, academic feel.
- **Surface Hierarchy:** The background uses Warm Cream, while individual cards and interactive inputs use a brighter Surface White to "lift" them off the page without needing shadows.
- **Functional Colors:** Success, Warning, and Error tones are desaturated and deep, maintaining a professional "printed" quality rather than a "digital neon" look.

## Typography

This design system utilizes **Hanken Grotesk** across all levels for its sharp, contemporary geometry and high legibility. It feels more "designed" than standard system fonts while remaining strictly professional.

- **Headlines:** Use Bold weights with slight negative letter-spacing to create a compact, authoritative look for item titles.
- **Prices:** Defined under `label-price`, these use a Bold weight and slight tracking to ensure they are immediately scannable within product grids.
- **Body:** Standardized at 16px for desktop to maintain the "premium" feel, dropping to 14px for secondary metadata or dense list views.

## Layout & Spacing

The layout follows a **Fixed Grid** model on desktop and a **Fluid** model on mobile. It uses a rigorous 4px baseline shift to ensure all elements align to a cohesive rhythm.

- **Desktop (1280px+):** 12-column grid with 20px gutters. Content is centered.
- **Tablet (768px - 1279px):** 8-column grid with 16px margins.
- **Mobile (<767px):** 4-column grid with 16px margins.
- **Spacing Logic:** Use `lg` (24px) for padding within cards and `xl` (48px) for vertical section separation.

## Elevation & Depth

This design system avoids drop shadows entirely to maintain a modern, flat-but-tactile aesthetic. Depth is communicated through **Tonal Layers** and **Low-Contrast Outlines**.

- **Level 0 (Base):** Warm Cream - The foundational canvas.
- **Level 1 (Surface):** Surface White - Used for cards, inputs, and modals. Must be paired with a 1px solid Border.
- **Interactions:** Hover states on cards should not lift via shadow. Instead, the border color should darken from its base shade to Charcoal (#202020) to indicate focus.

## Shapes

The shape language is **Soft** but disciplined. 

- **Standard Elements:** Buttons, inputs, and cards use a 0.25rem (4px) radius. This creates a subtle hint of approachability without feeling "bubbly" or juvenile.
- **Large Components:** Images and containers may use `rounded-lg` (8px) to soften the visual impact of high-density grids.
- **Interactive States:** Avoid pill shapes; maintain the 4px radius even for tags and badges to reinforce the structured, professional nature of the system.

## Components

### Buttons
- **Primary:** Charcoal (#202020) background with White text. Sharp, 4px corners.
- **Action (Sell):** Ochre (#E38F2D) background with White text. Used exclusively for "Create Listing" or "Buy Now."
- **Ghost:** Transparent background with Border and Secondary Text (#737373).

### Inputs & Form Fields
- Fields use the Surface White color to stand out from the Cream background.
- Labels are consistently `label-sm` in Charcoal.
- Active state: 1px border shift to Charcoal (#202020).

### Cards
- White background, 1px Border.
- No shadow.
- Metadata (location, time posted) uses `body-md` in Secondary Text (#737373).

### Chips & Badges
- Used for categories (e.g., "Textbooks," "Furniture"). 
- Rectangular with 4px radius. 
- Background: Warm Cream; Text: Charcoal (#202020).

### Navigation
- Top-tier navigation uses a solid Charcoal header for a "Header Bar" feel, or a clean Cream bar with a bottom border for a lighter look.
- Active links are underlined in Ochre (#E38F2D).

### Iconography
- Use a thick-stroke (1.5pt or 2pt) geometric icon set. 
- Icons should be monochromatic (Charcoal) unless indicating a specific action or status (e.g., Error). 
- Avoid rounded terminals in icons; prefer capped or square ends to match the structural theme.