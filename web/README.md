# Bar Exam 2026 Command Center Web App

This folder contains a browser-based version of the Bar Exam dashboard.

## What it includes

- real-time countdown to September 6, 2026 at 8:00 AM Manila time
- Pomodoro timer with saved study sessions
- daily and weekday analytics graphs
- syllabus tracker with color-coded status legend
- embedded Bar Bulletin PDF preview tied to each subject

## Run locally

From the project root:

```bash
python3 -m http.server 4173
```

Then open:

```text
http://127.0.0.1:4173/web/
```

## Share it

Because this is a static web app, you can upload the `web/` folder to:

- Netlify
- Vercel
- GitHub Pages
- any simple web host

## GitHub Pages

This repo now includes a GitHub Actions workflow at `.github/workflows/deploy-web.yml`.

If you push the repo to GitHub and enable GitHub Pages for the repository, the `web/` folder can be published automatically and you'll get a shareable link like:

```text
https://your-username.github.io/your-repo-name/
```

## Notes

- The app stores data in the browser with `localStorage`, so each friend keeps their own progress on their own device.
- The PDF is loaded from `web/assets/2026-Bar-Bulletin.pdf`.
