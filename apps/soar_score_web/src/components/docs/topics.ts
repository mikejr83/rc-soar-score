import { contestAppUrl, downloadUrl } from "@/lib/site";

/** One entry of the docs navigation (plan/ui/public-site/docs-help.md). */
export type Topic = {
  href: string;
  label: string;
  description: string;
  /** Who it is for; shown as the card eyebrow. */
  audience: "Director" | "Pilot" | "Everyone";
  external?: boolean;
};

/** The help topics, in sidebar order. */
export const helpTopics: Topic[] = [
  {
    href: "/docs/competitions",
    label: "Contest Director Getting Started",
    description: "Create, configure, draw, score and publish a contest.",
    audience: "Director",
  },
  {
    href: "/docs/participant-scoring",
    label: "Help Me Enter My Score",
    description: "Open your invitation, find your round and enter a flight.",
    audience: "Pilot",
  },
  {
    href: "/docs/user-accounts",
    label: "I Need An Account?",
    description: "Who needs one, who does not, and how to sign up.",
    audience: "Everyone",
  },
  {
    href: "/docs/contests-and-scores",
    label: "Finding Contests and Results",
    description: "Search for a contest and read the three results views.",
    audience: "Everyone",
  },
];

/** The landing page navigation: actions first, then the help topics. */
export const landingLinks: Topic[] = [
  {
    href: contestAppUrl,
    label: "Register for an account",
    description: "Sign up or sign in through the contest administration app.",
    audience: "Director",
    external: true,
  },
  {
    href: downloadUrl,
    label: "Download the offline application",
    description: "The Windows app for running a contest with no signal.",
    audience: "Director",
    external: true,
  },
  {
    href: "/results/contests",
    label: "Search contests",
    description: "Live and completed contests, newest first.",
    audience: "Everyone",
  },
  ...helpTopics,
  {
    href: "/support",
    label: "Request Support",
    description: "Questions, errors and feature requests.",
    audience: "Everyone",
  },
];
