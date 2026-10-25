import localFont from "next/font/local";

// The three brand fonts (OFL), copied from packages/soar_score_ui/assets/fonts
// so the site, the apps and the kit stay on the same files.

/** Headings: League Spartan 700 and 800. */
export const display = localFont({
  src: [
    { path: "../fonts/LeagueSpartan-Bold.ttf", weight: "700" },
    { path: "../fonts/LeagueSpartan-ExtraBold.ttf", weight: "800" },
  ],
  variable: "--font-display",
  display: "swap",
});

/** Body, tables, buttons and every number: Archivo 400 to 800. */
export const body = localFont({
  src: [
    { path: "../fonts/Archivo-Regular.ttf", weight: "400" },
    { path: "../fonts/Archivo-Medium.ttf", weight: "500" },
    { path: "../fonts/Archivo-SemiBold.ttf", weight: "600" },
    { path: "../fonts/Archivo-Bold.ttf", weight: "700" },
    { path: "../fonts/Archivo-ExtraBold.ttf", weight: "800" },
  ],
  variable: "--font-body",
  display: "swap",
});

/** Stencil accent, one number or short word per screen. */
export const accent = localFont({
  src: [{ path: "../fonts/SairaStencilOne-Regular.ttf", weight: "400" }],
  variable: "--font-accent",
  display: "swap",
});
