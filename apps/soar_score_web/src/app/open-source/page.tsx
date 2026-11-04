import type { Metadata } from "next";

import { OpenSourceView } from "@/components/open-source/open-source-view";
import licences from "@/content/licences.json";
import type { LicenceData } from "@/lib/licences";
import { repositoryUrl } from "@/lib/site";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Open source", "The licences of RC Soar Score and of the open source software it includes.");

/**
 * Open source licences and credits (`/open-source`, #687). The data is
 * generated from the lockfiles by `scripts/generate_licences.dart`; the apps
 * link to the sections `#contest-app` and `#self-scoring`.
 */
export default function OpenSourcePage() {
  return (
    <OpenSourceView
      data={licences as LicenceData}
      repositoryUrl={repositoryUrl}
      commit={process.env.VERCEL_GIT_COMMIT_SHA}
    />
  );
}
