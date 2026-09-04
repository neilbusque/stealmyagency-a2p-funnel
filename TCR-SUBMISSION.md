# TCR A2P 10DLC — Campaign Registration (Low Volume Mixed)

Copy-paste field set for the TCR / Twilio / GHL A2P campaign form.
Every value here matches the live site at https://training.stealmyagency.com.

**Do not widen the message types below.** The live SMS consent checkbox authorizes
training reminders, replay links, and follow-up about that training. If the campaign
description claims more than the checkbox says, the mismatch is a rejection.

---

## Use case

**Use Case:** Low Volume Mixed
**Opt-in type:** Web form
**Opt-in URL:** https://training.stealmyagency.com

---

## Campaign Description

Primary version. Paste as-is.

> Steal My Agency sends low-volume SMS messages to individuals who have explicitly opted in through the optional SMS consent checkbox on our registration form at https://training.stealmyagency.com. That checkbox is never pre-checked and is not required to submit the form, so consent to receive text messages is never a condition of registering or of purchasing anything.
>
> This is a mixed program covering several message types for the same opted-in audience: (1) a one-time confirmation that the subscriber is opted in, (2) reminders before the free educational training they registered for, typically 24 hours and 1 hour prior, containing the join link, (3) a replay link once the session has ended, (4) occasional follow-up about that same training, and (5) customer-care responses when a subscriber texts us a question.
>
> We do not message anyone who has not opted in. No mobile numbers are purchased, rented, shared, or sourced from any third party. Message frequency varies and will not exceed 6 messages per month, sent at low throughput. Every outbound message identifies Steal My Agency and includes opt-out instructions. Replying STOP unsubscribes the recipient immediately and returns a single confirmation, after which no further messages are sent. Replying HELP returns program details and our contact address, nathan@stealmyagency.com. Message and data rates may apply.
>
> For each subscriber we store a consent record containing the timestamp, IP address, and the exact consent language displayed at the moment of opt-in. Full program terms are published at https://training.stealmyagency.com/terms-and-conditions.html and our privacy policy at https://training.stealmyagency.com/privacy-policy.html.

### Short version

For forms with a smaller description field.

> Steal My Agency sends low-volume SMS only to people who ticked the optional, un-pre-checked SMS consent box on our registration form at https://training.stealmyagency.com. The program is mixed: an opt-in confirmation, reminders containing the join link before the free training they registered for, a replay link afterward, occasional follow-up about that training, and customer-care replies when a subscriber texts a question. No purchased, rented, or shared lists. Frequency varies, up to 6 messages per month. Every message identifies Steal My Agency and includes opt-out instructions. Reply STOP to unsubscribe, HELP for help (nathan@stealmyagency.com). Message and data rates may apply. Consent is not a condition of purchase.

---

## Message Flow / Call-to-Action

This is the field reviewers scrutinize hardest. It describes exactly how consent is captured.

> End users opt in on the public web form at https://training.stealmyagency.com. The form collects first name, last name, email address, and mobile number to register for a free educational training. Below those fields are two separate checkboxes.
>
> The first is an optional SMS consent checkbox, unchecked by default, reading verbatim: "I agree to receive recurring automated SMS text messages from Steal My Agency at the mobile number provided above. Messages include training reminders, replay links, and follow-up about the training I registered for. Message frequency varies, up to 6 messages per month. Message and data rates may apply. Reply STOP to opt out. Reply HELP for help. See our Privacy Policy and Terms & Conditions. Consent is not a condition of purchase."
>
> The form submits successfully whether or not that box is ticked, so SMS consent is never a condition of registration. A second, separately required checkbox covers the Privacy Policy and Terms & Conditions. A standalone "SMS Program Details" disclosure block sits directly above the submit button restating the program description, message frequency, message and data rates, STOP and HELP instructions, and carrier liability.
>
> On submission we store a consent record containing the timestamp, IP address, user agent, and the exact consent text displayed. Mobile numbers are collected nowhere else, and no lists are purchased, rented, or shared. The opt-in page is publicly accessible with no login, paywall, or interstitial, and is not blocked in robots.txt.

---

## Sample Messages

Five samples spanning the mix. Trim to whatever the form allows, but keep #1, #2 and #5
so the set still reads as mixed rather than single-purpose.

**Sample 1 — opt-in confirmation**

> Steal My Agency: Thanks for registering, [First Name]. You're opted in to training reminders and replay links. Msg frequency varies, up to 6/mo. Msg & data rates may apply. Reply STOP to unsubscribe, HELP for help.

**Sample 2 — reminder, 24 hours before**

> Steal My Agency: Hi [First Name], your free training with Nathan is tomorrow at [Time] [Timezone]. Here's your link: [Link]. Reply STOP to unsubscribe.

**Sample 3 — reminder, 1 hour before**

> Steal My Agency: Hi [First Name], the training starts in 1 hour. Join here: [Link]. Reply STOP to unsubscribe.

**Sample 4 — replay link**

> Steal My Agency: Hi [First Name], the replay of the training is ready here: [Link]. It stays up for 72 hours. Reply STOP to unsubscribe.

**Sample 5 — follow-up and customer care**

> Steal My Agency: Hi [First Name], following up on the training you registered for. If you have a question about anything covered, reply to this text and someone on our team will answer. Reply STOP to unsubscribe.

---

## Keywords and auto-replies

**Opt-in keywords:** START, UNSTOP, YES

**Opt-in / confirmation message:**

> Thanks for registering with Steal My Agency! You're now opted in to training reminders and replay links. Msg frequency varies, up to 6/mo. Msg & data rates may apply. Reply STOP to unsubscribe or HELP for help.

**Opt-out keywords:** STOP, STOPALL, UNSUBSCRIBE, CANCEL, END, QUIT

**Opt-out message:**

> You have been unsubscribed from Steal My Agency messages. You will not receive any more texts from us. Reply START to resubscribe.

**Help keywords:** HELP, INFO

**Help message:**

> Steal My Agency: training reminders and replay links. Msg frequency varies, up to 6/mo. Msg & data rates may apply. Email nathan@stealmyagency.com. Reply STOP to unsubscribe.

---

## Message contents — what to tick

| Field | Answer | Why |
|---|---|---|
| Subscriber opt-in | **Yes** | Optional checkbox on the web form |
| Subscriber opt-out | **Yes** | STOP handled, confirmation returned |
| Subscriber help | **Yes** | HELP returns program details + email |
| Embedded links | **Yes** | Join links and replay links are sent |
| Embedded phone numbers | **No** | No phone number in any message |
| Age-gated content | **No** | |
| Direct lending or loan arrangement | **No** | |
| Affiliate marketing | **No** | |
| Number pooling | **No** | Low volume, single number |

**Embedded links must be Yes.** The samples contain links; answering No and then sending
them is a violation that gets the campaign revoked.

**Do NOT tick** "Content related to financial services or other loan arrangement (No
Promotional messaging allowed)". This is business education, not a financial product, and
ticking it restricts the use case for no reason.

---

## Before you submit

1. **Legal entity name.** Everything above says "Steal My Agency". If the A2P *brand*
   record is registered to an LLC with a different legal name, the site and the campaign
   must both match that name exactly or it is rejected for a name mismatch.
2. **Business phone number.** The site ships with email only. A visible phone number
   matching the brand record improves vetting.
3. **Governing-law state.** T&C section 12 still says "the state in which Steal My Agency
   maintains its principal place of business" because the state is published nowhere.

## After approval — the rule that keeps this campaign alive

Carriers treat business-opportunity and "make money" content as a restricted category.
This campaign is registered as logistics for a free training: reminders, replay links,
follow-up, and answering questions. The sample messages carry zero income claims on
purpose.

If you later want to text promotions for a paid program, **the consent checkbox wording on
the site has to be widened first**, and the campaign description updated to match. Sending
income-claim promos under the current registration is the fastest way to lose the campaign
after it has been approved.
