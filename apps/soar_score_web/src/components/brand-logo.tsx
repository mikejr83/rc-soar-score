import Image from "next/image";

import { siteName } from "@/lib/site";

/**
 * The logo files from the brand kit (public/brand, copied from
 * packages/soar_score_ui/assets/logos). The mark's own colours never change;
 * only the lockup's wordmark differs between light and dark grounds, so the
 * lockup is drawn twice and CSS shows the one for the current scheme unless
 * `onDark` pins it.
 */

type MarkSize = "full" | "small" | "tiny";

const markFile: Record<MarkSize, string> = {
  full: "/brand/rc-soar-score-mark.svg",
  small: "/brand/rc-soar-score-mark-small.svg",
  tiny: "/brand/rc-soar-score-mark-tiny.svg",
};

/** The instrument mark on its own. Below 64px use small, below 32px tiny. */
export function BrandMark({
  size = 40,
  className,
  decorative = false,
}: {
  size?: number;
  className?: string;
  decorative?: boolean;
}) {
  const variant: MarkSize = size >= 64 ? "full" : size >= 32 ? "small" : "tiny";
  return (
    <Image
      src={markFile[variant]}
      width={size}
      height={size}
      alt={decorative ? "" : `${siteName} mark`}
      className={className}
      priority={size >= 64}
    />
  );
}

/**
 * The mark beside the wordmark. `height` is in CSS pixels. The tagline line
 * is 6% of the lockup's height, so below about 120px use `compact`, the kit
 * lockup without it.
 */
export function BrandLockup({
  height = 48,
  onDark,
  compact = false,
  className,
  priority = false,
}: {
  height?: number;
  /** Pin the ground; undefined follows the theme (OS scheme or the switch). */
  onDark?: boolean;
  compact?: boolean;
  className?: string;
  priority?: boolean;
}) {
  const [ratio, suffix] = compact ? [3100 / 761, "compact"] : [3199 / 920, "transparent"];
  const width = Math.round(height * ratio);
  const alt = `${siteName} logo`;
  const image = (ground: "dark" | "light", cls?: string) => (
    <Image
      src={`/brand/rc-soar-score-lockup-${ground}-${suffix}.svg`}
      width={width}
      height={height}
      alt={alt}
      className={cls}
      priority={priority}
    />
  );
  if (onDark !== undefined) return image(onDark ? "dark" : "light", className);
  return (
    <>
      {image("light", `only-light ${className ?? ""}`)}
      {image("dark", `only-dark ${className ?? ""}`)}
    </>
  );
}
