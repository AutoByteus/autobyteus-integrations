// AC-006 probe: counts occurrences of the GitHub test token in files and directories. Prints counts and paths only,
// never the token. Also counts the run pass prefix (rp_) for information, and the token's first-8/last-4 fragments
// are NOT used (only the exact value is searched).
// Usage: node scan-token.mjs <path>...
import fs from "node:fs";
import path from "node:path";

const line = fs.readFileSync(`${process.env.HOME}/.autobyteus-test/secrets/github-integration-test.env`, "utf8")
  .split("\n").find((l) => l.startsWith("GITHUB_INTEGRATION_TEST_TOKEN="));
const token = Buffer.from(line.slice(line.indexOf("=") + 1).trim().replace(/^["']|["']$/g, ""));
if (token.length < 20) { console.log("token not loaded"); process.exit(2); }

let files = 0, bytes = 0, skipped = 0;
const hits = [];
const visit = (p) => {
  let st;
  try { st = fs.lstatSync(p); } catch { skipped++; return; }
  if (st.isSymbolicLink()) { skipped++; return; } // e.g. CODEX_HOME/auth.json -> the user's login; not a run output
  if (st.isDirectory()) { for (const e of fs.readdirSync(p)) visit(path.join(p, e)); return; }
  if (!st.isFile()) return;
  const buf = fs.readFileSync(p);
  files++; bytes += buf.length;
  let n = 0, i = -1;
  while ((i = buf.indexOf(token, i + 1)) !== -1) n++;
  // also base64 of the token (a Basic auth header would carry base64("x-access-token:<token>"))
  const b64 = Buffer.from(`x-access-token:${token}`).toString("base64");
  const nb = buf.includes(b64) ? 1 : 0;
  if (n || nb) hits.push({ file: p, raw: n, basic: nb });
};
for (const p of process.argv.slice(2)) visit(p);
console.log(JSON.stringify({ scannedPaths: process.argv.slice(2), files, bytes, skippedSymlinksOrMissing: skipped, filesWithToken: hits.length, hits }, null, 1));
