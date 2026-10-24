/**
 * The two public API shapes, keyed exactly as served (snake_case). The nested
 * contest, participant, team, score and standing maps stay loosely typed, as
 * they did in the Flutter app; `published-contest.ts` shapes them.
 */

export type JsonMap = Record<string, unknown>;

/** One line of `GET /public/publications`. */
export interface PublicPublicationSummary {
  publication_id: string;
  published_at: string;
  projection_revision: number;
  /** Name, dates, time zone, place. */
  contest: JsonMap;
  discipline_type: string;
}

/** The answer to `GET /public/publications/{id}`. */
export interface PublicPublication {
  publication_id: string;
  visibility: string;
  projection_revision: number;
  published_at: string;
  contest: JsonMap;
  discipline_type: string;
  calculation_version: string;
  results_hidden_through_round?: number | null;
  participants?: JsonMap[];
  teams?: JsonMap[];
  matrix?: JsonMap | null;
  scores?: JsonMap[];
  /** `{ rounds: [...] }`: the standings after each completed round. */
  standings?: { rounds?: JsonMap[] };
  calculation?: JsonMap | null;
}
