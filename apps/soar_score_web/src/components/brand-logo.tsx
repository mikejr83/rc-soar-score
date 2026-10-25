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

const lockupRatio = 3199 / 920;

/** The mark beside the wordmark. `height` is in CSS pixels. */
export function BrandLockup({
  height = 48,
  onDark,
  className,
  priority = false,
}: {
  height?: number;
  /** Pin the ground; undefined follows the colour scheme. */
  onDark?: boolean;
  className?: string;
  priority?: boolean;
}) {
  const width = Math.round(height * lockupRatio);
  const alt = `${siteName} logo`;
  if (onDark !== undefined) {
    return (
      <Image
        src={`/brand/rc-soar-score-lockup-${onDark ? "dark" : "light"}-transparent.svg`}
        width={width}
        height={height}
        alt={alt}
        className={className}
        priority={priority}
      />
    );
  }
  return (
    <picture className={className}>
      <source
        srcSet="/brand/rc-soar-score-lockup-dark-transparent.svg"
        media="(prefers-color-scheme: dark)"
      />
      <Image
        src="/brand/rc-soar-score-lockup-light-transparent.svg"
        width={width}
        height={height}
        alt={alt}
        priority={priority}
      />
    </picture>
  );
}
