# CYBERKNIGHT CTFd Redesign Prompt
## Dark Cyber-Manga / Knight Operations

> Target: existing CTFd theme `ctfd-theme-neubrutalism`
>
> Goal: redesign the existing theme into a dark, premium, hacker-oriented CTF interface while preserving the visual identity of the CYBERKNIGHT club website.
>
> Reference identity:
> - https://cyb3rkn1ght-tdtu.github.io/
> - https://github.com/cyb3rkn1ght-tdtu/cyb3rkn1ght-tdtu.github.io
>
> A knight illustration will be supplied separately. Treat that illustration as a major brand asset, not a small decorative logo.

---

# 0. Core instruction

You are working inside an existing CTFd project.

The current theme is:

```text
ctfd-theme-neubrutalism
```

Do NOT create a completely unrelated theme.

Audit the existing theme, understand its templates, assets, build flow, JavaScript hooks, Bootstrap dependencies, CTFd challenge rendering, dynamic challenge integration, and then redesign the presentation layer.

The final interface must feel like:

```text
CYBERKNIGHT
DARK CYBER-MANGA
TACTICAL CTF OPERATIONS
```

The design must combine:

```text
Japanese manga editorial layout
+
letterpress / ink-print visual language
+
dark premium interface
+
CTF / cybersecurity operations console
+
neo-brutalist geometry
+
large knight illustration
```

It must NOT become:

```text
generic Matrix green
generic cyberpunk neon
purple-blue SaaS dashboard
glassmorphism template
gaming RGB UI
Bootstrap dark mode with a few red buttons
```

The final result should be recognizable as the same CYBERKNIGHT visual universe as the club website, but adapted for an interactive CTF platform.

---

# 1. First: audit the project before editing

Before changing code, inspect the entire current theme and related frontend integration.

Find and understand:

- theme entry point;
- `templates/`;
- `assets/`;
- `static/`;
- CSS / SCSS;
- JS / TypeScript if any;
- Jinja templates;
- challenge card rendering;
- challenge modal;
- navbar;
- homepage;
- login/register;
- scoreboard;
- users/teams;
- profile/account settings;
- alerts/toasts;
- pagination;
- form components;
- tables;
- Bootstrap classes;
- build scripts;
- package manager;
- Vite/Webpack/PostCSS/Sass flow if present;
- CTFd core template inheritance;
- CTFd JS selectors and data attributes;
- challenge submit logic;
- hints;
- files/downloads;
- solves;
- dynamic challenge controls;
- CTFd Whale integration if present.

Do not guess file names.

Do not rewrite the backend for visual changes.

Do not change routes, API contracts, challenge logic, CSRF logic, or container orchestration.

Before implementation, briefly report:

```text
Theme architecture
Important templates
CSS entry point
JS entry point
Build command
Risky CTFd hooks that must be preserved
```

Then continue implementing without waiting for confirmation unless there is a real blocker.

---

# 2. Visual analysis of the CYBERKNIGHT identity

The reference website uses a very distinctive visual language.

Preserve these characteristics.

## 2.1 Editorial manga composition

The site feels like:

```text
a manga cover
+
a printed magazine index
+
a technical publication
```

It does not feel like a normal web dashboard.

Important traits:

- oversized display typography;
- asymmetric composition;
- hard horizontal rules;
- large visual blocks;
- index/chapter numbering;
- Japanese micro-labels;
- flat print-like surfaces;
- strong black/red/cream contrast;
- large knight artwork partially cropped by the viewport;
- content feels deliberately typeset rather than placed into generic cards.

Bring this editorial attitude into CTFd.

---

# 3. New CTFd design direction

Use the internal design name:

# `CYBERKNIGHT // NIGHT ISSUE`

Alternative internal description:

```text
Negative Print Cyber-Manga
```

This is a DARK adaptation of the existing printed-manga identity.

The metaphor:

> The normal club website is a printed manga volume.
>
> The CTF platform is the same volume after entering the night operations room.

Therefore:

- the manga/editorial identity remains;
- the paper becomes warm-black ink;
- cream becomes text and structural linework;
- vermilion becomes the aggressive operational accent;
- terminal green appears only where something is genuinely technical/live;
- the knight becomes the "operator / guardian" visual.

---

# 4. Design principles

Every design decision must satisfy these principles.

## Principle A — Brand before hacker cliché

Users should first recognize CYBERKNIGHT.

They should not first think:

```text
another green hacker template
```

Avoid decorative hacking clichés such as:

- Matrix rain;
- anonymous masks;
- skull wallpaper;
- binary rain;
- random hexadecimal text everywhere;
- fake IP addresses;
- fake logs covering the screen;
- excessive glitch;
- neon cyan/purple everywhere.

Cybersecurity feeling should come from:

- terminology;
- hierarchy;
- command-line details;
- challenge metadata;
- terminal/code surfaces;
- structured mission presentation;
- technical typography.

---

## Principle B — Manga, but mature

Keep:

- panel geometry;
- hard rules;
- numbered sections;
- stamps/seals;
- asymmetry;
- strong display typography;
- print texture;
- mechanical button interaction.

Avoid:

- comic speech bubbles everywhere;
- kawaii UI;
- exaggerated comic effects;
- overly playful illustrations;
- anime UI tropes.

The visual target is:

```text
seinen manga technical publication
```

rather than:

```text
anime game interface
```

---

## Principle C — Dark and premium

Dark mode must be the DEFAULT for CTFd.

Do not use pure black everywhere.

Use layered warm charcoal surfaces.

Avoid giant blurred gradients.

Avoid glass blur as the main surface language.

The page must look good in a static screenshot.

---

## Principle D — Functional CTF first

Challenges must remain fast to scan.

Players need to quickly understand:

- category;
- challenge name;
- value;
- solve state;
- solve count;
- difficulty if available;
- challenge availability;
- dynamic instance state;
- primary action.

Art direction must not reduce usability.

---

# 5. Primary color system

The reference website already establishes the important brand colors.

Build the CTFd palette around them.

## 5.1 Core palette

Recommended starting tokens:

```css
:root {
  /* Background */
  --ck-bg: #100e09;
  --ck-bg-deep: #0b0a07;

  /* Main surfaces */
  --ck-surface: #16130d;
  --ck-surface-raised: #201c14;
  --ck-surface-alt: #262115;

  /* Ivory / paper ink inversion */
  --ck-text: #ece2cf;
  --ck-text-2: #b8ae96;
  --ck-text-muted: #857b64;

  /* Rules */
  --ck-rule: #3a3427;
  --ck-rule-strong: #ece2cf;
  --ck-hairline: #2a251b;

  /* Brand vermilion */
  --ck-red: #e85e44;
  --ck-red-strong: #f0705a;
  --ck-red-dark: #b93e2a;

  /* Quiet technical blue */
  --ck-indigo: #6e96c4;

  /* Terminal green */
  --ck-terminal: #5fd08a;

  /* Warning */
  --ck-warning: #d8b24e;

  /* Terminal */
  --ck-code-bg: #12140f;
  --ck-code-surface: #1b1e16;
  --ck-code-text: #e9e0cd;
}
```

You may tune values slightly for contrast and visual balance.

Do not replace the brand palette with cyan/purple.

---

# 6. Color usage rules

## Vermilion red

Use for:

- brand wordmark `KNIGHT`;
- active nav indicator;
- primary CTA;
- hard difficulty;
- important section numbers;
- first blood;
- critical action emphasis;
- challenge focus/hover edge;
- seals/stamps.

Do not fill half the page red.

---

## Ivory

Use for:

- primary text;
- structural rules;
- big headings;
- selected/high-priority content.

Never use pure white unless absolutely necessary.

---

## Terminal green

This color must remain intentionally "caged".

Use it only for:

- `SOLVED`;
- correct flag;
- instance online;
- successful connection;
- terminal prompt;
- code syntax;
- live system state.

Do NOT use terminal green for:

- navbar;
- every border;
- every card;
- page headings;
- decorative background.

The green becomes powerful because it is rare.

---

## Indigo

Use quietly for:

- links;
- information;
- secondary technical metadata;
- neutral interactive states;
- charts where necessary.

---

# 7. Background language

The current reference site has paper/ink texture.

Translate that to dark CTFd.

The global background should be:

```text
warm near-black
+
very subtle print grain
+
occasional manga hatch texture
+
hard structural linework
```

Possible CSS techniques:

- tiny radial noise;
- subtle repeating-linear-gradient hatch;
- restrained halftone texture;
- faint paper grain inverted for dark;
- local cross-hatching inside decorative panels.

Do NOT use:

- huge radial neon glows;
- animated particles;
- video background;
- Matrix rain;
- starfield;
- moving background grid.

Background texture should be almost invisible at first glance.

---

# 8. Typography

The reference design uses a strong combination of:

- expressive display type;
- serif editorial body;
- IBM Plex Mono for technical metadata.

Preserve that logic.

## Recommended hierarchy

### Display / brand

Prefer existing brand display font if already loaded.

Reference direction:

```text
Reggae One
```

Use for:

- CYBERKNIGHT wordmark;
- very large home title;
- occasional section/chapter number.

Do NOT use it for body text.

---

### Editorial serif

Reference direction:

```text
Shippori Mincho
Noto Serif
```

Use selectively for:

- challenge names;
- main page titles;
- special editorial labels;
- hero copy.

Do not overuse if it reduces CTF scanning speed.

---

### Technical mono

Reference direction:

```text
IBM Plex Mono
```

Use for:

- nav;
- metadata;
- points;
- solve counts;
- categories;
- labels;
- terminal;
- flag field;
- instance connection;
- small status labels;
- buttons where appropriate.

---

# 9. Text language

The CTF UI should feel technical and editorial.

Examples of presentation vocabulary:

```text
CTF OPERATIONS
CURRENT ISSUE
TARGET INDEX
MISSION
OPERATION
CHALLENGES
LIVE RANKING
INSTANCE
SOLVES
POINTS
STATUS
FIRST BLOOD
```

Japanese labels may be used as SMALL decorative secondary text, consistent with the club website.

Examples:

```text
作戦  operation
順位  ranking
挑戦  challenge
完    completed
難    hard
中    medium
易    easy
```

Important:

- Japanese is decorative-functional.
- Never hide essential information behind Japanese-only labels.
- English/CTFd content remains primary.
- Do not fill every component with Japanese text.

---

# 10. Neubrutalism inheritance

The current theme is Neubrutalism.

Do not erase all of that DNA.

Preserve:

- hard-edged geometry;
- minimal radius;
- offset shadows;
- clear borders;
- tactile buttons;
- physical press interaction;
- bold hierarchy.

Refine it to match print/letterpress.

## Borders

Prefer:

```css
border: 1px solid var(--ck-rule);
```

Important panels:

```css
border: 2px solid var(--ck-text);
```

Avoid large rounded corners.

Target radius:

```text
0px–4px
```

---

## Shadows

Use solid block-print shadow.

Example:

```css
box-shadow: 5px 5px 0 #090805;
```

or a restrained vermilion shadow for special elements.

Never use default soft Material shadows.

No giant blurred glow.

---

## Button press

Use physical print/stamp interaction.

```css
button:hover {
  transform: translate(-1px, -1px);
}

button:active {
  transform: translate(2px, 2px);
  box-shadow: none;
}
```

Keep motion fast:

```text
80–150ms
```

---

# 11. The knight image — major brand system

A knight illustration will be supplied separately.

The image must NOT be treated as:

```text
just a logo
```

It should become a recurring visual anchor.

Before implementation:

1. Search the repository for the supplied image.
2. Determine:
   - dimensions;
   - transparency;
   - aspect ratio;
   - dominant colors;
   - usable crop;
   - whether it has a background.
3. Do not invent a broken asset URL.
4. If the image is not present yet:
   - create the layout with a documented image slot;
   - keep a safe fallback;
   - clearly report the expected asset path.

Suggested semantic asset name if no project convention exists:

```text
cyberknight-knight.png
```

But use the real filename if supplied.

---

# 12. How to use the knight

## Home page

The knight should be BIG.

Desktop concept:

```text
┌───────────────────────────────────────────────────────────────┐
│ CYBERKNIGHT                                   CTF // ONLINE   │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│   CTF OPERATIONS                  [ LARGE KNIGHT ART ]         │
│                                                               │
│   BREAK THE SYSTEM.               knight cropped by viewport   │
│   READ THE MACHINE.               partially behind rules       │
│   CAPTURE THE FLAG.                                          │
│                                                               │
│   [ ENTER CHALLENGES ]                                        │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│ ISSUE 01     ACTIVE TEAMS     CHALLENGES     TIME              │
└───────────────────────────────────────────────────────────────┘
```

The knight can:

- extend beyond the hero container;
- be cropped aggressively;
- overlap structural rules;
- use red/ivory/gray palette;
- appear behind a limited amount of typography.

Do not place body text on top of the detailed part of the knight.

---

## Login / Register

Use a split editorial page:

```text
LEFT
authentication form

RIGHT
large cropped knight
```

On mobile, knight becomes a smaller top/banner crop.

---

## Challenges page

Do not show a giant knight behind the cards.

Instead use:

- a partial silhouette;
- a small cropped armor fragment;
- knight helmet watermark;
- edge illustration in page header;
- decorative illustration at empty space.

Challenge usability is primary.

---

## Scoreboard

Knight may appear as:

- faint background watermark;
- cropped sword/helmet line art;
- top-right editorial visual.

Opacity must remain low enough not to interfere with scores.

---

# 13. Image treatment

Do not add blue neon glow around the knight.

Preferred treatments:

- original flat illustration;
- grayscale + vermilion;
- hard threshold;
- print halftone;
- cross-hatch mask;
- red offset print;
- one-pixel registration offset;
- posterized shadows.

Optional very subtle "misregistered print" effect:

```text
ivory/gray layer
+
1–2px vermilion offset
```

Do not apply this to text.

Avoid continuous glitch animation.

---

# 14. Navbar / masthead

The reference site uses a magazine-like masthead.

Adapt the CTFd navbar to feel like the top line of a printed issue.

Desktop:

```text
電脳騎士部
CYBERKNIGHT

CHALLENGES   SCOREBOARD   TEAMS   USERS   ACCOUNT
```

Recommended behavior:

- sticky;
- warm dark background;
- strong bottom rule;
- compact;
- no giant height;
- no pills for every nav item;
- active state = vermilion rule or small block;
- mono uppercase nav.

Brand treatment:

```text
CYBER
KNIGHT
```

with `KNIGHT` in vermilion.

Do not hardcode site title if CTFd already provides configured site name.

---

# 15. Homepage

The homepage must be more than a generic CTFd jumbotron.

Use a manga cover composition.

## Hero structure

Left:

```text
small Japanese / mono kicker
CTF OPERATIONS

CYBER
KNIGHT

competition subtitle
event information
primary actions
```

Right:

```text
knight illustration
```

Add editorial issue metadata:

```text
VOL.01
CTF ISSUE
2026
```

Only use real event data if available.

Do not invent dates/countdowns.

---

# 16. Challenges page concept

Treat the challenge board as:

```text
TARGET INDEX
```

or:

```text
OPERATION INDEX
```

Do not convert every challenge to a futuristic glass card.

Use manga panels.

Category header example:

```text
01 / WEB EXPLOITATION
ウェブ
────────────────────────────────────────────
```

Challenge grid follows beneath.

---

# 17. Challenge cards

Cards should resemble printed manga chapter panels.

Desktop example:

```text
┌────────────────────────────────────┐
│ WEB // 04                  450 PTS │
│                                    │
│ JWT BREACH                         │
│                                    │
│ authentication logic              │
│                                    │
├────────────────────────────────────┤
│ 12 SOLVES              難 / HARD  │
└────────────────────────────────────┘
```

Important:

- challenge name must be dominant;
- points clear;
- category visible;
- solve state clear;
- no unnecessary decorative copy;
- do not invent description text if not present.

---

# 18. Card states

## Available

Neutral dark panel.

Hover:

- slight lift;
- vermilion edge;
- stronger block shadow.

---

## Solved

Use terminal green sparingly.

Example:

```text
完 // SOLVED
```

Possible treatments:

- green seal/stamp;
- green narrow top rule;
- check mark plus text;
- reduced visual prominence after solving.

Do not fill the whole card bright green.

---

## Incorrect / failure

Use vermilion/red for feedback.

Do not animate shaking aggressively.

---

## Locked / unavailable

Use muted ivory/charcoal.

If CTFd exposes a real locked state, show it.

Do not invent fake locks based on assumptions.

---

# 19. Hanko / seal system

The reference identity uses stamp-like motifs.

Bring this into CTFd as a signature component.

Possible seals:

```text
完     SOLVED
難     HARD
中     MEDIUM
易     EASY
初     FIRST BLOOD
```

Visual:

- square or circular stamp;
- vermilion/green depending on semantics;
- slight `rotate(-2deg)` or `rotate(2deg)`;
- hard border;
- no glossy effects.

Use sparingly.

One seal per card is enough.

---

# 20. Challenge modal = Operation Brief

This is one of the most important screens.

Make it feel like an editorial mission dossier.

Structure:

```text
┌──────────────────────────────────────────────────────┐
│ OPERATION 04 / WEB                         450 PTS   │
├──────────────────────────────────────────────────────┤
│                                                      │
│ JWT BREACH                                           │
│ ジェイダブリューティー                               │
│                                                      │
│ [ description / markdown ]                           │
│                                                      │
│ ───────────────────────────────────────────────────  │
│ FILES                                                │
│ [ DOWNLOAD ]                                         │
│                                                      │
│ INSTANCE                                             │
│ STATUS       ONLINE                                   │
│ HOST         ...                                      │
│ PORT         ...                                      │
│                                                      │
│ FLAG                                                 │
│ > CTF{________________________________________}       │
│                                                      │
│ [ SUBMIT FLAG ]                                      │
└──────────────────────────────────────────────────────┘
```

The exact fields must come from real CTFd data.

Do not fake:

- difficulty;
- host;
- port;
- instance state;
- solve count;
- category.

---

# 21. Markdown challenge content

Style all Markdown content intentionally:

- headings;
- paragraphs;
- links;
- inline code;
- fenced code;
- blockquotes;
- lists;
- tables;
- images;
- horizontal rules.

The challenge content should not suddenly look like default Bootstrap.

Code blocks should feel like the terminal portion of the manga.

---

# 22. Terminal/code design

This is where the "hacker" identity should become strongest.

Example:

```text
┌─ TERMINAL ───────────────────────────────────────────┐
│ $ nc challenge.cyberknight 31337                    │
│ connection established                               │
│ █                                                    │
└──────────────────────────────────────────────────────┘
```

Use:

```text
background      #12140f
text            #e9e0cd
terminal green  #5fd08a
vermilion       #e85e44
comment         #948a74
```

Do not make the whole website look like this terminal.

---

# 23. Flag submission

Make the flag area feel like a command input.

Example:

```text
FLAG SUBMISSION

> CTF{___________________________________________}

[ SUBMIT ]
```

The prompt symbol can be decorative.

Preserve the exact CTFd input/form behavior.

Correct response:

```text
完 // FLAG ACCEPTED
```

with restrained green.

Incorrect response:

```text
REJECTED
```

with vermilion.

Do not change CTFd response logic.

---

# 24. Dynamic challenge / CTFd Whale

If dynamic challenges are in use, preserve every control.

Possible visual mapping:

```text
INSTANCE

OFFLINE
STARTING
ONLINE
STOPPING
ERROR
```

Use actual states only.

Visual semantics:

- ONLINE = terminal green;
- STARTING = warning;
- OFFLINE = muted;
- ERROR = vermilion.

Buttons:

```text
[ START INSTANCE ]
[ STOP INSTANCE ]
[ RESET ]
```

Do not change their API calls, selectors, IDs, or event handlers without updating all dependencies.

Connection information should be displayed inside a technical panel.

---

# 25. Scoreboard

Treat scoreboard as:

```text
LIVE RANKING
順位表
```

It should resemble a printed ranking page rather than a finance dashboard.

Example:

```text
RANK   TEAM                         SCORE
────────────────────────────────────────────
01     NULLPOINTER                  4820
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

02     SEGFAULT                     4380
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

03     /DEV/NULL                    3970
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Top 3:

- stronger typography;
- vermilion rank number;
- optional tiny seal;
- no gold/silver/bronze gradients.

---

# 26. Score graph

If CTFd exposes a scoreboard graph:

- preserve its JavaScript/data logic;
- redesign its container;
- use brand colors;
- avoid rainbow series if possible;
- use ivory/red/indigo/green carefully;
- keep chart labels readable.

Do not delete the graph just because styling it is difficult.

---

# 27. Teams / Users

Think:

```text
ROSTER
```

or:

```text
OPERATORS
```

But preserve real labels/routes where necessary.

Profile panel example:

```text
TEAM // NULLPOINTER

RANK       01
SCORE      4820
SOLVES     21
```

Use editorial horizontal rules instead of excessive nested cards.

---

# 28. Login / Register

Use a split-screen composition inspired by the reference landing page.

Desktop:

```text
┌───────────────────────┬───────────────────────────────┐
│                       │                               │
│ CYBERKNIGHT           │                               │
│ AUTHENTICATION        │       LARGE KNIGHT ART        │
│                       │                               │
│ USERNAME              │                               │
│ [________________]    │                               │
│ PASSWORD              │                               │
│ [________________]    │                               │
│                       │                               │
│ [ AUTHENTICATE ]      │                               │
│                       │                               │
└───────────────────────┴───────────────────────────────┘
```

The split does not have to be exactly 50/50.

Use 40/60 or 45/55 if the illustration benefits from it.

---

# 29. Forms

Inputs:

- dark opaque surface;
- ivory text;
- thin rule;
- hard rectangular geometry;
- tiny or zero radius;
- clear focus ring.

Focus:

```text
vermilion border
+
small solid offset
```

Do not use glowing cyan input borders.

Chrome autofill must not turn the input white.

Style:

- input;
- textarea;
- select;
- checkbox;
- radio;
- file field;
- password field.

---

# 30. Buttons

## Primary

Vermilion fill.

```text
[ ENTER CHALLENGES ]
[ SUBMIT FLAG ]
```

Hard border and press interaction.

---

## Secondary

Dark/ivory outlined.

---

## Terminal success

Green only where semantically correct.

---

## Danger

Vermilion may also represent danger, so distinguish destructive buttons using layout/text/icon rather than a completely new neon palette.

---

# 31. Alerts / toast messages

Make notifications resemble small editorial notices.

Example:

```text
NOTICE // FLAG ACCEPTED
```

or:

```text
SYSTEM // INSTANCE READY
```

Keep them compact.

Never cover the entire screen with animated cyber effects.

---

# 32. Pagination

Use simple mono numbered pagination.

Example:

```text
← PREV    01  02  03  04    NEXT →
```

Current page:

- vermilion underline;
- inverted small block;
- no rounded pills.

---

# 33. Home section numbering

Borrow the reference site's chapter/index behavior.

Page sections may use:

```text
01
CHALLENGES

02
SCOREBOARD

03
RULES
```

Only on landing/overview pages.

Do not add giant numbers inside every functional form.

---

# 34. Manga line system

Use hard horizontal rules as a major visual motif.

Examples:

```text
────────────────────────────────────────
```

Web implementation:

- 1px hairline for internal grouping;
- 2px primary panel line;
- 3px hero/masthead rule.

Vermilion rule can indicate current section.

---

# 35. Layout

Use asymmetry deliberately.

Not every page should be a centered rectangle.

Examples:

- hero split layout;
- oversized section numbers in left gutter;
- category title aligned differently from challenge grid;
- knight art allowed to escape grid;
- scoreboard rank numbers in a narrow left rail.

However:

- forms should remain predictable;
- challenge cards should align cleanly;
- mobile should become simpler.

---

# 36. Desktop content width

Suggested:

```text
max-width: 1180–1280px
```

Challenge grid can exceed reading-width.

Challenge descriptions should have a comfortable reading measure.

Do not let long Markdown lines span 1500px.

---

# 37. Mobile

Mobile must NOT be a compressed desktop poster.

At <= 768px:

- reduce decorative Japanese;
- hide non-essential large texture;
- simplify offset shadows;
- knight becomes smaller crop;
- one-column forms;
- challenge cards 1 column or sensible 2-column only if width permits;
- navbar collapses correctly;
- challenge modal becomes full-height or near-full-height;
- scoreboard becomes horizontally safe;
- no horizontal overflow.

Test:

```text
360px
390px
768px
1024px
1280px
1440px
```

---

# 38. Motion

The reference identity favors mechanical motion.

Use:

- card lift;
- button press;
- stamp appearance;
- one-time solved feedback;
- subtle line reveal.

Timing:

```text
80ms–180ms
```

Do NOT use:

- infinite glitch;
- floating particles;
- pulsing all cards;
- bouncing knight;
- constant scanline motion;
- mouse parallax.

Support:

```css
@media (prefers-reduced-motion: reduce)
```

---

# 39. Hover language

Cards:

```text
translate(-2px, -2px)
block shadow increases
vermilion edge appears
```

Buttons:

```text
press down
```

Links:

```text
hard underline / vermilion rule
```

Do not scale components to 1.08.

---

# 40. Iconography

Do not import a huge icon library without need.

Prefer:

- typography;
- simple symbols;
- existing icons;
- a lightweight line icon set only if already present.

Avoid:

- skulls;
- anonymous masks;
- generic hacker hoodies;
- padlock icon on everything.

The knight is already the visual mascot.

---

# 41. Accessibility

Must include:

- strong text contrast;
- `:focus-visible`;
- keyboard navigability;
- semantic buttons;
- labels for form fields;
- usable error states;
- state indicated by icon/text as well as color;
- reduced motion;
- readable mobile type.

Decorative Japanese must never be the only label.

---

# 42. Do not copy the club landing literally

The CTFd platform is an interactive product.

Do NOT simply paste the website CSS into CTFd.

Instead extract its DESIGN DNA:

```text
cream/charcoal/vermilion
+
manga editorial composition
+
knight
+
hard rules
+
chapter/index system
+
stamp motif
+
mono technical labels
+
block-print interaction
```

Then adapt it to:

```text
challenges
scoreboard
teams
authentication
dynamic instances
flag submission
```

---

# 43. Important visual hierarchy

Every screen should follow:

1. Page identity.
2. Primary action/content.
3. Useful CTF metadata.
4. Operational state.
5. Decorative manga detail.

Never reverse this order.

---

# 44. Things that should feel "hacker"

The hacker mood should come from REAL CTF interaction.

Emphasize:

- terminal connection panel;
- flag prompt;
- challenge metadata;
- instance state;
- code syntax;
- monospace microcopy;
- technical category labels;
- operational vocabulary.

Do not try to manufacture hacker mood with random green text.

---

# 45. Things that should feel "knight"

The knight identity should come from:

- the supplied illustration;
- brand wordmark;
- armor/sword cropping;
- stamp/emblem system;
- commanding editorial hierarchy;
- deep vermilion.

Do not add medieval parchment, castle textures, fantasy fonts, or RPG inventory UI.

This is:

```text
CYBER knight
```

not:

```text
medieval fantasy game
```

---

# 46. Recommended design tokens

Create a maintainable token layer.

Example:

```css
:root {
  /* Background */
  --ck-bg: #100e09;
  --ck-bg-deep: #0b0a07;

  /* Surfaces */
  --ck-surface-1: #16130d;
  --ck-surface-2: #201c14;
  --ck-surface-3: #262115;

  /* Text */
  --ck-text-1: #ece2cf;
  --ck-text-2: #b8ae96;
  --ck-text-3: #857b64;

  /* Brand */
  --ck-accent: #e85e44;
  --ck-accent-hover: #f0705a;
  --ck-indigo: #6e96c4;
  --ck-term: #5fd08a;
  --ck-warning: #d8b24e;

  /* Rules */
  --ck-rule: #3a3427;
  --ck-rule-strong: #ece2cf;

  /* Geometry */
  --ck-radius: 2px;
  --ck-border: 1px;
  --ck-border-heavy: 2px;

  /* Shadow */
  --ck-shadow-sm: 3px 3px 0 #090805;
  --ck-shadow-md: 6px 6px 0 #090805;

  /* Motion */
  --ck-fast: 100ms ease;
  --ck-normal: 160ms ease;
}
```

Use variables consistently.

Do not scatter magic hex values across dozens of selectors.

---

# 47. Suggested component classes

If the code architecture permits, build reusable styles for:

```text
.ck-panel
.ck-rule
.ck-kicker
.ck-section-number
.ck-seal
.ck-tag
.ck-terminal
.ck-operation-card
.ck-operation-header
.ck-score-row
.ck-knight-art
.ck-editorial-title
.ck-masthead
.ck-status
```

Do not force these names if the theme already has a better naming architecture.

---

# 48. Bootstrap cleanup

Search for light-mode leakage.

Explicitly test:

- `.card`;
- `.modal-content`;
- `.dropdown-menu`;
- `.form-control`;
- `.form-select`;
- `.table`;
- `.alert`;
- `.pagination`;
- `.popover`;
- `.tooltip`;
- `.nav-tabs`;
- `.list-group`;
- browser autofill.

No random white Bootstrap panel should remain.

---

# 49. CTFd behavior preservation

This is mandatory.

After redesign, verify:

- home;
- login;
- logout;
- register;
- account;
- teams;
- users;
- challenges;
- category filtering;
- challenge modal;
- Markdown rendering;
- downloads;
- hints;
- flag input;
- correct flag;
- incorrect flag;
- solves;
- scoreboard;
- scoreboard graph;
- pagination;
- notifications;
- dynamic challenge controls;
- CTFd Whale integration if present.

Do not remove data attributes or IDs that JavaScript depends on.

Do not change backend behavior for presentation reasons.

---

# 50. Asset handling for the knight

When the supplied knight is present:

1. place it in the existing asset pipeline;
2. optimize it without destroying quality;
3. preserve transparency if needed;
4. use responsive sizing;
5. set meaningful alt text unless purely decorative;
6. preload only if it is a true LCP hero image;
7. avoid loading the full hero image on every page if unnecessary.

If a smaller derivative is useful for mobile, create one through the existing project workflow rather than an external service.

---

# 51. Knight image crop rules

Desktop hero:

```text
50–70% of hero height
```

or larger if composition supports it.

Allow:

- helmet off-grid;
- sword off-grid;
- shoulders cropped;
- art touching viewport boundary.

Do not:

- stretch;
- distort aspect ratio;
- put in a rounded avatar;
- wrap in a generic card;
- shrink to a tiny mascot.

---

# 52. Home hero target visual

Aim for this feeling:

```text
┌──────────────────────────────────────────────────────────────┐
│ 電脳騎士部                         CHALLENGES  SCORE  ACCOUNT │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ VOL.01 / CTF ISSUE                                           │
│                                                              │
│ CYBER                            ╱ KNIGHT ARMOR               │
│ KNIGHT                          ╱                             │
│                               ╱                              │
│ BREAK THE SYSTEM.            ╱   LARGE ILLUSTRATION           │
│ READ THE MACHINE.          ╱                                  │
│ CAPTURE THE FLAG.        ╱                                    │
│                                                              │
│ [ ENTER OPERATIONS ]                                          │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│ STATUS / LIVE          FORMAT / CTF          ISSUE / 01       │
└──────────────────────────────────────────────────────────────┘
```

This diagram is conceptual.

Use real CTFd content.

---

# 53. Challenge page target visual

```text
01
OPERATION INDEX
挑戦

WEB EXPLOITATION
──────────────────────────────────────────────────────────────

┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│ WEB // 01  100PTS │  │ WEB // 02  250PTS │  │ WEB // 03  500PTS │
│                   │  │                   │  │                   │
│ Warmup            │  │ JWT Breach        │  │ Final Gateway     │
│                   │  │                   │  │                   │
│ 完 SOLVED          │  │ 14 SOLVES         │  │ 難 HARD           │
└───────────────────┘  └───────────────────┘  └───────────────────┘
```

Cards remain readable at a glance.

---

# 54. Scoreboard target visual

```text
02
LIVE RANKING
順位

01  NULLPOINTER                                      4820
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

02  SEGFAULT                                         4310
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

03  /DEV/NULL                                        3970
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use linework rather than glossy progress cards.

---

# 55. Login target visual

```text
CYBERKNIGHT
AUTHENTICATION
認証

USERNAME
[________________________________]

PASSWORD
[________________________________]

[ AUTHENTICATE ]

                         [ cropped knight illustration ]
```

The page must look finished even with little content.

---

# 56. Footer

Minimal.

Example:

```text
CYBERKNIGHT // CTF OPERATIONS
Powered by CTFd
```

Respect existing attribution/license requirements.

Use a strong top rule.

---

# 57. Performance

Do not add:

- Three.js;
- particle engines;
- heavy animation frameworks;
- background videos;
- giant JS libraries.

Prefer:

- CSS;
- existing dependencies;
- existing CTFd JavaScript;
- optimized image assets.

---

# 58. Build

Use the project's real build process.

If source assets exist:

- edit source;
- rebuild;
- do not hand-edit generated bundles unless that is already project practice.

Do not commit:

- `node_modules`;
- debug files;
- temporary screenshots unless repository workflow expects them;
- build caches.

---

# 59. Browser verification

If browser automation is available, verify visually at minimum:

```text
/
 /challenges
 challenge modal
 /scoreboard
 /teams or /users
 /login
 /register
 /profile or /account
```

Test desktop and mobile.

Look specifically for:

- white flash;
- white modal;
- unreadable dropdown;
- missing focus;
- overflow;
- bad knight crop;
- text overlapping knight;
- inconsistent button geometry;
- old Neubrutalism colors left behind;
- Bootstrap defaults;
- low contrast;
- layout jumps.

---

# 60. Definition of Done

The redesign is complete only when all statements are true:

- CTFd is dark by default.
- The interface clearly belongs to CYBERKNIGHT.
- The supplied knight illustration is a meaningful brand element.
- Vermilion/ivory/charcoal dominate the visual identity.
- Terminal green is restrained and semantic.
- The theme still retains refined Neubrutalist geometry.
- Manga/editorial influence is clearly visible.
- Challenges remain easy to scan.
- Challenge modal is functional and polished.
- Scoreboard is distinctive.
- Login/register look intentional.
- No accidental light Bootstrap sections remain.
- Mobile layout is usable.
- CTFd behavior is preserved.
- Dynamic challenges still work if present.
- Build succeeds.
- No new console errors are introduced.
- No broken asset URLs exist.
- Reduced motion is supported.

---

# 61. Final report format

After implementation, return:

## Audit

What the original theme structure was.

## Files changed

List every modified/created file.

## Design foundation

Explain:

- colors;
- typography;
- layout;
- knight integration;
- challenge card system;
- modal;
- scoreboard.

## CTFd compatibility

List the functional paths/features checked.

## Knight asset

Report:

- source filename;
- output path;
- crop/optimization decisions;
- responsive behavior.

If the image has not been supplied, explicitly state that and report the placeholder contract instead of pretending it exists.

## Build/test commands

Show commands actually run and their result.

## Remaining issues

Only real remaining issues.

Do not claim something was tested if it was not tested.

---

# 62. Absolute prohibitions

Do NOT solve the task by:

- changing only background and text colors;
- adding a Matrix animation;
- making everything neon green;
- introducing cyan/purple glassmorphism;
- adding 20px rounded cards everywhere;
- putting the knight inside a small avatar;
- adding fake terminal logs;
- replacing CTFd functionality with mock UI;
- deleting difficult-to-style components;
- breaking dynamic challenge controls;
- hardcoding challenge/category/event data.

---

# 63. Final aesthetic target

When a player opens the platform, the desired reaction is:

```text
"This is CYBERKNIGHT's CTF."
```

not:

```text
"This is a generic CTFd theme."
```

The visual equation is:

```text
CYBERKNIGHT club identity
+
dark negative print
+
manga editorial composition
+
neo-brutalist physicality
+
real CTF operational UI
+
large knight artwork
=
CYBERKNIGHT // NIGHT ISSUE
```

Keep it dark.
Keep it sharp.
Keep it readable.
Keep it technical.
Keep it unmistakably CYBERKNIGHT.
