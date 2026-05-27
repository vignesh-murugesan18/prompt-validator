# AI Prompt Coach

A Rails MVP inspired by the shared prompt-coaching reference app. Users can submit a prompt, choose a Groq model, optionally enrich the analysis with Perplexity web search, and receive a 0-10 score with strengths, weaknesses, and concrete improvements.

## Stack

- Ruby 3.2.2
- Rails 8
- PostgreSQL
- Hotwire, Stimulus, Importmap
- Tailwind CSS
- Active Job with Solid Queue available for production use

## Environment

Required for real prompt analysis:

```sh
export GROQ_API_KEY="your-groq-api-key"
```

Optional:

```sh
export GROQ_MODEL="llama-3.1-8b-instant"
export PERPLEXITY_API_KEY="your-perplexity-api-key"
export PERPLEXITY_MODEL="sonar-pro"
```

If `GROQ_API_KEY` is missing or Groq rate limits are exceeded, the app falls back to local prompt-quality rules. If `PERPLEXITY_API_KEY` is missing, the web-search option degrades gracefully and the Groq analysis still runs.

## Local Setup

Copy `.env.example` to `.env` and set `DATABASE_URL` (Neon pooled URL), `GROQ_API_KEY`, and any optional AI keys. Development uses the same `DATABASE_URL` as production.

```sh
bundle install
bin/rails db:migrate db:seed
bin/dev
```

### Migration error: `pg_type_typname_nsp_index` / `prompt_experiments already exists`

This means a migration failed halfway on Neon. In the Neon SQL console, drop the partial object (adjust name if needed):

```sql
DROP TABLE IF EXISTS prompt_experiments CASCADE;
```

Then run `bin/rails db:migrate` again. New migrations use `unless table_exists?` guards where possible to reduce repeats.

Then open `http://localhost:3000`.

## Tests

```sh
bin/rails test
```

## Free Deployment

The lowest-cost deployment path is Render Free for the Rails web service plus Neon Free for PostgreSQL. Render provides a free HTTPS `*.onrender.com` URL, so a custom domain is optional.

1. Create a Neon Free project and copy the pooled PostgreSQL connection string.
2. Push this app to GitHub.
3. In Render, create a Blueprint from `render.yaml`.
4. Set `DATABASE_URL` to the Neon connection string, `GROQ_API_KEY` to your Groq key, and add `RAILS_MASTER_KEY` only if your production credentials require it.
5. Keep `SOLID_QUEUE_IN_PUMA=true` so background prompt analysis jobs run inside the single free web service.

The Docker entrypoint runs `db:prepare db:seed` when the Rails server starts, so migrations and example prompts are prepared automatically during deploy.

## Main Features

- Reference-style prompt editor with minimum length feedback.
- Example prompts seeded from `db/seeds.rb`.
- Background prompt analysis job.
- Groq-backed structured scoring with a local fallback for rate limits.
- Optional Perplexity enrichment.
- Recent shared prompts plus top and lowest 24-hour leaderboards.
- Graceful failed-analysis state for missing API keys, timeouts, and invalid AI responses.
- **My Work** session history (per browser) with optional email linking for cross-device merge.
- **Notifications**: daily/weekly email digests, per-analysis completion emails, Slack webhooks.

## Sessions & history

- Each browser gets an anonymous `PromptSession` (cookie-backed visitor token).
- **My work** (`/prompt_sessions`) lists your analyses and A/B experiments.
- **Continue where you left off** on the home page shows your recent runs.
- Enter the same **email** in notification settings on another device to merge past sessions into one history.

## Email notifications (SMTP)

Digests and “analysis complete” emails require SMTP environment variables (see `.env.example`).

### Free SMTP providers (2026)

| Provider | Free tier | SMTP host | Notes |
|----------|-----------|-----------|--------|
| **Brevo** (Sendinblue) | ~300 emails/day | `smtp-relay.brevo.com` | Best free volume; verify sender/domain |
| **Mailjet** | 200 emails/day | `in-v3.mailjet.com` | Good for transactional mail |
| **SendGrid** | 100 emails/day forever | `smtp.sendgrid.net` | User = `apikey`, password = API key |
| **Resend** | 3,000/month (API); SMTP on paid | Use API or upgrade | Great DX; SMTP on higher plans |
| **Gmail** | ~500/day (personal) | `smtp.gmail.com` | Dev only; use [App Password](https://myaccount.google.com/apppasswords) |

**Recommendation:** start with **Brevo** or **Mailjet** for production on Render.

### Configure in this app

Add to `.env` (local) or Render environment variables:

```sh
MAILER_FROM="AI Prompt Coach <coach@yourdomain.com>"
SMTP_ADDRESS=smtp-relay.brevo.com
SMTP_PORT=587
SMTP_USERNAME=your-brevo-login-email
SMTP_PASSWORD=your-brevo-smtp-key
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

**Brevo steps**

1. Sign up at [brevo.com](https://www.brevo.com).
2. **SMTP & API** → create an SMTP key.
3. Verify a sender email or domain under **Senders**.
4. Use login email as `SMTP_USERNAME` and the SMTP key as `SMTP_PASSWORD`.

**SendGrid steps**

1. Create API key with “Mail Send”.
2. `SMTP_ADDRESS=smtp.sendgrid.net`, `SMTP_USERNAME=apikey`, `SMTP_PASSWORD=<API key>`.

**Local dev without SMTP**

If `SMTP_ADDRESS` is unset, development saves emails to `tmp/mail/` (file delivery).

**Test a digest manually**

```sh
bin/rails notifications:daily
```

### Slack webhooks

1. Create an [Incoming Webhook](https://api.slack.com/messaging/webhooks) in your Slack workspace.
2. Paste the URL in **Notifications** settings in the app.
3. Digests post to Slack when a webhook is set (no SMTP required for Slack-only).

Scheduled digests run via Solid Queue recurring tasks in `config/recurring.yml` (9:00 UTC daily / weekly). Requires `SOLID_QUEUE_IN_PUMA=true` or a dedicated worker on Render.
