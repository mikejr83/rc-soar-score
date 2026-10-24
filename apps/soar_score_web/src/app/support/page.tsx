import type { Metadata } from "next";

import { SupportForm } from "@/components/support/support-form";

export const metadata: Metadata = { title: "Support" };

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
        that looks wrong, or an idea. A contest running right now gets
        priority: choose Emergency Contest Issue.
      </p>
      <SupportForm />
    </div>
  );
}
