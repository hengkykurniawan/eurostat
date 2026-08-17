# Eurostat Explorer

A single-file dashboard for the [Eurostat database](https://ec.europa.eu/eurostat/data/database).
Search every published dataset, filter it, chart it, and download the numbers.

### ➜ [Open the live app](https://hengkykurniawan.github.io/eurostat/)

## Open it locally

Double-click **`start.bat`**, or just open `eurostat-dashboard.html` in your browser.

There is nothing to install and no server to run: the whole app — including a searchable
index of all 7,571 datasets — lives inside that one HTML file. Data itself is fetched live
from Eurostat's API each time you open a dataset, so the numbers are always current.

If your browser ever refuses to fetch from a local file, run `.\serve.ps1` instead — it
serves the same file over `http://localhost:8931`.

## What you can do

| | |
|---|---|
| **Search** | Type anything — `inflation`, `gdp`, `une_rt_m`, `renewable` — across 7,571 dataset titles and codes. Filter by theme with the chips. Press `/` to jump to the search box. |
| **Filter** | Every dataset's real dimensions (unit, indicator, age, sex, sector, …) are read from Eurostat's structure service, so the dropdowns always match the dataset. Pick countries individually or with the EU27 / Euro area / Big 5 / Nordics presets. |
| **Chart** | *Trend over time* — multi-country line chart with a hover readout. *Compare countries* — ranked bar chart for any single period. *Data table* — the raw grid. Click a legend entry to hide a series. |
| **Download** | **CSV** (tidy: one row per observation, codes *and* labels, plus the quality flag), **JSON** (with the exact API query used), and **chart PNG**. |
| **Share** | "Copy shareable link" copies a URL that restores the exact dataset, filters and period. "Copy API URL" gives you the raw Eurostat query for use in Python, R or Excel. |
| **Keep** | ☆ Save marks datasets; recently opened ones appear at the top of the sidebar. |

## Reading the numbers

Values carry Eurostat's quality flags: `p` provisional, `e` estimated, `b` break in series,
`d` definition differs, `u` low reliability. A `:` in the table means the value is not available.
Rows tagged **agg** in the country list are aggregates (EU27, Euro area) rather than countries.

If a selection comes back empty, that combination simply isn't published — change the unit,
indicator or period. If Eurostat answers with a "request too large" error, narrow the period
or pick fewer countries.

## Rebuilding the dataset index

The bundled catalogue is a snapshot of Eurostat's table of contents (built 2026-08-17).
Dataset *values* are always live; only the searchable list of dataset names is a snapshot.
To refresh it:

```powershell
.\build.ps1 -Refresh
```

`build.ps1` downloads the table of contents, compacts it, gzips it, and embeds it into
`src/app.template.html` to produce `eurostat-dashboard.html`. Edit the template, never the
built file — a rebuild overwrites it.

## Files

```
eurostat-dashboard.html   the app — this is the only file you need
start.bat                 opens the app
serve.ps1                 optional local web server
build.ps1                 rebuilds the app from the template + catalogue
src/app.template.html     the source (HTML + CSS + JS, no dependencies)
src/toc.txt               cached Eurostat table of contents
```

## Source and attribution

Data © European Union, 1995–2026, via the Eurostat dissemination API
(`ec.europa.eu/eurostat/api/dissemination`). Reuse is allowed with acknowledgement of the
source. The app calls Eurostat directly from your browser — nothing is proxied, logged or
stored anywhere else; saved datasets and your theme choice live in your browser's local
storage only.
