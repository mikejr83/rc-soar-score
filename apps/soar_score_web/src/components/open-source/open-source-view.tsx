import type { ReactNode } from "react";

import {
  type LicenceData,
  type LicenceEntry,
  type LicenceProduct,
  sharedTexts,
} from "@/lib/licences";
import docs from "@/components/docs/docs.module.css";

import styles from "./open-source.module.css";

interface ViewProps {
  data: LicenceData;
  repositoryUrl: string;
  /** Commit the site was built from (Vercel sets it); links to the exact source. */
  commit?: string;
}

const sharedId = (product: LicenceProduct, text: number) =>
  `${product.id}-text-${text}`;

function Entry({
  product,
  entry,
  texts,
  shared,
}: {
  product: LicenceProduct;
  entry: LicenceEntry;
  texts: string[];
  shared: Set<number>;
}) {
  return (
    <li>
      <details className={styles.entry}>
        <summary>
          <span className={styles.name}>
            {entry.name}
            {entry.version ? ` ${entry.version}` : ""}
          </span>
          <span className={styles.licence}>{entry.license}</span>
        </summary>
        <div className={styles.body}>
          <p>
            <a href={entry.homepage} rel="noopener noreferrer">
              {entry.homepage}
            </a>
          </p>
          {entry.note ? <p>{entry.note}</p> : null}
          {entry.texts.map((i) =>
            shared.has(i) ? (
              <p key={i}>
                Licence text: <a href={`#${sharedId(product, i)}`}>see below</a>.
              </p>
            ) : (
              <pre key={i} className={styles.text}>
                {texts[i]}
              </pre>
            ),
          )}
        </div>
      </details>
    </li>
  );
}

function Product({
  product,
  texts,
}: {
  product: LicenceProduct;
  texts: string[];
}) {
  const shared = sharedTexts(product, texts);
  const sharedSet = new Set(shared);
  return (
    <section id={product.id} className={styles.product}>
      <h2>{product.name}</h2>
      <p>{product.summary}</p>
      <p>
        {product.entries.length} components. Open an entry for its home page
        and licence text.
      </p>
      <ul className={styles.list}>
        {product.entries.map((entry) => (
          <Entry
            key={`${entry.source}:${entry.name}:${entry.version}`}
            product={product}
            entry={entry}
            texts={texts}
            shared={sharedSet}
          />
        ))}
      </ul>
      {shared.length > 0 ? (
        <div className={styles.shared}>
          <h3>Licence texts shared by several components</h3>
          {shared.map((i) => (
            <div key={i} id={sharedId(product, i)}>
              <p>
                Used by:{" "}
                {product.entries
                  .filter((e) => e.texts.includes(i))
                  .map((e) => e.name)
                  .join(", ")}
              </p>
              <pre className={styles.text}>{texts[i]}</pre>
            </div>
          ))}
        </div>
      ) : null}
    </section>
  );
}

/** The /open-source page body. A pure function of the generated data, so it is easy to test. */
export function OpenSourceView({
  data,
  repositoryUrl,
  commit,
}: ViewProps): ReactNode {
  const sourceUrl = commit
    ? `${repositoryUrl}/tree/${commit}`
    : repositoryUrl;
  return (
    <div className="wrap wrap--narrow" style={{ paddingBlock: 40 }}>
      <article className={docs.article}>
        <h1>Open source</h1>
        <p>
          RC Soar Score is open source, and it is built on the work of many
          other open source projects. This page lists them, with the licence
          text each one asks us to reproduce.
        </p>

        <h2 id="our-licences">Our licences</h2>
        <ul>
          <li>
            The code is licensed under the{" "}
            <a href="https://www.gnu.org/licenses/agpl-3.0.html">
              GNU Affero General Public License v3.0
            </a>{" "}
            (AGPL-3.0). The text is in the{" "}
            <a href={`${repositoryUrl}/blob/master/LICENSE`}>LICENSE</a> file.
          </li>
          <li>
            The planning and rule documentation is licensed under{" "}
            <a href="https://creativecommons.org/licenses/by/4.0/">CC BY 4.0</a>.
          </li>
          <li>
            Source code: <a href={repositoryUrl}>{repositoryUrl}</a>.{" "}
            {commit ? (
              <>
                The version running on this site is{" "}
                <a href={sourceUrl}>commit {commit.slice(0, 7)}</a>.
              </>
            ) : (
              <>
                The version running on this site is built from the
                master branch.
              </>
            )}{" "}
            If you use a modified version over a network, the AGPL asks you to
            offer your users its source.
          </li>
          <li>
            Published contest results are the data of the contest director and
            the participants and are not covered by these licences.
          </li>
        </ul>

        <h2 id="third-party">Third-party software</h2>
        <p>
          Each product below lists every package it includes, direct and
          indirect, generated from the lock files of the project. Versions are
          those of the current release.
        </p>
        <ul className={styles.toc}>
          {data.products.map((p) => (
            <li key={p.id}>
              <a href={`#${p.id}`}>{p.name}</a>
            </li>
          ))}
        </ul>

        {data.products.map((p) => (
          <Product key={p.id} product={p} texts={data.texts} />
        ))}
      </article>
    </div>
  );
}
