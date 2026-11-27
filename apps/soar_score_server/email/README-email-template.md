# RC Soar Score email templates

This folder holds the shared HTML email shell and its content blocks, plus the first message built from them: the pilot invitation (ticket #790). The server sends these exact files.

| File                       | What it is                                                                   |
| -------------------------- | ---------------------------------------------------------------------------- |
| `invitation-email.html`    | The shell plus the invitation content.                                       |
| `invitation-email.txt`     | The plain-text part of the same message. It must stay in step with the HTML. |
| `README-email-template.md` | This guide.                                                                  |

`lib/mail/invitation_mailer.dart` reads both files at startup (`lib/mail/email_template.dart`) and sends them as the HTML and plain-text parts of one message. The Dockerfile copies this folder to `/app/email`. A template that is missing, or that uses a placeholder the mailer does not fill, stops the server at startup.

Keep `{{...}}` out of HTML comments and other text that is not meant to be filled: every placeholder in the file is replaced, comments included, and the link must never appear outside the button and the fallback line.

## How the template is built

Every email has two layers.

1. **The shell.** It is the same in every RC Soar Score email. Copy it unchanged.
2. **Content blocks.** These sit in the shell's content slot, in reading order. Each block is a self-contained table that you can copy into another email.

The HTML comments mark each region exactly, so you can find them by searching for `SHELL:` and `BLOCK:`.

```text
SHELL: HEAD             meta tags, <title>, base styles, dark-mode rules
SHELL: PREHEADER        hidden inbox preview text, padded
SHELL: PAGE             paper background, 16px side gutters
  SHELL: COLUMN         600px maximum, fluid below; Outlook width table
    SHELL: HEADER BAND  night band, compact dark lockup, alt text in Paper
    SHELL: GAP          12px
    SHELL: CARD         white surface, 1px hairline, 12px corners
      CONTENT SLOT START
        BLOCK: HEADING
        BLOCK: GREETING
        BLOCK: PARAGRAPH  (entry sentence)
        BLOCK: PARAGRAPH  (lead-in)
        BLOCK: PRIMARY BUTTON
        BLOCK: FALLBACK URL
        BLOCK: NOTICE BOX
      CONTENT SLOT END
    SHELL: FOOTER       one row per line, plus FOOTER SLOT
```

### Shell rules

- Each element carries its light-theme styles inline, so the email still reads correctly when a client strips the `<style>` block. The `<style>` block adds only the phone padding, the full-width button on phones, hover and focus states, and dark mode.
- Dark mode uses colour classes, which every block shares. Put the right class on any new element and it follows the theme with no new CSS.

| Class                        | Light (inline)                  | Dark (from `<style>`)       |
| ---------------------------- | ------------------------------- | --------------------------- |
| `ss-page`                    | `#f3f2f2` background            | `#1c1b1a`                   |
| `ss-band`                    | `#1c1b1a` background and border | border becomes `#49443f`    |
| `ss-card`                    | `#ffffff`, `#d6d2cc` border     | `#2b2927`, `#49443f` border |
| `ss-text`                    | `#201e1d` text                  | `#f3f2f2`                   |
| `ss-muted`                   | `#605d5d` text                  | `#b8b3ad`                   |
| `ss-notice`                  | `#f3f2f2`, `#d6d2cc` border     | `#35322f`, `#49443f` border |
| `ss-hairline`                | `#d6d2cc` border                | `#49443f`                   |
| `ss-btn-cell`, `ss-btn-link` | `#b83300`, white text           | `#ff6a33`, `#0c0b0b` text   |

- `ss-plain` marks text that iOS or Samsung Mail might auto-link (dates, places, the URL), so detected links keep the surrounding style.
- The Outlook-only conditional comments are the width table around the column, the `OfficeDocumentSettings` block (it stops high-DPI Windows scaling the 600px width), and the VML button. There are no others.

### Content blocks

All blocks use the shared font stacks.

- Headings: `'League Spartan', 'Arial Black', 'Helvetica Neue', Arial, sans-serif`, weight 800.
- Body: `Archivo, 'Helvetica Neue', Arial, sans-serif`.

| Block                     | Size and colour                                                | Spacing below               |
| ------------------------- | -------------------------------------------------------------- | --------------------------- |
| Heading                   | `<h1>`, 24px, 800, line height 1.2, `ss-text`                  | 20px                        |
| Greeting                  | 16px, line height 1.55, `ss-text`                              | 16px                        |
| Paragraph                 | 16px, line height 1.55, `ss-text`                              | 16px (20px before a button) |
| Primary button            | 16px bold label, 52px tall, 8px corners                        | 24px                        |
| Fallback URL              | 14px `ss-muted` label, 13px `ss-text` URL that breaks anywhere | 24px                        |
| Notice box                | 16px `ss-text` on `ss-notice`, 8px corners                     | none (last block)           |
| Facts row (snippet below) | 13px label in capitals, 16px value                             | none                        |

Spacing is part of each block, so blocks stack in any order. Only one primary button may appear in a card, because the button is the card's single orange element.

#### Spare block: facts row

The invitation does not use this block, so it is kept here only. The `ss-hairline` dark rule it needs is already in the shell. For several rows, repeat the `<tr>`.

```html
<!-- BLOCK: FACTS ROW. Placeholders: {{factLabel}}, {{factValue}}. Repeat the <tr> for more rows. -->
<table
  role="presentation"
  class="ss-hairline"
  width="100%"
  cellpadding="0"
  cellspacing="0"
  border="0"
  style="border-top:1px solid #d6d2cc;"
>
  <tr>
    <td
      class="ss-muted"
      valign="top"
      width="35%"
      style="padding:10px 12px 10px 0;font-family:Archivo,'Helvetica Neue',Arial,sans-serif;font-size:13px;font-weight:800;line-height:18px;letter-spacing:0.18em;text-transform:uppercase;color:#605d5d;"
    >
      {{factLabel}}
    </td>
    <td
      class="ss-text"
      valign="top"
      style="padding:10px 0;font-family:Archivo,'Helvetica Neue',Arial,sans-serif;font-size:16px;line-height:1.55;color:#201e1d;word-wrap:break-word;overflow-wrap:break-word;"
    >
      {{factValue}}
    </td>
  </tr>
</table>
<!-- BLOCK: FACTS ROW END -->
```

## Placeholders

The mailer must HTML-escape every value before it fills it in. The template does not escape anything.

| Placeholder        | Where it appears                                         | Rules                                                                                                                                                                                                                                             |
| ------------------ | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `{{contestName}}`  | `<title>`, preheader, heading, entry sentence (bold)     | Free text from the director, often 60+ characters, may contain `&`, quotes and other punctuation. Wraps in every position.                                                                                                                        |
| `{{pilotName}}`    | Greeting                                                 | Any length and script. When it is empty, the greeting must read `Hello,` (see open items).                                                                                                                                                        |
| `{{locationLine}}` | Entry sentence                                           | Empty, or ` (Host, City, State, Country)` with its leading space and only the parts given, joined by commas.                                                                                                                                      |
| `{{dateLine}}`     | Entry sentence                                           | Empty, or `, Sat 10 Oct 2026` (one day), `, 10 to 11 Oct 2026` (span), `, 30 Oct to 1 Nov 2026` (across months). It is the contest's own calendar days with no times, so no time zone. The format can change in the mailer with no layout change. |
| `{{link}}`         | VML button `href`, HTML button `href`, fallback URL text | Full `https` URL, always present. It is secret, so it appears nowhere else: not in alt text, comments, tracking or hidden fields.                                                                                                                 |
| `{{logoUrl}}`      | Header band `<img src>`                                  | The hosted compact dark lockup, `https://rcsoarscore.com/brand/rc-soar-score-lockup-dark-compact-480.png` (480 × 118px, 13 KB, transparent). It is the same for every email.                                                                      |

The subject (`Your scoring link for {{contestName}}`, with `[TEST] ` in redirect mode), the From address and the absence of a Reply-To are message headers set by the mailer. They are not part of these files.

## Visible strings (for translation, #1028)

Every string is plain text in the HTML, with no text in images. Each string sits on one line, so it can be extracted directly.

| Key (suggested) | English                                                                                                                           | Where                            |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| `title`         | Your scoring link for {{contestName}}                                                                                             | `<title>` (matches the subject)  |
| `preheader`     | Your personal link to enter and review your scores for {{contestName}}.                                                           | Preheader                        |
| `heading`       | {{contestName}}                                                                                                                   | Heading                          |
| `greeting`      | Hello {{pilotName}},                                                                                                              | Greeting                         |
| `entry`         | You are entered in {{contestName}}{{locationLine}}{{dateLine}}.                                                                   | Paragraph (contest name in bold) |
| `leadIn`        | Use this personal link to enter and review your scores:                                                                           | Paragraph                        |
| `button`        | Open my scoring page                                                                                                              | Button (twice: VML and HTML)     |
| `fallbackLabel` | Or paste this address into your browser:                                                                                          | Fallback URL                     |
| `notice`        | This link is yours alone, so please do not share it. It stops working 24 hours after the contest is completed.                    | Notice box                       |
| `footerWhy`     | Your contest director sent this invitation. Replies to this address are not read; please contact the director with any questions. | Footer                           |
| `footerProduct` | RC Soar Score                                                                                                                     | Footer                           |
| `logoAlt`       | RC Soar Score                                                                                                                     | Logo `alt`                       |

## Adding a new email

1. Copy `invitation-email.html` to a new file, for example `support-confirmation-email.html`.
2. Change the `<title>` to the new subject line and the first preheader `<div>` to the new preview sentence (about 90 characters). Leave the padding `<div>` unchanged.
3. Delete everything between `CONTENT SLOT START` and `CONTENT SLOT END`. Then paste in the blocks you need, in reading order, from this file or from the invitation. Change only the text and placeholders inside each block.
4. Keep at most one primary button. If the email needs no action, leave the button out rather than adding a second style.
5. Replace the footer's "why you got this" line with the right reason for this email. Keep the product line and the footer slot.
6. Write the matching `.txt` part with the same wording, in the same order, with any link on its own line.
7. Before sending, check light and dark themes at 320px, 390px and 600px wide, with images blocked and with the `<style>` block removed. Keep the file under about 90 KB. The invitation is about 15 KB.

## Contrast (WCAG 2.x, computed from the hex values)

Light theme:

| Text                                  | Surface                | Ratio   | Needs |
| ------------------------------------- | ---------------------- | ------- | ----- |
| Ink `#201e1d` body and heading        | White `#ffffff` card   | 16.60:1 | 4.5:1 |
| Ink `#201e1d` notice text             | Paper `#f3f2f2` notice | 14.86:1 | 4.5:1 |
| Muted `#605d5d` fallback label        | White `#ffffff`        | 6.52:1  | 4.5:1 |
| Muted `#605d5d` footer                | Paper `#f3f2f2` page   | 5.83:1  | 4.5:1 |
| White button label                    | Deep Orange `#b83300`  | 5.98:1  | 4.5:1 |
| White button label (hover)            | `#9e2c00`              | 7.46:1  | 4.5:1 |
| Paper `#f3f2f2` alt text (images off) | Night `#1c1b1a` band   | 15.39:1 | 4.5:1 |
| Button edge (non-text)                | White card             | 5.98:1  | 3:1   |
| Focus ring Ink (non-text)             | White card             | 16.60:1 | 3:1   |

Dark theme:

| Text                             | Surface              | Ratio   | Needs |
| -------------------------------- | -------------------- | ------- | ----- |
| Paper `#f3f2f2` body and heading | `#2b2927` card       | 12.97:1 | 4.5:1 |
| Paper `#f3f2f2` notice text      | `#35322f` notice     | 11.40:1 | 4.5:1 |
| `#b8b3ad` fallback label         | `#2b2927` card       | 6.96:1  | 4.5:1 |
| `#b8b3ad` footer                 | Night `#1c1b1a` page | 8.26:1  | 4.5:1 |
| Dial `#0c0b0b` button label      | `#ff6a33`            | 6.89:1  | 4.5:1 |
| Paper `#f3f2f2` alt text         | Night `#1c1b1a` band | 15.39:1 | 4.5:1 |
| Button edge (non-text)           | `#2b2927` card       | 5.08:1  | 3:1   |
| Focus ring Paper (non-text)      | `#2b2927` card       | 12.97:1 | 3:1   |

The hairlines (`#d6d2cc` on white, `#49443f` on `#2b2927`) measure 1.51:1. They are decorative seams and carry no information, as the brand intends. Each surface is also set apart by a surface step.

## Sample renderings

These samples use made-up values. The link is not a real token.

Cases 1 and 2 were rendered in headless Chrome at 320px, 390px and 700px wide, and also with images blocked and with the `<style>` block removed. All three cases were rendered in light and dark themes at 390px. No case scrolled sideways. The button measured 52px tall in every case, 316px wide on a 390px phone and 320px wide on desktop.

Sample link: `https://score.rcsoarscore.com/invitations/EXAMPLE-TOKEN-not-a-real-link-0123456789abcdefghijklmnopqrstuvwxyz`

### 1. Short contest, full location, one-day date

- Values: pilot `Alex Example`, contest `Example Spring Thermal`, location ` (Example Soaring Club, Springfield, Ohio, USA)`, date `, Sat 10 Oct 2026`.
- Subject: Your scoring link for Example Spring Thermal
- Preheader: Your personal link to enter and review your scores for Example Spring Thermal.

```text
[RC Soar Score logo]

Example Spring Thermal

Hello Alex Example,

You are entered in **Example Spring Thermal** (Example Soaring Club, Springfield, Ohio, USA), Sat 10 Oct 2026.

Use this personal link to enter and review your scores:

[ Open my scoring page ]

Or paste this address into your browser:
https://score.rcsoarscore.com/invitations/EXAMPLE-TOKEN-not-a-real-link-0123456789abcdefghijklmnopqrstuvwxyz

| This link is yours alone, so please do not share it. It stops working 24 hours after the contest is completed. |

Your contest director sent this invitation. Replies to this address are not read; please contact the director with any questions.
RC Soar Score
```

### 2. Long contest name, multi-day dates, no location

- Values: pilot `Zoë Ñandú-Example`, contest `Example Northern Regional F3J & F5J Thermal Duration Championship 2026` (71 characters), location empty, date `, 10 to 11 Oct 2026`.
- Subject: Your scoring link for Example Northern Regional F3J & F5J Thermal Duration Championship 2026
- Preheader: Your personal link to enter and review your scores for Example Northern Regional F3J & F5J Thermal Duration Championship 2026.

On a 390px phone, the heading wraps to four lines and the entry sentence to four lines. The `&` arrives escaped as `&amp;` and displays as `&`.

```text
[RC Soar Score logo]

Example Northern Regional F3J & F5J Thermal Duration Championship 2026

Hello Zoë Ñandú-Example,

You are entered in **Example Northern Regional F3J & F5J Thermal Duration Championship 2026**, 10 to 11 Oct 2026.

Use this personal link to enter and review your scores:

[ Open my scoring page ]

Or paste this address into your browser:
https://score.rcsoarscore.com/invitations/EXAMPLE-TOKEN-not-a-real-link-0123456789abcdefghijklmnopqrstuvwxyz

| This link is yours alone, so please do not share it. It stops working 24 hours after the contest is completed. |

Your contest director sent this invitation. Replies to this address are not read; please contact the director with any questions.
RC Soar Score
```

### 3. No location and no dates

- Values: pilot `Sam Sample`, contest `Example Club Fun Fly`, location and date both empty.
- Subject: Your scoring link for Example Club Fun Fly
- Preheader: Your personal link to enter and review your scores for Example Club Fun Fly.

The entry sentence ends `…Example Club Fun Fly.` with no stray space, comma or bracket.

```text
[RC Soar Score logo]

Example Club Fun Fly

Hello Sam Sample,

You are entered in **Example Club Fun Fly**.

Use this personal link to enter and review your scores:

[ Open my scoring page ]

Or paste this address into your browser:
https://score.rcsoarscore.com/invitations/EXAMPLE-TOKEN-not-a-real-link-0123456789abcdefghijklmnopqrstuvwxyz

| This link is yours alone, so please do not share it. It stops working 24 hours after the contest is completed. |

Your contest director sent this invitation. Replies to this address are not read; please contact the director with any questions.
RC Soar Score
```

## Dark mode and blocked images

- **Clients that honour `prefers-color-scheme`** (Apple Mail on iOS and macOS, Outlook for Mac and iOS, some Android clients) switch to the dark column of the palette. The page becomes Night, the card `#2b2927`, the notice `#35322f`, and the button `#ff6a33` with Dial text.
- **Outlook.com and the new Outlook** receive the same colours through the `[data-ogsc]` and `[data-ogsb]` rules.
- **Header band.** It is Night in both themes. In dark mode the page is also Night, so the band gets a `#49443f` hairline to keep its shape.
- **Clients that invert colours themselves** (the Gmail apps, Samsung Mail, Outlook for Windows and Android) ignore these rules and recolour the message their own way. The band, button and notice are all solid colours behind text, and none of them depends on a transparent image. So they keep readable contrast under inversion, but the exact shades are the client's.
- **Images blocked.** The band stays Night with "RC Soar Score" in Paper, 22px heavy, centred. Some clients also show a broken-image marker or their own alt-text box. The message has no information in images, so nothing is lost.

## Expected degradation by client

| Client                          | Expected result                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Apple Mail (iOS, macOS)         | Full design, including dark mode, hover and focus.                                                                                                                                                                                                                                                                                               |
| Gmail web                       | Full light design with rounded corners. No dark mode: Gmail web does not apply `prefers-color-scheme`. The fallback URL is auto-linked in Gmail's link colour, and tapping it still opens the right page.                                                                                                                                        |
| Gmail iOS and Android           | Light design. In dark mode the app inverts colours itself (iOS fully, Android partly), so the card turns dark and the shades of the button and text are the app's. Gmail with a non-Google account strips `<style>`, which leaves the inline light design and the 320px button cap (the button is still full width on phones up to about 390px). |
| Outlook desktop 2016+ (Windows) | Square corners on the band, card, notice and button, as intended. The button is the VML version, a fixed 320 × 52px. There is no CSS dark mode, and Outlook's own dark mode may recolour backgrounds and text. Hover and focus states are not shown. With images blocked, Outlook shows its own alt-text box.                                    |
| New Outlook, Outlook.com        | Full design, with dark mode through the `data-ogsc` and `data-ogsb` overrides.                                                                                                                                                                                                                                                                   |
| Outlook iOS and Android         | Light design. Dark mode varies by app version: either our dark rules or the app's own inversion.                                                                                                                                                                                                                                                 |
| Yahoo Mail                      | Light design with media queries. The app's dark mode inverts colours itself.                                                                                                                                                                                                                                                                     |
| Samsung Mail                    | Light design. Dark mode is the app's own inversion. The `#MessageViewBody` rule keeps auto-detected links in the text style.                                                                                                                                                                                                                     |

## Decisions and compromises

These were confirmed with the product owner or are needed to meet the brief inside email limits.

- **A visible contest-name heading was added** above the greeting as an `<h1>`, at the product owner's request, for semantic headings. The contest name therefore appears twice: in the heading and in bold in the entry sentence. The brief's sentence wording is unchanged. The plain text starts with the contest name on its own line, to keep the same order.
- **Notice wording:** "This link is yours alone…" in both parts. The old plain text said "The link…".
- **Plain text has no "Or paste this address into your browser:" line.** The plain text has no button, so the label would refer to nothing. The link sits on its own line after the lead-in, as before.
- **Footer product line:** "RC Soar Score" in 13px muted text, as the brief allows.
- **Compact lockup instead of the full lockup.** The brief asked for the full dark lockup with its tagline. At 240px wide that tagline was only about 5px tall and could not be read, and the PNG was 126 KB. With the product owner's approval, the header uses the compact dark lockup (mark and wordmark, no tagline) instead. It was exported from `rc-soar-score-lockup-dark-compact.svg` as `rc-soar-score-lockup-dark-compact-480.png`, at 480 × 118px with a transparent background and the SVG's colours unchanged. That file is in both `packages/soar_score_ui/assets/logos/png/` and `apps/soar_score_web/public/brand/`.
- **Logo size.** The template shows the PNG at 240 × 59px, half its pixel size, so it is sharp on 2× screens. That is still below the brand's 360px homepage minimum, as the brief expected, but the wordmark reads clearly. On a 320px-wide phone the band leaves 230px, so the logo scales down to 230px with its ratio kept.
- **Logo clear space.** 28px of band padding plus the PNG's own 3px margin gives at least 30px on every side. That is more than half the mark's height (about 27px at this size).
- **Date example.** The brief's one-day example, `Sat 11 Oct 2026`, falls on a Sunday. The samples use `Sat 10 Oct 2026` and `10 to 11 Oct 2026` instead. The mailer's date formatter should take the weekday from the date itself.
- **Dark-mode band hairline.** In dark mode the page and the band are both Night. The band gets a `#49443f` hairline (Line Dark) so it still reads as a band.
- **Dark-mode button hover.** The brief gives no dark hover colour. Instead of inventing an orange, the hover keeps `#ff6a33` and shows a Paper border.
- **Dark-mode focus ring.** DESIGN.md uses Orange on Dark for focus on night surfaces. Next to a `#ff6a33` button that ring would merge with the button, so focus uses Paper `#f3f2f2` in dark mode. Light mode uses Ink, as DESIGN.md says.
- **Notice surface.** The light notice uses Paper `#f3f2f2` as its surface step, from the brief's palette, rather than DESIGN.md's `#e8e4dc`. Its corners are 8px, a step down from the 12px card, as the brief gives no value.
- **No shadows.** DESIGN.md gives dark-theme cards a drop shadow, but the brief rules out shadows in email. The card uses a hairline and a surface step only.
- **Fonts.** No web fonts are loaded. League Spartan and Archivo appear only if they are installed on the reader's device. Otherwise headings fall back to Arial Black (or Helvetica Neue) and body text to Helvetica Neue or Arial.
- **`{{link}}` appears three times:** in the VML button for Outlook desktop, in the HTML button and in the fallback text. Each copy is part of the button or the fallback, which are the only places the brief allows.
- **Outlook conditionals.** Besides the button and the column width table, the head carries an `OfficeDocumentSettings` block (`PixelsPerInch` 96). It keeps the 600px width stable on high-DPI Windows displays, so it counts as width control.

## How the mailer fills the templates

- **Escaping.** The HTML part escapes every value (`&`, `<`, `>`, `"`, `'`). The text part escapes nothing.
- **Empty values.** A placeholder with an empty value also drops the one space before it, so an empty `{{pilotName}}` gives `Hello,`.
- **Dates.** The mailer formats the contest's own calendar days with `intl`, in the locale resolved for the pilot: the pilot's account preference, else the locale of the contest's country, else `en-US` (`CountryLocale` in `soar_score_core`). For `en-US` a single day reads `Sat, Oct 10, 2026` and a span `Oct 10 to Oct 11, 2026`, which differs from the sample renderings above. The word "to" stays English until the emails are translated (#1028).
- **Location line.** ` (Host, City, State, Country)` with only the parts given, or empty.
