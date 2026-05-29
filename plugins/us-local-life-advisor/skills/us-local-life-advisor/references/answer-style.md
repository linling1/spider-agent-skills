# Answer Style

Use this reference when shaping user-facing answers.

## Structure

Start with the practical conclusion. Then give the strongest evidence, followed by topic details. Put caveats at the end, not at the top, unless there is an urgent safety issue.

Good shapes:

- Simple question: 2-5 sentences with a clear recommendation.
- Comparison: short recommendation, table, then notes.
- High-impact decision: recommendation, evidence by dimension, next steps, Sources and Limits.

Use Markdown tables when there are 3+ comparable records or options. Keep tables compact and avoid columns that repeat missing data.

## Source URL Handling

When records include URL-like fields such as `url`, `source_url`, `website`, or `link`, render names or titles as Markdown links. Do not invent links, infer homepages, or turn plain agency names into links without a URL field or external verification.

Separate externally sourced facts from local-data findings in plain language. For example, use headings such as **Local Data Signals** and **Official/Web Checks**. Do not use engineering labels such as MCP, tool, source_id, payload, adapter, or internal database in ordinary answers.

## Freshness and Limits

For complex answers, include a short **Sources and Limits** section that says:

- What dimensions were checked.
- Whether records are recent/current when the data exposes freshness.
- Any important coverage gaps, such as unavailable school, transit, healthcare, or cost-of-living data.
- That absence of retrieved incidents is not a safety guarantee.

## High-Risk Caveats

- Crime/safety: Never guarantee absolute safety. State that risk varies by time, exact block, and circumstances. For emergencies, tell the user to call 911.
- Missing persons: Avoid speculation about causes, suspects, or whereabouts. Point to official reporting channels.
- Nursing homes/healthcare: Compare quality signals, deficiencies, complaints, and fines, but recommend official inspections, in-person visits, and professional advice for care decisions.
- Legal, financial, housing, and elections: Provide official sources and practical next steps, but avoid definitive legal or financial advice.

## Language

Follow the user's language. Default to English. If answering in Chinese, keep place names, agency names, addresses, program names, and official resource names in English when that helps the user verify or act.
