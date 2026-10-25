"use client";

import { useState, type FormEvent } from "react";

import styles from "./support-form.module.css";

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

/** The error for one field, or null. Exported for the test. */
export function validate(values: Values): Partial<Record<Field, string>> {
  const errors: Partial<Record<Field, string>> = {};
  if (!values.name.trim()) errors.name = "Enter your name.";
  if (!values.email.trim()) errors.email = "Enter your email address.";
  else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email.trim()))
    errors.email = "Enter an email address like name@example.com.";
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

  const errors = validate(values);
  const shown = (field: Field) => (attempted || touched[field]) && errors[field];
  const set = (field: keyof Values) => (value: string) =>
    setValues((v) => ({ ...v, [field]: value }));
  const touch = (field: Field) => () => setTouched((t) => ({ ...t, [field]: true }));

  function submit(event: FormEvent) {
    event.preventDefault();
    setAttempted(true);
    if (Object.keys(errors).length > 0) {
      document.getElementById("support-errors")?.focus();
      return;
    }
    // TODO(#220): send the request to the support channel once one is chosen.
    setSubmitted(true);
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
          The support channel is still being set up, so nothing has been sent
          anywhere yet. For anything urgent, contact your contest director
          directly.
        </p>
      </div>
    );
  }

  const errorList = attempted ? (Object.keys(errors) as Field[]) : [];

  return (
    <form className={styles.form} onSubmit={submit} noValidate>
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

      <p className="hint">
        Spam protection and delivery are not connected yet (#220).
      </p>

      <div>
        <button type="submit" className="btn btn--primary">
          Submit request
        </button>
      </div>
    </form>
  );
}
