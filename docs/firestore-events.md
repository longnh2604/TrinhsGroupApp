# Firestore `events` — the Home carousel

The Events carousel on Home is driven entirely by the `events` collection in Firestore
project `trinhsgroup-befce`. Nothing about a banner lives in the app any more: artwork,
wording and running order are all fields on the document, read through a snapshot
listener, so an edit in the console shows up without a new build or even a relaunch.

## Fields

| Field | Type | Required | What it is |
|---|---|---|---|
| `id` | number | yes | Running order, ascending. Also the SwiftUI identity. A string like `"1"` is tolerated, but pick Number in the console. |
| `active` | boolean | no | `false` hides the event without deleting it. Missing counts as `true`. |
| `eyebrow` | string | yes | Small caps line above the title, e.g. `FAMILY SHARING`. |
| `title` | string | yes | The headline. |
| `subtitle` | string | yes | Price or summary line. |
| `detail` | string | yes | Text inside the yellow chip along the bottom. |
| `imgURL` | string | yes | Card artwork. Firebase Storage download URL. |
| `posterURL` | string | no | Full poster. Empty hides the "View poster" hint and makes the card untappable. |
| `type` | string | — | Carried over from 2022, unused by the app. |
| `link` | string | — | Carried over from 2022, unused by the app. |
| `content` | string | — | Carried over from 2022, unused by the app. |

`eyebrow`, `subtitle`, `detail`, `posterURL` and `active` are the five to add; the rest
already exist on the three 2022 documents.

## Room for text

The card is 196pt tall and the artwork takes a fixed 140pt off the right, which leaves
about 195pt of text width on a 393pt-wide phone. These are the limits that follow, and
they are estimates from the font sizes rather than measured maximums — check the longest
one on a device before publishing.

| Field | Lines | Aim for | What happens past it |
|---|---|---|---|
| `eyebrow` | 1 | ≤ 28 chars | Truncates. |
| `title` | 1 | ≤ 18 chars | Shrinks to 80%, then truncates. |
| `subtitle` | 2 | ≤ 50 chars | Truncates. |
| `detail` | 1 | ≤ 34 chars | Shrinks to 85%, then truncates. |

## Artwork

**`imgURL` — 420 × 588 px** (5:7 portrait, at @3x).

It is drawn into a 140 × 196pt slot and scaled to *fill*, so anything that does not match
5:7 gets cropped from the edges. Keep the subject centred.

**`posterURL` — 1242 × 2208 px**, or any portrait shape at least 1250 px wide.

The poster is scaled to *fit* inside a full-screen sheet, so its aspect ratio is free; the
width is what keeps it sharp on the largest iPhone.

Both are downloaded over the network on every cold start, so export as JPEG or WebP and
keep each under about 300 KB. For contrast, the two Android promo PNGs still bundled in
the app are 2.4 MB and 3.0 MB.

## Publishing

Any HTTPS URL works — Firebase Storage or, as now, `trinhsgroup.com.au/wp-content/uploads/`.
From Firebase Storage take the **download URL**, the long one ending in `?alt=media&token=…`;
a `gs://` path will not load. Plain HTTP will not load either: the app sets
`NSAllowsArbitraryLoads = false`.

## Generating the card artwork

The card sets its own type, so the thumbnail must carry **no words of its own** — a poster
scaled into the 140pt slot turns its text into unreadable specks. Generate at 1024 x 1536,
then resize to 420 x 588.

Shared style, append to each prompt:

> Warm natural side light, shallow depth of field, plain warm cream background (#F8EFE1),
> no pattern. Subject centred with generous empty margin top and bottom. Absolutely no text,
> no letters, no numbers, no logos, no watermarks, no branded packaging. Appetising, clean,
> editorial restaurant photography. Vertical portrait.

**Family Combo** — Two bowls of Vietnamese beef pho with fresh herbs and sliced onion, a
plate of golden fried chicken wings with skinny fries, and fresh prawn rice paper rolls with
a small dish of dipping sauce, grouped close together and shot from a high three-quarter
angle as one shared family feast.

**Kids Menu** — A child-sized meal on a pale wooden board: a small bowl of chicken pho, a
short banh mi cut in half, three crispy spring rolls and a little glass of orange juice,
shot from a high three-quarter angle. Bright, friendly, uncluttered.

**Lunch Special** — A crusty banh mi filled with roast pork, coriander, cucumber and pickled
carrot, beside a clear bowl holding four translucent prawn dumplings on lettuce, and a plain
unbranded chilled drink can, shot from a high three-quarter angle.
