#!/usr/bin/env python3
"""Writes tester-friendly release notes for a published GitHub release.

Used by .github/workflows/release-notes.yml; see docs/releasing.md.

  scripts/generate_release_notes.py TAG [--dry-run]

Needs GH_TOKEN and GITHUB_REPOSITORY (for the gh CLI) and ANTHROPIC_API_KEY.
Collects the pull requests merged since the previous release, asks Claude to
summarise them, and writes the result into the release body below a marker.
Anything above the marker (a hand-written intro) is kept. If the model call
fails, GitHub's own generated notes are used instead, so a release never ends
up with empty notes. Standard library only.
"""
import json
import os
import re
import subprocess
import sys
import urllib.request

MODEL = os.environ.get("RELEASE_NOTES_MODEL", "claude-sonnet-5-5")
START = "<!-- release-notes:start -->"
END = "<!-- release-notes:end -->"
MAX_PRS = 150
BODY_CHARS = 600

PROMPT = """You write release notes for RC Soar Score, an application for \
running radio controlled sailplane contests. Readers are contest directors and \
testers, not developers.

Below is the list of changes merged since the previous release, with each pull \
request's title, labels and description. Write the notes in Markdown with these \
sections, leaving out any that would be empty:

## What's new
Two to four sentences on the main themes of this release.

## New features
One bullet per theme or feature, in plain language, describing what the user \
can now do. Group related pull requests into one bullet and link each as \
(#123).

## Fixes and improvements
Same style.

## Before you update
Anything a tester must do or know: data that is reset, things to re-publish, \
sign-in or QR code effects. Only include what the changes actually say; write \
nothing here if unsure.

Rules: no filler, no marketing language, no invented features, never mention \
internal tooling or CI unless it changes what users get. Do not add a heading \
above "What's new". Output only the Markdown.
"""


def gh(*args):
    return subprocess.run(
        ["gh", *args], check=True, capture_output=True, text=True
    ).stdout


def previous_tag(tag):
    """The release tag before this one, by creation date (pre-releases count).

    Reads every page of releases, so an old tag finds its real predecessor.
    Stops with an error if the tag is not a published release, because any
    other answer would compare against the wrong release.
    """
    pages = json.loads(
        gh("api", "--paginate", "--slurp",
           "repos/{owner}/{repo}/releases?per_page=100")
    )
    tags = [r["tag_name"] for page in pages for r in page if not r.get("draft")]
    if tag not in tags:
        sys.exit(f"::error::{tag} is not a published release of this repository")
    after = tags[tags.index(tag) + 1 :]
    return after[0] if after else None


def github_notes(tag, prev):
    args = ["api", "repos/{owner}/{repo}/releases/generate-notes",
            "-f", f"tag_name={tag}"]
    if prev:
        args += ["-f", f"previous_tag_name={prev}"]
    return json.loads(gh(*args))["body"]


def pull_details(generated):
    numbers = []
    for n in re.findall(r"/pull/(\d+)", generated):
        if n not in numbers:
            numbers.append(n)
    lines = []
    for n in numbers[:MAX_PRS]:
        pr = json.loads(gh("api", f"repos/{{owner}}/{{repo}}/pulls/{n}"))
        body = re.sub(r"<!--.*?-->", "", pr.get("body") or "", flags=re.S)
        body = re.sub(r"\s+", " ", body).strip()[:BODY_CHARS]
        labels = ", ".join(l["name"] for l in pr.get("labels", []))
        lines.append(f"- #{n} {pr['title']} [{labels}] {body}")
    if len(numbers) > MAX_PRS:
        lines.append(f"(and {len(numbers) - MAX_PRS} more pull requests)")
    return "\n".join(lines)


def ask_claude(tag, prev, details):
    payload = {
        "model": MODEL,
        "max_tokens": 4000,
        "messages": [{
            "role": "user",
            "content": f"{PROMPT}\nRelease: {tag} (previous: {prev})\n\n"
                       f"Changes:\n{details}",
        }],
    }
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=json.dumps(payload).encode(),
        headers={
            "x-api-key": os.environ["ANTHROPIC_API_KEY"],
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = json.load(resp)
    return "".join(b["text"] for b in data["content"] if b["type"] == "text").strip()


def merge_body(existing, generated):
    block = f"{START}\n{generated}\n{END}"
    existing = existing or ""
    if START in existing:
        head = existing.split(START)[0].rstrip()
        tail = existing.split(END, 1)[1].lstrip() if END in existing else ""
        return "\n\n".join(p for p in (head, block, tail) if p)
    return "\n\n".join(p for p in (existing.strip(), block) if p)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    if len(args) != 1:
        sys.exit(__doc__)
    tag = args[0]
    prev = previous_tag(tag)
    generated = github_notes(tag, prev)
    try:
        notes = ask_claude(tag, prev, pull_details(generated))
        if not notes:
            raise ValueError("empty answer")
    except Exception as exc:  # fall back to GitHub's own notes
        print(f"::warning::AI notes failed ({exc}); using GitHub's notes")
        notes = generated
    release = json.loads(gh("api", f"repos/{{owner}}/{{repo}}/releases/tags/{tag}"))
    body = merge_body(release.get("body"), notes)
    if dry:
        print(body)
        return
    subprocess.run(
        ["gh", "api", "-X", "PATCH",
         f"repos/{{owner}}/{{repo}}/releases/{release['id']}", "-F", "body=@-"],
        input=body, text=True, check=True, capture_output=True,
    )
    print(f"Release notes written for {tag} (previous: {prev}).")


if __name__ == "__main__":
    main()
