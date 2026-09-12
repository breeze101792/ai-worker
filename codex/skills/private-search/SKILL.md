---
name: private-search
description: Use the user's private SearXNG instance for web search. Use when you need to look something up on the internet, verify a fact, find documentation, or research a topic. This is the user's own search engine, meant for LLM use, and can be used at any time.
---

# Private Search

The user runs a private SearXNG instance. It is meant for LLM use and can be
used at any time instead of other web search tools.

## Endpoint

```
http://10.31.1.9:30053/search?q=<query>&format=json
```

## How to query

Use `webfetch` (or `curl` via bash) against the JSON endpoint. URL-encode the
query.

```
http://10.31.1.9:30053/search?q=GLM-5.3+model+capabilities&format=json
```

## Response shape

The JSON response has these top-level keys:

- `results` — array of search hits. Each hit has `title`, `content` (snippet),
  `url`, and `engine`.
- `answers` — direct answers, when available.
- `infoboxes` — structured knowledge boxes, when available.
- `suggestions` — related query suggestions.
- `corrections` — spelling corrections.
- `unresponsive_engines` — engines that failed; ignore.

## Usage notes

- Prefer `format=json` so the output is machine-readable.
- If a result's `url` looks authoritative (official docs, source repo), follow
  it with `webfetch` to read the full page rather than relying on the snippet.
- Some engines behind SearXNG may be rate-limited or CAPTCHA-gated; if a query
  returns few results, rephrase or retry.
