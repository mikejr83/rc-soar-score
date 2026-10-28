---
name: RC Soar Score
description: Cockpit-panel scoring for RC sailplane contests, built to be read at the field.
colors:
  wing-orange: '#e8420c'
  deep-orange: '#b83300'
  deep-orange-hover: '#9e2c00'
  orange-on-dark: '#ff6a33'
  night: '#1c1b1a'
  dial: '#0c0b0b'
  bezel: '#4a4643'
  ink: '#201e1d'
  paper: '#f3f2f2'
  white: '#ffffff'
  muted-light: '#605d5d'
  muted-dark: '#b8b3ad'
  hairline-light: '#d6d2cc'
  hairline-strong-light: '#b9b3aa'
  table-head-light: '#e8e4dc'
  panel-surface: '#262422'
  panel-line: '#3a3735'
  surface-dark: '#2b2927'
  surface-2-dark: '#35322f'
  line-dark: '#49443f'
  line-strong-dark: '#6a645d'
  ok-bg-light: '#d8efe1'
  ok-fg-light: '#0f4a2b'
  ok-bg-dark: '#173a27'
  ok-fg-dark: '#b1f1ce'
typography:
  display:
    fontFamily: 'League Spartan, Archivo, system-ui, sans-serif'
    fontSize: 'clamp(36px, 6vw, 56px)'
    fontWeight: 800
    lineHeight: 1.08
    letterSpacing: '-0.01em'
  headline:
    fontFamily: 'League Spartan, Archivo, system-ui, sans-serif'
    fontSize: 'clamp(28px, 4vw, 40px)'
    fontWeight: 800
    lineHeight: 1.08
    letterSpacing: '-0.01em'
  title:
    fontFamily: 'League Spartan, Archivo, system-ui, sans-serif'
    fontSize: '24px'
    fontWeight: 700
    lineHeight: 1.08
  lede:
    fontFamily: 'Archivo, system-ui, sans-serif'
    fontSize: 'clamp(17px, 2vw, 20px)'
    fontWeight: 400
    lineHeight: 1.5
  body:
    fontFamily: 'Archivo, system-ui, sans-serif'
    fontSize: '16px'
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: 'Archivo, system-ui, sans-serif'
    fontSize: '13px'
    fontWeight: 800
    lineHeight: 18px
    letterSpacing: '0.18em'
  stencil:
    fontFamily: 'Saira Stencil One, League Spartan, sans-serif'
    fontWeight: 400
    lineHeight: 1
    letterSpacing: '0.02em'
rounded:
  sm: '8px'
  md: '12px'
  pill: '999px'
spacing:
  xs: '4px'
  sm: '8px'
  md: '16px'
  lg: '24px'
  xl: '48px'
  section: 'clamp(48px, 8vw, 96px)'
components:
  button-primary:
    backgroundColor: '{colors.deep-orange}'
    textColor: '{colors.white}'
    rounded: '{rounded.sm}'
    padding: '10px 18px'
    height: '44px'
  button-primary-hover:
    backgroundColor: '{colors.deep-orange-hover}'
    textColor: '{colors.white}'
  button-ghost:
    backgroundColor: 'transparent'
    textColor: '{colors.ink}'
    rounded: '{rounded.sm}'
    padding: '10px 18px'
    height: '44px'
  button-ghost-on-dark:
    backgroundColor: 'transparent'
    textColor: '{colors.paper}'
    rounded: '{rounded.sm}'
    padding: '10px 18px'
    height: '44px'
  card:
    backgroundColor: '{colors.white}'
    textColor: '{colors.ink}'
    rounded: '{rounded.md}'
    padding: '22px'
  panel:
    backgroundColor: '{colors.night}'
    textColor: '{colors.paper}'
    rounded: '{rounded.md}'
    padding: '28px'
  input:
    backgroundColor: '{colors.white}'
    textColor: '{colors.ink}'
    rounded: '{rounded.sm}'
    padding: '10px 12px'
    height: '44px'
  pill:
    backgroundColor: '{colors.table-head-light}'
    textColor: '{colors.ink}'
    rounded: '{rounded.pill}'
    padding: '3px 10px 3px 8px'
  pill-live:
    backgroundColor: '{colors.deep-orange}'
    textColor: '{colors.white}'
    rounded: '{rounded.pill}'
    padding: '3px 10px 3px 8px'
---

# Design System: RC Soar Score

## Overview

**Creative North Star: "The Cockpit Instrument Panel"**

RC Soar Score looks like the instruments a pilot trusts: a dark bezel, an engraved label, one orange needle, numbers that line up. The public site carries that panel onto the web. Dark sections are the instrument face (night black, hairline seams, an orange sweep); light sections are the paper the results are printed on. Nothing is decorative that costs legibility, because the real use scene is a phone in direct sun between flights.

The mood is purposeful, legible, outdoors. Density is comfortable rather than dense: generous section padding, tight groups inside cards, a 65ch reading measure. Colour is spent sparingly so the orange keeps its force as a pointer. The system must never read as a generic SaaS dashboard: no gradient text, no glass, no colour-only status, no stock illustration.

**Key Characteristics:**

- One Dayglo Wing Orange element per area of a screen; the rest is night, paper and ink.
- Three faces with fixed jobs: League Spartan for headings, Archivo for everything you read or count, Saira Stencil One for one stencilled number or code per screen.
- Always-dark instrument panels sit inside both light and dark themes.
- Status is text plus a drawn icon, never colour alone.
- Every animation respects reduced motion and nothing is hidden behind JavaScript.

## Colors

A night-black panel, warm paper, and a single high-visibility orange, with muted warm greys for secondary text.

### Primary

- **Dayglo Wing Orange** (#e8420c): the orange painted on a sailplane wing so it reads against sky and grass. Used for graphics, large display numbers and the instrument sweep. Never for small text.
- **Deep Orange** (#b83300): the orange for anything small enough to need contrast, which means the primary button and inline links on light surfaces (white on it passes 6.0:1). Hover darkens to #9e2c00.
- **Orange on Dark** (#ff6a33): the accent, link and focus colour on night surfaces, where deep orange would sink.

### Neutral

- **Night** (#1c1b1a): the instrument panel background and the dark-theme canvas.
- **Dial** (#0c0b0b): the black instrument face, and text on orange in dark mode.
- **Bezel** (#4a4643): the grey metal rim of the working-time dial.
- **Ink** (#201e1d): text and focus rings on paper.
- **Paper** (#f3f2f2): the light canvas and text on night.
- **Muted Light** (#605d5d) and **Muted Dark** (#b8b3ad): secondary text on paper and on night.
- **Hairline Light** (#d6d2cc), **Panel Line** (#3a3735), **Line Dark** (#49443f): borders and seams; the strong variants (#b9b3aa, #6a645d) outline ghost buttons and inputs.
- **Surface steps**: white and #e8e4dc on paper; #2b2927 and #35322f on night; #262422 inside an always-dark panel.
- **Completed green** (#0f4a2b on #d8efe1; #b1f1ce on #173a27): the one semantic colour, always beside a tick icon and the word.

### Named Rules

**The One Needle Rule.** One orange element per area of a screen. A second orange in the same area is a second needle, and the reader no longer knows where to look.

**The Small Text Rule.** Small text on orange, and orange on light paper, uses Deep Orange. Wing Orange is for graphics and display sizes only.

**The Panel Follows Daylight Rule.** Instrument panels are night black in the dark theme and scribed aluminium (table-head beige, hairline seams, ink text, deep orange) in the light one. The header stays night in both, so the dark lockup is always right, and the dial face stays black glass in any light.

## Typography

**Display Font:** League Spartan 700 and 800 (with Archivo, then system sans)
**Body Font:** Archivo 400 to 800 (with system sans)
**Label/Mono Font:** Saira Stencil One 400, the stencil accent

**Character:** Geometric, heavy headings with tight tracking over a plain, wide-set grotesque that handles tables and numbers without fuss. The stencil face is the one flourish: a round number, a station code, a place, stencilled like a tail marking.

### Hierarchy

- **Display** (800, clamp(36px, 6vw, 56px), 1.08): the page headline; balanced wrapping, -0.01em tracking.
- **Headline** (800, clamp(28px, 4vw, 40px), 1.08): section titles.
- **Title** (700, 24px, 1.08) and **Subtitle** (700, 18px): card and row titles.
- **Lede** (400, clamp(17px, 2vw, 20px), 1.5, muted): the sentence under a heading, pretty-wrapped, 65ch measure.
- **Body** (400, 16px, 1.55): copy; 15px inside cards and definition lists.
- **Label** (800, 13px, 18px, 0.18em, uppercase, muted): eyebrows, facts labels, role labels. 13px is the floor.
- **Number** (`.num`, 500, tabular numerals): every score, time, distance and height.
- **Stencil** (400, 1, 0.02em): one per screen, from 26px station codes to the hero place.

### Named Rules

**The 13px Floor Rule.** No label goes below 13px. Sunlight and sunglasses are the baseline, not the edge case.

**The One Stencil Rule.** Saira Stencil One appears once per screen area, for a number or a short code, never for a sentence.

## Layout

A single centred column, 1120px wide, with a 16px gutter that respects safe-area insets; a narrow 820px column for reading pages. Sections pad clamp(48px, 8vw, 96px) vertically, tight sections clamp(32px, 5vw, 56px). The header is a fixed 64px strip. Groups inside a card sit on an 8px rhythm (4, 8, 12, 16, 24); sections separate on 48 and above.

Grids collapse at 840px: three station cards become one column, the four hero facts become two columns and then stacked label and value rows under 520px, the flight plan turns from a horizontal route into a vertical track with a dashed line and waypoint dots. The desktop nav shows at 840px and above; below it a Contests button stays beside a native details menu. Dark instrument panels move above their copy on narrow screens.

## Elevation & Depth

Tonal layering. On paper, depth is a hairline border and a surface step; nothing floats. On the dark theme, tone alone is too close, so cards carry one soft black drop and a brighter hairline. Always-dark panels inside either theme use a bezel treatment, a panel line and their own surface, not a shadow.

### Shadow Vocabulary

- **Card, light** (`box-shadow: 0 1px 2px rgb(12 11 11 / 0.06), 0 8px 24px -12px rgb(12 11 11 / 0.25)`): available on station cards only; the hairline does the work.
- **Card, dark** (`box-shadow: 0 1px 2px rgb(0 0 0 / 0.35), 0 8px 24px -12px rgb(0 0 0 / 0.6)`): the dark theme's card lift.

### Named Rules

**The Hairline First Rule.** Separate with a 1px line and a surface step before reaching for a shadow. Shadows exist only where tone cannot do the job.

## Shapes

Machined corners: 12px on cards and panels, 8px on buttons, inputs and the focus ring's corners, a full pill (999px) on status chips. Borders are 1px hairlines; the only thick line is the 2px dashed flight track. Instrument bezels add four corner screws and a black face. Bars are 10px tall with 5px ends; a penalty bar fills from the right and is hatched at 135 degrees. The hero and closing panels sit on a 48px seams grid masked to fade from the top.

## Components

### Buttons

- **Shape:** 8px corners, 44px minimum height, 15px semibold Archivo, 10px by 18px padding; small variant 7px by 14px at 14px.
- **Primary:** Deep Orange with white text; hover darkens to #9e2c00. One per area.
- **Ghost:** transparent with a strong hairline border and ink text; hover turns the border to ink. On dark panels the ghost uses paper text and the panel line, hover brightens the border to paper.
- **Active:** 1px downward nudge. **Disabled:** 50% opacity, not-allowed cursor.
- **External:** any button or link that leaves the site carries a drawn leave-site arrow and a hidden "(opens the contest app)" for screen readers.

### Chips

- **Style:** pill, 13px semibold, a 14px drawn icon before the word.
- **State:** neutral on surface-2 with a hairline (Coming); In progress in deep orange with white; Completed in the green pair with a tick.

### Cards / Containers

- **Corner Style:** 12px.
- **Background:** surface (white on paper, #2b2927 on night).
- **Shadow Strategy:** none in light, the dark card drop in dark; station cards opt in to the light shadow.
- **Border:** 1px hairline.
- **Internal Padding:** 22px; a station card's bezel bleeds to the card edge as a night strip with the stencil code.

### Panels

The always-dark instrument surface: night background, paper text, panel line border, 12px corners, 28px padding. Focus rings inside a panel switch to Orange on Dark.

### Inputs / Fields

- **Style:** 1px strong hairline, surface background, 8px corners, 44px minimum height, 10px by 12px padding.
- **Focus:** 2px outline in the focus colour (ink on paper, orange on night) at 1px offset, border matches.
- **Error:** 13px semibold text in the accent colour under the field; hints are 13px muted.

### Navigation

Night header, 64px, mark and wordmark on the left, three text links and a small ghost Sign in on the right from 840px up. Below that, a Contests ghost button and a hamburger that opens a native details sheet, so it works without JavaScript. Links underline on hover; the skip link is a 44px target.

### Working-Time Dial (signature)

A 320px SVG instrument: grey bezel with four screws, black face, white tick marks, an orange sweep for time used, a white glider silhouette as the hand, an engraved "WORKING TIME" label and a stencil readout. It sets the palette for every dark panel and is the one place Wing Orange owns a large region.

## Do's and Don'ts

### Do:

- **Do** keep one orange element per area of a screen, and make it the thing to act on or read.
- **Do** put the word next to every status icon and colour.
- **Do** keep every label at 13px or above and every target at 44px or above.
- **Do** draw icons as 16 or 24 unit stroke SVGs at 1.8 to 2px; one stroke family across the site.
- **Do** use tabular numerals for anything counted or timed.
- **Do** give every scroll animation a no-JavaScript and reduced-motion fallback that shows the content.

### Don't:

- **Don't** retype the wordmark; use the logo files from the brand kit.
- **Don't** put Wing Orange on small text or on light paper; use Deep Orange.
- **Don't** add gradient text, glass blur, neon glows or stock illustration; the panel is matte.
- **Don't** change a panel's night background when the theme changes.
- **Don't** use colour alone to say in progress, completed, dropped, re-flight or penalty.
- **Don't** add a second display face or a fourth font; the three faces are fixed by the kit.
