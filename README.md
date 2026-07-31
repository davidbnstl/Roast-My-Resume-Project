# Roast My Resume

Small AI-powered tool that grades a resume, gives feedback through "roasts" - After it generates a rewritten version — Built over the summer as an incoming college student looking to learn how AI- assisted software actually gets made.

Try it live: https://claude.ai/public/artifacts/84927624-7ecf-4124-bc17-7dbf4c0b91ff

## What I built
A resume critique tool that lets you paste in resume text or upload a PDF/DOCX/TXT file. It sends the content to Claude, which returns a letter grade, a one-line "roast" summary, specific roast points, and rewrite suggestions.

## What I learned
- **Structured AI output** — prompting the model to return consistent, parsable JSON instead of open-ended text, so the UI can format results reliably every time.
- **Client-side file parsing** — extracting text from PDF and DOCX files directly in the browser without a backend server.
- **Interface design for a "quick, fun" tool** — keeping the UI simple enough to use in under a minute, and iterating on details like typography so it reads clearly at a glance.
- **Shipping fast** — going from idea to a working, shareable demo in a short amount of time rather than over-scoping a first project.

## Built with
React, Claude API, PDF.js, Mammoth.js

---
Feedback welcome please reach out and point out where I can improve.
