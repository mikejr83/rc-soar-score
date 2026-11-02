/**
 * Types and helpers for the generated third-party licence data
 * (`src/content/licences.json`, written by `scripts/generate_licences.dart`,
 * see `AGENTS.md`). The /open-source page (#687) renders it.
 */

export interface LicenceEntry {
  name: string;
  version: string;
  license: string;
  homepage: string;
  /** `dart` and `npm` packages come from the lockfiles; `bundled` ones are listed by hand in the generator. */
  source: "dart" | "npm" | "bundled";
  direct?: boolean;
  note?: string;
  /** Indexes into `LicenceData.texts`. */
  texts: number[];
}

export interface LicenceProduct {
  id: string;
  name: string;
  summary: string;
  entries: LicenceEntry[];
}

export interface LicenceData {
  schema: number;
  /** Fingerprints (FNV-1a 64, LF-normalised) of the files the data was generated from. */
  inputs: Record<string, string>;
  products: LicenceProduct[];
  texts: string[];
}

/** Texts at least this long that several packages share are shown once per product. */
export const SHARED_TEXT_MIN_LENGTH = 3000;

/**
 * The text indexes of a product that are rendered once, in a block of their
 * own, instead of inside each package: long (Apache-2.0, LGPL, ...) texts used
 * by two or more entries.
 */
export function sharedTexts(product: LicenceProduct, texts: string[]): number[] {
  const uses = new Map<number, number>();
  for (const entry of product.entries) {
    for (const i of entry.texts) uses.set(i, (uses.get(i) ?? 0) + 1);
  }
  return [...uses.entries()]
    .filter(([i, n]) => n >= 2 && texts[i].length >= SHARED_TEXT_MIN_LENGTH)
    .map(([i]) => i)
    .sort((a, b) => a - b);
}

/** FNV-1a 64 over the UTF-8 bytes of `text` with CRLF turned into LF; matches the generator. */
export function fingerprint(text: string): string {
  const bytes = new TextEncoder().encode(text.replace(/\r\n/g, "\n"));
  let h = BigInt("0xcbf29ce484222325");
  const prime = BigInt("0x100000001b3");
  const mask = BigInt("0xffffffffffffffff");
  for (const b of bytes) {
    h ^= BigInt(b);
    h = (h * prime) & mask;
  }
  return h.toString(16).padStart(16, "0");
}
