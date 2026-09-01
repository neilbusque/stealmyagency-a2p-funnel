// Opt-in endpoint for the Steal My Agency A2P registration form.
//
// Same-origin, so there is no CORS dance and no need to treat status 0 as
// success the way a direct browser POST to a GHL webhook requires.
//
// Set GHL_WEBHOOK_URL in the Vercel project to forward submissions to
// GoHighLevel (or Zapier, or anything else that accepts a JSON POST). With no
// webhook configured the endpoint still accepts and logs the submission so the
// form works for TCR reviewers before the CRM is wired up.

const CONSENT_VERSION = '2026-09-01';
const FORWARD_TIMEOUT_MS = 8000;

function digits(s) {
  return String(s || '').replace(/\D/g, '');
}

function validEmail(s) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(String(s || '').trim());
}

function clientIp(req) {
  const fwd = req.headers['x-forwarded-for'];
  if (typeof fwd === 'string' && fwd.length) return fwd.split(',')[0].trim();
  return req.headers['x-real-ip'] || req.socket?.remoteAddress || null;
}

async function readBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  if (typeof req.body === 'string' && req.body.length) {
    try { return JSON.parse(req.body); } catch { return null; }
  }
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return null; }
}

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Allow', 'POST, OPTIONS');
    return res.status(204).end();
  }
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST, OPTIONS');
    return res.status(405).json({ ok: false, error: 'method_not_allowed' });
  }

  const body = await readBody(req);
  if (!body) return res.status(400).json({ ok: false, error: 'invalid_json' });

  const firstName = String(body.firstName || '').trim();
  const lastName = String(body.lastName || '').trim();
  const email = String(body.email || '').trim();
  const phoneDigits = digits(body.phone);

  const missing = [];
  if (!firstName) missing.push('firstName');
  if (!lastName) missing.push('lastName');
  if (!validEmail(email)) missing.push('email');
  if (phoneDigits.length < 10) missing.push('phone');
  // The Privacy/Terms box is the only required consent. SMS consent is
  // deliberately optional so that consent is never a condition of registering.
  if (body.termsConsent !== true) missing.push('termsConsent');

  if (missing.length) {
    return res.status(400).json({ ok: false, error: 'validation_failed', fields: missing });
  }

  // E.164 for US/Canada numbers; leave anything else as the caller sent it.
  let e164 = null;
  if (phoneDigits.length === 10) e164 = '+1' + phoneDigits;
  else if (phoneDigits.length === 11 && phoneDigits.startsWith('1')) e164 = '+' + phoneDigits;
  else e164 = '+' + phoneDigits;

  const smsConsent = body.smsConsent === true;

  const record = {
    firstName,
    lastName,
    email,
    phone: e164,
    phoneRaw: String(body.phone || '').trim(),
    smsConsent,
    termsConsent: true,
    source: String(body.source || 'stealmyagency-a2p-webinar'),
    pageUrl: String(body.pageUrl || ''),
    // Proof-of-consent fields. TCR and carriers can ask for these on audit.
    consent: {
      version: CONSENT_VERSION,
      text: String(body.consentText || '').slice(0, 2000),
      grantedAt: new Date().toISOString(),
      ip: clientIp(req),
      userAgent: req.headers['user-agent'] || null,
      method: 'web_form_checkbox'
    }
  };

  // Structured log so the submission is recoverable from Vercel logs even when
  // no webhook is configured yet.
  console.log('[optin]', JSON.stringify(record));

  const webhook = process.env.GHL_WEBHOOK_URL;
  let forwarded = false;
  let forwardError = null;

  if (webhook) {
    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), FORWARD_TIMEOUT_MS);
    try {
      const r = await fetch(webhook, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(record),
        signal: ac.signal
      });
      forwarded = r.ok;
      if (!r.ok) forwardError = 'webhook_status_' + r.status;
    } catch (err) {
      forwardError = err.name === 'AbortError' ? 'webhook_timeout' : 'webhook_unreachable';
    } finally {
      clearTimeout(t);
    }
    if (!forwarded) console.error('[optin] forward failed:', forwardError);
  }

  // The lead is captured in the logs regardless, so a webhook problem must not
  // show the visitor an error. A reviewer testing the form has to see it work.
  return res.status(200).json({ ok: true, forwarded, smsConsent });
}
