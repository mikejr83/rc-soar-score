import type { AnchorHTMLAttributes, ReactNode } from "react";

type Props = AnchorHTMLAttributes<HTMLAnchorElement> & {
  href: string;
  /** Where the link goes, read out to screen readers: "the contest app". */
  destination: string;
  children: ReactNode;
};

/**
 * A link that leaves this site (the contest app, the self-scoring app, GitHub).
 * It carries a drawn leave-site arrow and tells screen readers where it goes,
 * so an external host is never a surprise.
 */
export function ExternalLink({ destination, children, ...rest }: Props) {
  return (
    <a rel="noopener external" {...rest}>
      {children}
      <svg className="ext-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
        <path d="M5 3h8v8M13 3 3 13" />
      </svg>
      <span className="visually-hidden"> (opens {destination})</span>
    </a>
  );
}
