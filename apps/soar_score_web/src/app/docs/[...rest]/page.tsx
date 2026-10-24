import { redirect } from "next/navigation";

/** Anything else under /docs goes to the docs not-found page (docs-help.md). */
export default function DocsCatchAll() {
  redirect("/docs/not-found");
}
