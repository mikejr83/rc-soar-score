import type { Metadata } from "next";

import { SupportForm } from "@/components/support/support-form";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Support");

/** Support request page (`/support`, plan/ui/public-site/support.md). */
export default function SupportPage() {
  return (
    <div className="wrap wrap--narrow section--tight" style={{ paddingBlock: 40 }}>
      <p className="eyebrow">
        <b>Support</b> · Tell us what happened
      </p>
      <h1 style={{ marginTop: 8 }}>Request support</h1>
      <p className="lede" style={{ marginTop: 16 }}>
        Questions about running a contest, trouble entering a score, a result
        that looks wrong, or an idea.
      </p>
      <p className="lede" style={{ marginTop: 12 }}>
        I read support requests personally and reply as time allows. If your
        contest is underway, contact your contest director for immediate help.
        If you arranged live support with me in advance, use the contact method
        we agreed on.
      </p>
      <SupportForm />
    </div>
  );
}
