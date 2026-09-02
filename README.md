# Steal My Agency: A2P 10DLC Opt-In Funnel

A publicly crawlable webinar registration funnel built to satisfy TCR (The Campaign
Registry) and US carrier review for A2P 10DLC SMS campaign registration.

**Live:** https://stealmyagency-a2p.vercel.app
**Hosting:** Vercel project `stealmyagency-a2p`, team `neil-s-team-1825f849` (Pro)

## Pages

| File | Purpose |
|---|---|
| `index.html` | Webinar registration page with the opt-in form and the SMS disclosures |
| `thank-you.html` | Post-submission confirmation, restates the SMS terms |
| `privacy-policy.html` | Privacy policy with the full SMS data-handling sections |
| `terms-and-conditions.html` | T&C with the SMS program section and the earnings disclaimer |
| `api/optin.js` | Serverless endpoint that validates, records consent, and forwards to the CRM |
| `robots.txt` / `sitemap.xml` | Explicitly allow crawling so TCR reviewers can reach every page |

## Wiring the form to GoHighLevel

The form posts to `/api/optin` on the same origin, so there is no CORS problem and no
need for the "treat status 0 as success" hack that a direct browser POST to a GHL
webhook requires.

With no webhook set, the endpoint still validates and accepts the submission and writes
it to the Vercel logs, so the form works for a reviewer testing it today. To send leads
into GHL, add one environment variable and redeploy:

```bash
cd ~/Documents/Work/Claude/a2p-sites/stealmyagency
vercel env add GHL_WEBHOOK_URL production --scope neil-s-team-1825f849
# paste the GHL inbound webhook URL when prompted
vercel --prod --scope neil-s-team-1825f849
```

The JSON payload sent to the webhook:

```json
{
  "firstName": "Jane", "lastName": "Doe",
  "email": "jane@example.com",
  "phone": "+15555555555", "phoneRaw": "(555) 555-5555",
  "smsConsent": true, "termsConsent": true,
  "source": "stealmyagency-a2p-webinar",
  "pageUrl": "https://stealmyagency-a2p.vercel.app/",
  "consent": {
    "version": "2026-09-01",
    "text": "<the exact consent wording shown to the user>",
    "grantedAt": "2026-09-01T18:00:00.000Z",
    "ip": "203.0.113.9",
    "userAgent": "...",
    "method": "web_form_checkbox"
  }
}
```

`consent` is the proof-of-consent record. Keep it. Carriers can ask for it on audit.

## Before you submit to TCR: three things to fill in

These are the only fields I could not verify from public sources. Everything else on the
site is real and already correct.

**1. Business phone number (highest priority).** The site currently shows only
`nathan@stealmyagency.com` as the contact. A visible phone number that matches the one on
the A2P brand record materially improves vetting. I did not put a placeholder number live,
because a fake number on the page is worse than no number. To add the real one:

```bash
cd ~/Documents/Work/Claude/a2p-sites/stealmyagency
# swap in the real number, then commit and redeploy
grep -rn "nathan@stealmyagency.com" *.html   # shows every contact spot to update
```

**2. Legal entity name.** The site says "Steal My Agency" throughout, matching the
company's own published privacy policy. If the A2P brand is registered under an LLC or
Inc. name, replace it so the site matches the TCR brand record exactly:

```bash
sed -i '' 's/Steal My Agency/Steal My Agency LLC/g' *.html   # use the real registered name
```

Mismatched entity names between the site and the brand record is a common rejection cause.

**3. Governing-law state.** Section 12 of the T&C says "the state in which Steal My Agency
maintains its principal place of business" because the state is not published anywhere.
Name the actual state when you know it. TCR does not check this, but a lawyer would.

## TCR campaign registration copy

Paste these straight into the GHL / TCR A2P campaign form.

**Use case:** Low Volume Mixed

**Campaign description:**

> This Campaign sends low-volume messages from Steal My Agency to individuals who have explicitly opted in via the SMS consent checkbox on our registration form at https://stealmyagency-a2p.vercel.app. That checkbox is optional, is never pre-checked, and is not required to submit the form or to receive anything from us.
>
> After opting in, the end user receives text messages relating only to the free educational training they registered for. The experience is: a one-time confirmation that they are subscribed, one or two reminders before the session begins (typically 24 hours and 1 hour prior) containing the join link, a replay link once the session has ended, and occasional follow-up about that same training. Recipients may reply to a message with a question and will receive a response from our team.
>
> No messages are sent to anyone who has not opted in, and no numbers are purchased, rented, or shared. Message frequency varies and will not exceed 6 messages per month, sent at low throughput. Every message identifies Steal My Agency and includes opt-out instructions. Replying STOP unsubscribes the recipient immediately and returns a single confirmation, after which no further messages are sent. Replying HELP returns program details and our contact address, nathan@stealmyagency.com. Message and data rates may apply.
>
> For each subscriber we store a consent record containing the timestamp, IP address, and the exact consent language displayed at the moment of opt-in. Full program terms are published at https://stealmyagency-a2p.vercel.app/terms-and-conditions.html and https://stealmyagency-a2p.vercel.app/privacy-policy.html.

**Opt-in message:**

> Thanks for registering with Steal My Agency! You're now opted in to training reminders
> and replay links. Msg frequency varies, up to 6/mo. Msg & data rates may apply. Reply
> STOP to unsubscribe or HELP for help.

**Sample message 1 (reminder):**

> Hi [First Name], it's the Steal My Agency team. Your training with Nathan starts in 1
> hour. Here's your link: [Link]. Reply STOP to unsubscribe.

**Sample message 2 (replay):**

> Hi [First Name], thanks for registering with Steal My Agency. The replay of the training
> is ready here: [Link]. It stays up for 72 hours. Reply STOP to unsubscribe.

**HELP reply:**

> Steal My Agency: training reminders and replay links. Msg frequency varies, up to 6/mo.
> Msg & data rates may apply. Email nathan@stealmyagency.com. Reply STOP to unsubscribe.

**STOP reply:**

> You have been unsubscribed from Steal My Agency messages. You will not receive any more
> texts from us. Reply START to resubscribe.

**Opt-in type:** Web form
**Opt-in URL:** https://stealmyagency-a2p.vercel.app

**Do NOT tick** "Content related to financial services or other loan arrangement" or any
"direct lending" box. This is business education, not a financial product, and ticking
those restricts the use case unnecessarily.

### One risk worth knowing about

Carriers treat business-opportunity and "make money" content as a restricted category.
The site is deliberately built to stay clear of that line: the SMS program is described
strictly as event reminders and replay links for people who registered, the sample
messages carry no income claims at all, and a plain-English earnings disclaimer sits on
both the landing page and the T&C. Keep the actual sent messages logistical. Sending
income-claim promos on this campaign is the fastest way to get it revoked after approval.

## Compliance decisions baked in

- SMS consent checkbox is **optional and unchecked**. The form submits without it, so
  consent is never a condition of registering. A required checkbox here is the single most
  common TCR rejection.
- Terms/Privacy checkbox is **required and unchecked**, with a visible error if skipped.
- The SMS checkbox text carries all six CTIA elements plus links to both policies plus
  "Consent is not a condition of purchase."
- A standalone **SMS Program Details** block sits above the submit button, so a reviewer
  can read the disclosures without parsing checkbox micro-copy.
- **No `noindex` or `nofollow` anywhere.** `robots.txt` explicitly allows all crawlers.
- `smsConsent` in the payload reflects the real checkbox state. It is never hardcoded true.
- No authentication, no paywall, no interstitial. Every page loads for an anonymous visitor.

## Redeploying

Vercel's git integration is connected to `neilbusque/stealmyagency-a2p-funnel` with `main`
as the production branch, so a push is the deploy:

```bash
cd ~/Documents/Work/Claude/a2p-sites/stealmyagency
git add . && git commit -m "describe the change" && git push origin main
```

`vercel --prod --scope neil-s-team-1825f849` also works if you need to ship without a
commit. Either way, confirm the live alias actually moved afterwards:

```bash
curl -sI https://stealmyagency-a2p.vercel.app | head -1   # expect HTTP/2 200
```

### Do not re-enable deployment protection

`ssoProtection` and `passwordProtection` are both set to `null` on this project on purpose.
New Vercel projects turn Vercel Authentication on by default, which answers 302 to every
request. A TCR reviewer who hits that sees a login wall instead of the opt-in form, and the
campaign gets rejected. If the site ever starts 302ing, that setting came back:

```bash
TOK=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/Library/Application Support/com.vercel.cli/auth.json')))['token'])")
curl -s -X PATCH -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" \
  -d '{"ssoProtection":null,"passwordProtection":null}' \
  "https://api.vercel.com/v9/projects/stealmyagency-a2p?teamId=team_26oADIWJ5ZLiTNHr199AOPAs"
```

## Source of the build

Adapted from the archived `a2p-compliance-site` skill at
`~/.claude/skills/_archive-2026-07-07/a2p-compliance-site/`. That skill targets RIAs and
deploys to Netlify. This build keeps its compliance rules and drops the RIA framing
(investment-adviser disclaimers became an earnings disclaimer) and the Netlify deploy path.

Brand tokens were pulled from the live stealmyagency.com stylesheet: blue `#2d62ff`, pink
`#dd23bb`, black ground, Space Grotesk. The logo is the site's own wordmark, cropped and
downscaled from 583KB to 87KB.

## Photos (v2 polish, 2026-09-01)

All of Nathan's photos come from Steal My Agency's own published media:

- `nathan.webp` — hero cutout, subject-lifted (macOS Vision framework) from the
  thumbnail of a video on his own channel, youtube.com/@nathanbentleyofficial
  (video id `Did3k6Folak`), fringe cleaned with an alpha erode.
- `nathan-office.jpg` / `nathan-avatar.webp` — the photo of Nathan at his desk that
  SMA publishes on stealmyagency.com/thankyou (Webflow CDN asset
  `6672668daa17f1dbeaee6853_image 2026.webp`).
- `og-card.png` — 1200x630 share card generated from the brand tokens, the wordmark,
  and the portrait. Referenced by the og:image / twitter:image meta tags.

Two of his other photos were considered and rejected on purpose: the YouTube avatar
(fanning cash at a microphone) and the Rolls-Royce/Ferrari shot from the homepage
composite. Carriers treat business-opportunity content as a restricted category, and
wealth-flex imagery on the opt-in page works against approval. Keep this page's imagery
work-flavored: him at a desk, him at a microphone.

## Connecting the real domain

The funnel should live on Steal My Agency's own domain before the TCR submission.
Carriers weigh an opt-in URL on the brand's domain far more heavily than a `.vercel.app`
one, and a mismatch between the website on the brand record and the opt-in URL is a
rejection reason on its own.

**Target: `training.stealmyagency.com`**

The apex `stealmyagency.com` and `www` both point at Webflow and serve the main site, so
they stay exactly as they are. A subdomain is the correct move here, not a migration.

### The two DNS records

`training.stealmyagency.com` is already added to the Vercel project and is waiting on DNS.
Whoever manages DNS for `stealmyagency.com` needs to add these two records. DNS is on
Google Cloud DNS (`ns-cloud-a1..a4.googledomains.com`), so this is the Cloud DNS zone in
Google Cloud Console, under whichever project holds the `stealmyagency.com` zone.

| Type | Name / Host | Value | TTL |
|---|---|---|---|
| `TXT` | `_vercel` | `vc-domain-verify=training.stealmyagency.com,f5587fd1de1620f6c08b` | 300 |
| `CNAME` | `training` | `07800e8bf82db1bd.vercel-dns-016.com.` | 300 |

Notes for whoever adds them:

- In Google Cloud DNS the record names are entered fully qualified, so
  `_vercel.stealmyagency.com.` and `training.stealmyagency.com.` (trailing dot included).
- The CNAME value keeps its trailing dot.
- Neither record touches the apex or `www`. **The main Webflow site is unaffected.**
- The TXT proves domain ownership to Vercel. It can be deleted once the domain shows as
  verified, but leaving it costs nothing and avoids a re-verify later.
- If a `CAA` record exists on the apex, Vercel needs `letsencrypt.org` allowed or the SSL
  certificate will not issue. Check with `dig +short CAA stealmyagency.com` first. There is
  no CAA record today, so nothing to do unless one is added later.

### Then run one command

```bash
cd ~/Documents/Work/Claude/a2p-sites/stealmyagency
./scripts/connect-domain.sh --check   # status only, changes nothing
./scripts/connect-domain.sh           # finishes the job
```

The full run waits for Vercel to report the domain verified, then rewrites every absolute
URL in the site (canonical, `og:url`, `og:image`, `twitter:image`, `sitemap.xml`, the
`Sitemap:` line in `robots.txt`) from the `.vercel.app` host to `training.stealmyagency.com`,
checks each page returns 200 on the new host, commits, and deploys. Internal links are all
relative, so nothing else has to change.

Vercel issues the SSL certificate automatically once the CNAME resolves, usually within a
minute or two of propagation. The `.vercel.app` URL keeps working afterwards.

### Last step

Change the opt-in URL in the TCR campaign copy above from
`https://stealmyagency-a2p.vercel.app` to `https://training.stealmyagency.com`.
If the campaign has already been submitted, update the website field on the brand and
campaign records so the site the reviewer visits matches what is registered.

### Message to send the DNS owner

> Hi, I need two DNS records added to stealmyagency.com to point a subdomain at a new
> landing page. Neither one touches the main site, the apex and www stay on Webflow exactly
> as they are.
>
> 1. TXT record, host `_vercel`, value `vc-domain-verify=training.stealmyagency.com,f5587fd1de1620f6c08b`
> 2. CNAME record, host `training`, value `07800e8bf82db1bd.vercel-dns-016.com.`
>
> DNS is on Google Cloud DNS, so these go in the Cloud DNS zone for stealmyagency.com.
> TTL 300 is fine for both. Let me know once they are in and I will confirm it resolved.
