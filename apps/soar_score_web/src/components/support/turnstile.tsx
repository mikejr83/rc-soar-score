"use client";

import Script from "next/script";
import { forwardRef, useEffect, useImperativeHandle, useRef, useState } from "react";

/** The parts of Cloudflare's explicit-render API this form uses. */
type TurnstileApi = {
  render: (element: HTMLElement, options: Record<string, unknown>) => string;
  reset: (widgetId?: string) => void;
  remove: (widgetId?: string) => void;
};

declare global {
  interface Window {
    turnstile?: TurnstileApi;
  }
}

/** The action the server checks; it must match the widget's action. */
export const turnstileAction = "support";

export type TurnstileHandle = {
  /** Clears the spent token and renders a fresh challenge. */
  reset: () => void;
};

type Props = {
  /** The public site key (NEXT_PUBLIC_TURNSTILE_SITE_KEY), or undefined. */
  siteKey: string | undefined;
  /** Receives the token when the challenge passes, null when it is spent. */
  onToken: (token: string | null) => void;
};

/** An explicitly rendered Turnstile widget (support form only). */
export const Turnstile = forwardRef<TurnstileHandle, Props>(function Turnstile(
  { siteKey, onToken },
  ref,
) {
  const container = useRef<HTMLDivElement>(null);
  const widgetId = useRef<string | null>(null);
  const tokenHandler = useRef(onToken);
  const [scriptReady, setScriptReady] = useState(false);
  const [scriptFailed, setScriptFailed] = useState(false);

  useEffect(() => {
    tokenHandler.current = onToken;
  }, [onToken]);

  useEffect(() => {
    const element = container.current;
    if (!siteKey || !scriptReady || !element || !window.turnstile) return;
    const api = window.turnstile;
    widgetId.current = api.render(element, {
      sitekey: siteKey,
      action: turnstileAction,
      callback: (token: string) => tokenHandler.current(token),
      "expired-callback": () => tokenHandler.current(null),
      "error-callback": () => tokenHandler.current(null),
    });
    const id = widgetId.current;
    return () => {
      if (id) api.remove(id);
      widgetId.current = null;
    };
  }, [siteKey, scriptReady]);

  useImperativeHandle(
    ref,
    () => ({
      reset() {
        tokenHandler.current(null);
        if (widgetId.current && window.turnstile) window.turnstile.reset(widgetId.current);
      },
    }),
    [],
  );

  if (!siteKey) {
    return (
      <p className="error" role="alert">
        The spam check is not available on this site, so requests cannot be sent right now.
      </p>
    );
  }

  return (
    <div>
      <Script
        src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"
        strategy="afterInteractive"
        onReady={() => setScriptReady(true)}
        onError={() => setScriptFailed(true)}
      />
      <div ref={container} />
      {scriptFailed && (
        <p className="error" role="alert">
          The spam check could not load. Check your connection and reload the page.
        </p>
      )}
    </div>
  );
});
