# Source Selection

Use this reference when choosing local data signals, scopes, and parameters. Treat the live Source Catalog from `describe_sources` as the current contract; this file is a concise working guide for beta iteration.

## Source Catalog Snapshot

| Source | Typical use | Supported scopes observed |
| --- | --- | --- |
| crime | Crime and public-safety incidents | street, neighbor, zipcode, city, state, nation |
| sex_offenders | Sex offender registry signals | street, neighbor, zipcode, city, state |
| safe_parking | Vehicle safety incidents and car break-in risk | street, neighbor, zipcode, city, state |
| gas_prices | Nearby or area fuel prices | street, neighbor, zipcode, city, state |
| traffic | Traffic and road incidents | street, neighbor, zipcode, city, state |
| municipal | Local government, education, public-safety, and civic updates | street, neighbor, zipcode, city, state |
| events | Local events and happenings | street, neighbor, zipcode, city, state |
| jobs | Local job listings | street, neighbor, zipcode, city, state |
| real_estate | Real estate listings and area market signals | street, neighbor, zipcode, city, state |
| weather_alerts | Weather warnings and alerts | street, neighbor, zipcode, city, state |
| fire_incidents | Fire incidents and regional fire awareness | street, neighbor, zipcode, city, state |
| free_food | Food pantries and free food/community resources | street, neighbor, zipcode, city, state |
| freebies | Free local items | street, neighbor, zipcode, city, state |
| missing_persons | Missing persons records | street, neighbor, zipcode, city, state |
| nursing_homes | Nursing home quality, deficiencies, complaints, and fines | street, neighbor, zipcode, city, state |

## Intent Matrix

| Intent | Local data to request | Parameter hints | Web supplements |
| --- | --- | --- | --- |
| Neighborhood safety | crime, sex_offenders | Recent window for crime; radius for street/neighbor; compact details unless user asks for examples | Police department alerts, official crime dashboards, emergency notices |
| Moving or renting/buying | crime, sex_offenders, real_estate, municipal, events, weather_alerts | Use city or neighborhood; include real estate compact or aggregate; broaden detail only for top candidates | Schools, transit, commute, utilities, taxes, cost of living |
| School/kids safety | crime, sex_offenders, municipal | Query around school address if provided; include public-safety and education-related municipal updates | Official school/district pages, state education dashboards |
| Gas station at night | gas_prices, crime | Radius around address/current area; fuel type if provided; compare cheapest options with nearby safety signals | Official road closures or station pages if needed |
| Parking/car safety | safe_parking, crime | Use street/neighbor when possible; radius around destination; compact incident examples | City parking rules, official garage pages |
| Traffic/road incidents | traffic, municipal, weather_alerts | Keep time window current; include weather when conditions matter | DOT, 511, transit agency alerts |
| Local events | events, municipal, traffic, weather_alerts | Filter by date/time when user provides it; include travel/weather caveats | Venue/event official pages for ticketing or schedule confirmation |
| Jobs | jobs, municipal | Keep user constraints explicit: role, commute, remote/hybrid, pay | Employer pages, state labor resources |
| Real estate | real_estate, crime, sex_offenders, municipal, weather_alerts | Use exact address, ZIP, or neighborhood; compare 3+ records in a table | Schools, flood/fire risk, transit, HOA/property official records |
| Municipal updates | municipal | City or ZIP scope; narrow by topic if user names permits, schools, public safety, utilities, elections | Official city/county/state pages |
| Weather/fire alerts | weather_alerts, fire_incidents, municipal | Prefer current alerts; use exact location when possible | NWS, CAL FIRE or relevant state/local emergency agencies |
| Free food/resources | free_food, municipal | Query near address/ZIP; include hours/contact only if present | Official nonprofit/county resource pages |
| Free local items | freebies | Query near address/ZIP; preserve listing links when present | Listing site pages when available |
| Missing persons | missing_persons, municipal | Use city/state; avoid speculation; emphasize official reporting channels | Official law enforcement or missing-persons clearinghouse pages |
| Nursing home evaluation | nursing_homes, municipal | Compare CMS rating, deficiencies, complaints, and fines when available | CMS Care Compare, state licensing/ombudsman resources |
| "What's happening in X?" | crime, municipal, events, weather_alerts | Baseline local awareness; add traffic/fire based on region and season | Official current alerts and local government pages |

## Scope Guidance

- Prefer the most specific reliable location the user gives: address > neighborhood > ZIP > city > state.
- Resolve once with `resolve_local_geo` and reuse the geo object for multiple source requests.
- If a source downgrades a scope, explain the practical meaning in plain language only when it affects the answer.
- Use nation scope only for sources that explicitly support it. In the observed catalog, crime supports nation scope; most other sources are local/state only.

## Parameter Guidance

- Use compact detail for broad questions and expanded detail only when the user asks for examples, records, or a deeper evaluation.
- Use aggregate-only when comparing several places and record examples are not needed.
- For address-level safety, prefer radius-based searches where available.
- For high-impact decisions, combine multiple weak signals rather than over-weighting a single count.
- Treat missing data as "not available in the retrieved sources", not as proof that nothing exists.
