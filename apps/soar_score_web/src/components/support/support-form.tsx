"use client";

import Link from "next/link";
import { useRef, useState, type FormEvent } from "react";

import styles from "./support-form.module.css";
import { normalizeSupportEmail, postSupport, type SubmitOutcome } from "./submit";
import { Turnstile, type TurnstileHandle } from "./turnstile";

export const userTypes = ["Contest Director", "Pilot", "Participant"] as const;

/** The request types and their help text (support.md). */
export const requestTypes = {
  "Public site issue": "Contests not displaying, site errors, etc.",
  "Contest Management": "Questions about running contests, admin, etc.",
  "Online Score Entry": "Trouble entering scores or questions about online scoring.",
  "Feature Request": "New features are always coming. Help shape the application!",
  "User Account Inquiry": "Trouble registering, accessing the site, etc.",
  "General Inquiry": "Questions or comments that don't fall into another category.",
  "Emergency Contest Issue": "A critical issue around running a contest or entering scores.",
} as const;

export const messageLimit = 2000;

type Field = "name" | "email" | "requestType" | "message";
type Values = Record<Field, string> & { userType: string };

const labels: Record<Field, string> = {
  name: "Name",
  email: "Email",
  requestType: "Request type",
  message: "Message",
};

/** The errors for the fields, or an empty object. Exported for the test. */
export function validate(values: Values): Partial<Record<Field, string>> {
  const errors: Partial<Record<Field, string>> = {};
  if (!values.name.trim()) errors.name = "Enter your name.";
  if (!values.email.trim()) errors.email = "Enter your email address.";
  else if (normalizeSupportEmail(values.email) === null)
    errors.email =
      "Enter one email address using only English letters, numbers and common symbols, such as name@example.com.";
  if (!values.requestType) errors.requestType = "Choose a request type.";
  if (!values.message.trim()) errors.message = "Describe what happened.";
  else if (values.message.length > messageLimit)
    errors.message = `Keep the message under ${messageLimit} characters.`;
  return errors;
}

const empty: Values = { name: "", email: "", userType: "", requestType: "", message: "" };

export function SupportForm() {
  const [values, setValues] = useState<Values>(empty);
  const [touched, setTouched] = useState<Partial<Record<Field, boolean>>>({});
  const [attempted, setAttempted] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [pending, setPending] = useState(false);
  const inFlight = useRef(false);
  const [token, setToken] = useState<string | null>(null);
  const [serverError, setServerError] = useState<string | null>(null);
  const [retryWait, setRetryWait] = useState<number | null>(null);
  const [unconfirmed, setUnconfirmed] = useState(false);
  const challenge = useRef<TurnstileHandle>(null);
  const serverErrorRef = useRef<HTMLDivElement>(null);
  const siteKey = process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY;

  const errors = validate(values);
  const shown = (field: Field) => (attempted || touched[field]) && errors[field];
  const set = (field: keyof Values) => (value: string) =>
    setValues((v) => ({ ...v, [field]: value }));
  const touch = (field: Field) => () => setTouched((t) => ({ ...t, [field]: true }));

  function fail(outcome: Extract<SubmitOutcome, { kind: "retry" | "unconfirmed" }>) {
    // An unconfirmed send may already have spent the challenge, so a retry
    // always needs a new token, whatever the outcome.
    const resetChallenge = outcome.kind === "unconfirmed" || outcome.resetChallenge;
    if (outcome.kind === "unconfirmed") {
      setUnconfirmed(true);
      setServerError(
        "We could not confirm that your request was delivered. It may have been sent, so check before submitting again.",
      );
      setRetryWait(null);
    } else {
      setUnconfirmed(false);
      setServerError(outcome.message);
      setRetryWait(outcome.waitSeconds ?? null);
    }
    if (resetChallenge) {
      // A spent token cannot be reused; the widget issues a new one.
      setToken(null);
      challenge.current?.reset();
    }
    requestAnimationFrame(() => serverErrorRef.current?.focus());
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (inFlight.current) return;
    setAttempted(true);
    setServerError(null);
    if (Object.keys(errors).length > 0) {
      document.getElementById("support-errors")?.focus();
      return;
    }
    const email = normalizeSupportEmail(values.email);
    if (!token || email === null) {
      fail({
        kind: "retry",
        message: "Complete the spam check before submitting.",
        resetChallenge: false,
      });
      return;
    }
    inFlight.current = true;
    setPending(true);
    try {
      const outcome = await postSupport(fetch, {
        name: values.name.trim(),
        email,
        userType: values.userType,
        requestType: values.requestType,
        message: values.message,
        captchaToken: token,
      });
      if (outcome.kind === "accepted") {
        setSubmitted(true);
      } else {
        fail(outcome);
      }
    } finally {
      inFlight.current = false;
      setPending(false);
    }
  }

  if (submitted) {
    return (
      <div className={`card ${styles.thanks}`} role="status">
        <p className="stencil" style={{ fontSize: 40, color: "var(--accent-graphic)" }}>
          Received
        </p>
        <h2 style={{ fontSize: 24, marginTop: 12 }}>
          Thank you. Your support request has been received.
        </h2>
        <p style={{ marginTop: 10, color: "var(--text-muted)" }}>
          I read support requests personally and reply as time allows. If your
          contest is underway, contact your contest director for immediate help.
          If you arranged live support with me in advance, use the contact
          method we agreed on.
        </p>
      </div>
    );
  }

  const errorList = attempted ? (Object.keys(errors) as Field[]) : [];

  return (
    <form className={styles.form} onSubmit={submit} noValidate>
      {serverError && (
        <div
          ref={serverErrorRef}
          className={styles.summary}
          role="alert"
          tabIndex={-1}
        >
          <strong>{serverError}</strong>
          {retryWait !== null && <p>You can try again in {retryWait} seconds.</p>}
          {unconfirmed && <p>Submitting again may send a second copy.</p>}
        </div>
      )}

      {errorList.length > 0 && (
        <div
          id="support-errors"
          className={styles.summary}
          role="alert"
          tabIndex={-1}
        >
          <strong>Please fix the following:</strong>
          <ul>
            {errorList.map((f) => (
              <li key={f}>
                <a href={`#support-${f}`}>
                  {labels[f]}: {errors[f]}
                </a>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="field">
        <label htmlFor="support-name">Name</label>
        <input
          id="support-name"
          className="input"
          autoComplete="name"
          required
          value={values.name}
          onChange={(e) => set("name")(e.target.value)}
          onBlur={touch("name")}
          aria-invalid={shown("name") ? true : undefined}
          aria-describedby={shown("name") ? "support-name-error" : undefined}
        />
        {shown("name") && (
          <span className="error" id="support-name-error">
            {errors.name}
          </span>
        )}
      </div>

      <div className="field">
        <label htmlFor="support-email">Email</label>
        <input
          id="support-email"
          className="input"
          type="email"
          autoComplete="email"
          required
          value={values.email}
          onChange={(e) => set("email")(e.target.value)}
          onBlur={touch("email")}
          aria-invalid={shown("email") ? true : undefined}
          aria-describedby={shown("email") ? "support-email-error" : undefined}
        />
        {shown("email") && (
          <span className="error" id="support-email-error">
            {errors.email}
          </span>
        )}
      </div>

      <div className="field">
        <label htmlFor="support-userType">
          I am a <span className="hint">(optional)</span>
        </label>
        <select
          id="support-userType"
          className="input"
          value={values.userType}
          onChange={(e) => set("userType")(e.target.value)}
        >
          <option value=""></option>
          {userTypes.map((t) => (
            <option key={t}>{t}</option>
          ))}
        </select>
      </div>

      <div className="field">
        <label htmlFor="support-requestType">Request type</label>
        <select
          id="support-requestType"
          className="input"
          required
          value={values.requestType}
          onChange={(e) => set("requestType")(e.target.value)}
          onBlur={touch("requestType")}
          aria-invalid={shown("requestType") ? true : undefined}
          aria-describedby={
            shown("requestType") ? "support-requestType-error" : "support-requestType-hint"
          }
        >
          <option value="">Choose one</option>
          {Object.keys(requestTypes).map((t) => (
            <option key={t}>{t}</option>
          ))}
        </select>
        <span className="hint" id="support-requestType-hint">
          {values.requestType
            ? requestTypes[values.requestType as keyof typeof requestTypes]
            : "Pick the closest match; it routes the request."}
        </span>
        {shown("requestType") && (
          <span className="error" id="support-requestType-error">
            {errors.requestType}
          </span>
        )}
      </div>

      <div className="field">
        <label htmlFor="support-message">Message</label>
        <textarea
          id="support-message"
          className="input"
          required
          maxLength={messageLimit}
          value={values.message}
          onChange={(e) => set("message")(e.target.value)}
          onBlur={touch("message")}
          aria-invalid={shown("message") ? true : undefined}
          aria-describedby={`support-message-count${shown("message") ? " support-message-error" : ""}`}
        />
        <span className={`hint num ${styles.count}`} id="support-message-count">
          {values.message.length} / {messageLimit}
        </span>
        {shown("message") && (
          <span className="error" id="support-message-error">
            {errors.message}
          </span>
        )}
      </div>

      <div className="field">
        <span className="hint">Spam check</span>
        <Turnstile ref={challenge} siteKey={siteKey} onToken={setToken} />
      </div>

      <p className="hint">
        We use these details only to answer your request. See the{" "}
        <Link href="/privacy">Privacy Policy</Link>.
      </p>

      <div>
        <button type="submit" className="btn btn--primary" disabled={pending}>
          {pending ? "Sending..." : "Submit request"}
        </button>
      </div>
    </form>
  );
}
