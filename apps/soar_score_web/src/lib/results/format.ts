/** Whole numbers plain, otherwise one decimal. */
export const formatScore = (value: number): string =>
  Number.isInteger(value) ? String(value) : value.toFixed(1);

/** `99.8%`, `100%`. */
export function formatPercent(value: number): string {
  const text = value.toFixed(1);
  return `${text.endsWith(".0") ? text.slice(0, -2) : text}%`;
}

/** Seconds as `m:ss`, with tenths when the time has them. */
export function formatTime(value: unknown): string {
  if (typeof value !== "number") return value == null ? "-" : String(value);
  const minutes = Math.floor(value / 60);
  const seconds = value - minutes * 60;
  const text = Number.isInteger(seconds)
    ? String(seconds).padStart(2, "0")
    : seconds.toFixed(1).padStart(4, "0");
  return `${minutes}:${text}`;
}

const day = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

/** `2026-10-10`, or `2026-10-10 to 2026-10-11` when the contest spans days. */
export function formatDates(start?: Date, end?: Date): string {
  if (!start) return end ? day(end) : "";
  if (!end || day(start) === day(end)) return day(start);
  return `${day(start)} to ${day(end)}`;
}

/** `launch_height` reads as `Launch height` until #456 carries labels. */
export function label(key: string): string {
  const words = key.replaceAll("_", " ");
  return words.charAt(0).toUpperCase() + words.slice(1);
}
