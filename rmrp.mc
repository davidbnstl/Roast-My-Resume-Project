import { useState } from "react";
import mammoth from "mammoth";

const SAMPLE = `Jordan Ellis
Objective: Seeking a marketing position where I can use my skills.

Experience:
- Worked at campus coffee shop, helped customers, handled register
- Social media intern (unpaid), posted content for a local nonprofit
- Group project leader for marketing class, got an A

Skills: Microsoft Word, team player, hard worker, good communication`;

let pdfjsLoading = null;
function loadPdfJs() {
  if (window.pdfjsLib) return Promise.resolve(window.pdfjsLib);
  if (pdfjsLoading) return pdfjsLoading;
  pdfjsLoading = new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js";
    script.onload = () => {
      window.pdfjsLib.GlobalWorkerOptions.workerSrc =
        "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";
      resolve(window.pdfjsLib);
    };
    script.onerror = reject;
    document.body.appendChild(script);
  });
  return pdfjsLoading;
}

async function extractPdfText(file) {
  const pdfjsLib = await loadPdfJs();
  const buf = await file.arrayBuffer();
  const doc = await pdfjsLib.getDocument({ data: buf }).promise;
  let text = "";
  for (let i = 1; i <= doc.numPages; i++) {
    const page = await doc.getPage(i);
    const content = await page.getTextContent();
    text += content.items.map((it) => it.str).join(" ") + "\n";
  }
  return text;
}

export default function ResumeRoaster() {
  const [resume, setResume] = useState("");
  const [stage, setStage] = useState("idle"); // idle | loading | done | error
  const [result, setResult] = useState(null);
  const [fileError, setFileError] = useState("");
  const [fileName, setFileName] = useState("");

  const grading = {
    "A": "#5C7A5C", "A-": "#5C7A5C",
    "B+": "#8A8478", "B": "#8A8478", "B-": "#8A8478",
    "C+": "#B3261E", "C": "#B3261E", "C-": "#B3261E",
    "D": "#B3261E", "F": "#B3261E",
  };

  async function handleFile(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    setFileError("");
    setFileName(file.name);
    try {
      const ext = file.name.split(".").pop().toLowerCase();
      let text = "";
      if (ext === "txt") {
        text = await file.text();
      } else if (ext === "docx") {
        const buf = await file.arrayBuffer();
        const out = await mammoth.extractRawText({ arrayBuffer: buf });
        text = out.value;
      } else if (ext === "pdf") {
        text = await extractPdfText(file);
      } else {
        setFileError("Use a .pdf, .docx, or .txt file.");
        return;
      }
      if (!text.trim()) {
        setFileError("Couldn't find text in that file — try pasting instead.");
        return;
      }
      setResume(text.trim());
    } catch (err) {
      setFileError("Couldn't read that file — try pasting the text instead.");
    }
  }

  async function roastIt() {
    const text = resume.trim() || SAMPLE;
    if (!resume.trim()) setResume(SAMPLE);
    setStage("loading");
    setResult(null);
    try {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 1000,
          messages: [
            {
              role: "user",
              content: `You are a blunt but ultimately constructive resume critic — think a sharp-tongued career coach with a red pen, not cruel. Given this resume text, respond with ONLY raw JSON (no markdown fences, no preamble) matching exactly this shape:
{
  "grade": "one of A, A-, B+, B, B-, C+, C, C-, D, F",
  "headline": "one witty one-line summary of the resume's vibe, max 12 words",
  "roastPoints": [ {"issue": "short label, max 5 words", "comment": "punchy, specific, funny-but-fair critique, 1-2 sentences"} ... 3 to 5 items ],
  "rewriteSuggestions": [ "concrete, specific fix phrased as an instruction, 1 sentence" ... 3 to 5 items ]
}
Resume:
"""
${text}
"""`,
            },
          ],
        }),
      });
      const data = await res.json();
      const raw = data.content.map((b) => b.text || "").join("");
      const clean = raw.replace(/```json|```/g, "").trim();
      const parsed = JSON.parse(clean);
      setResult(parsed);
      setStage("done");
    } catch (e) {
      setStage("error");
    }
  }

  return (
    <div style={{
      minHeight: "100vh",
      background: "#EDE4D3",
      fontFamily: "'Public Sans', -apple-system, sans-serif",
      color: "#1F2A44",
      padding: "32px 16px",
    }}>
      <link href="https://fonts.googleapis.com/css2?family=Public+Sans:wght@400;600;800&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet" />

      <div style={{ maxWidth: 640, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 28 }}>
          <div style={{
            fontFamily: "'Public Sans', sans-serif",
            fontSize: 32, fontWeight: 800, color: "#B3261E",
            letterSpacing: -0.5,
          }}>
            Roast My Resume
          </div>
          <div style={{ fontSize: 13, color: "#8A8478", marginTop: 6, letterSpacing: 0.3 }}>
            paste it in. get graded. get fixed.
          </div>
        </div>

        {/* Paper sheet */}
        <div style={{
          position: "relative",
          background: "#FAF7EF",
          border: "1px solid #DDD3BC",
          borderRadius: 3,
          boxShadow: "0 8px 24px rgba(31,42,68,0.10)",
          padding: "28px 24px",
        }}>
          {result && (
            <div style={{
              position: "absolute", top: -18, right: -14,
              width: 76, height: 76, borderRadius: "50%",
              border: `4px solid ${grading[result.grade] || "#B3261E"}`,
              color: grading[result.grade] || "#B3261E",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontFamily: "'Public Sans', sans-serif", fontWeight: 800, fontSize: 26,
              transform: "rotate(8deg)",
              background: "rgba(250,247,239,0.9)",
            }}>
              {result.grade}
            </div>
          )}

          {/* Upload row */}
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <label
              style={{
                padding: "7px 14px", background: "#FAF7EF",
                border: "1px solid #C9BFA8", borderRadius: 4,
                fontSize: 12.5, fontWeight: 600, color: "#1F2A44",
                cursor: "pointer", display: "inline-block",
              }}
            >
              Upload PDF / DOCX / TXT
              <input
                type="file"
                accept=".pdf,.docx,.txt"
                onChange={handleFile}
                style={{
                  position: "absolute", width: 1, height: 1,
                  padding: 0, margin: -1, overflow: "hidden",
                  clip: "rect(0,0,0,0)", border: 0,
                }}
              />
            </label>
            {fileName && !fileError && (
              <span style={{ fontSize: 12, color: "#8A8478" }}>{fileName} loaded</span>
            )}
            {fileError && (
              <span style={{ fontSize: 12, color: "#B3261E" }}>{fileError}</span>
            )}
          </div>

          <textarea
            value={resume}
            onChange={(e) => setResume(e.target.value)}
            placeholder="...or paste your resume text here. Hit Roast It to see a sample."
            style={{
              width: "100%", minHeight: 160, resize: "vertical",
              fontFamily: "'IBM Plex Mono', monospace", fontSize: 13.5,
              lineHeight: 1.6, color: "#1F2A44",
              background: "transparent", border: "none", outline: "none",
            }}
          />

          <button
            onClick={roastIt}
            disabled={stage === "loading"}
            style={{
              marginTop: 12, padding: "10px 22px",
              background: stage === "loading" ? "#C9BFA8" : "#B3261E",
              color: "#FAF7EF", border: "none", borderRadius: 4,
              fontFamily: "'Public Sans', sans-serif", fontWeight: 600, fontSize: 14,
              cursor: stage === "loading" ? "default" : "pointer",
              letterSpacing: 0.3,
            }}
          >
            {stage === "loading" ? "Grading..." : "Roast It"}
          </button>

          {stage === "error" && (
            <div style={{ marginTop: 14, color: "#B3261E", fontSize: 13 }}>
              Something went wrong grading that. Try again.
            </div>
          )}

          {result && (
            <div style={{ marginTop: 22, borderTop: "1px dashed #DDD3BC", paddingTop: 18 }}>
              <div style={{
                fontFamily: "'Public Sans', sans-serif", fontSize: 17, fontWeight: 800,
                color: "#B3261E", marginBottom: 12,
              }}>
                "{result.headline}"
              </div>

              <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: 1, color: "#8A8478", marginBottom: 8 }}>
                THE ROAST
              </div>
              {result.roastPoints.map((p, i) => (
                <div key={i} style={{ marginBottom: 10, paddingLeft: 12, borderLeft: "2px solid #B3261E" }}>
                  <div style={{ fontFamily: "'Public Sans', sans-serif", fontSize: 14, color: "#B3261E", fontWeight: 700 }}>
                    {p.issue}
                  </div>
                  <div style={{ fontSize: 13.5, color: "#1F2A44" }}>{p.comment}</div>
                </div>
              ))}

              <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: 1, color: "#8A8478", margin: "18px 0 8px" }}>
                THE REWRITE
              </div>
              {result.rewriteSuggestions.map((s, i) => (
                <div key={i} style={{
                  marginBottom: 8, paddingLeft: 12, borderLeft: "2px solid #5C7A5C",
                  fontSize: 13.5, color: "#1F2A44",
                }}>
                  {s}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
