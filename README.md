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

```sh
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

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
