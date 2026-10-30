// Temporary live harness for autobyteus-integrations-1 API/E2E (API-10…API-18).
// Drives an isolated AutoByteus instance over its public GraphQL and WebSocket API.
// The GitHub test token is read from the owner-private file only by `connect`, sent once in that request,
// and never printed or written. The run pass (rp_…) is masked in everything this script writes.
// Usage: node harness.mjs <command> [args]   (state in /tmp/gh-int-live/state.json)
import fs from "node:fs";
import { randomUUID } from "node:crypto";

const STATE = "/tmp/gh-int-live/state.json";
const state = fs.existsSync(STATE) ? JSON.parse(fs.readFileSync(STATE, "utf8")) : {};
const save = () => fs.writeFileSync(STATE, JSON.stringify(state, null, 2));
const mask = (text) => String(text).replace(/rp_[A-Za-z0-9_-]+/g, "rp_<pass>");
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const gql = async (query, variables = {}) => {
  const res = await fetch(`${state.backendUrl}/graphql`, {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ query, variables }),
  });
  const body = await res.json();
  if (!body.data || body.errors?.length) throw new Error(mask(JSON.stringify(body.errors ?? body)));
  return body.data;
};
const readToken = () => {
  const line = fs.readFileSync(`${process.env.HOME}/.autobyteus-test/secrets/github-integration-test.env`, "utf8")
    .split("\n").find((l) => l.startsWith("GITHUB_INTEGRATION_TEST_TOKEN="));
  return line.slice(line.indexOf("=") + 1).trim().replace(/^["']|["']$/g, "");
};
const STATUS = "connected login connectedAt agentDefinitionIds";
const INSTRUCTIONS = [
  "You are a GitHub helper agent. Use the github-integration skill for anything on GitHub.",
  "When the user gives you an exact shell command, run exactly that command once with your shell tool, without changing it,",
  "then reply with its full output and exit code. Do not run other commands unless the user asks you to.",
].join(" ");

const commands = {
  async init(backendUrl, instanceId, dataRoot) { Object.assign(state, { backendUrl, instanceId, dataRoot }); save(); console.log("ok"); },
  async connect() {
    const status = (await gql(`mutation($token: String!) { connectGitHubIntegration(token: $token) { ${STATUS} } }`,
      { token: readToken() })).connectGitHubIntegration;
    console.log(JSON.stringify(status));
  },
  async status() { console.log(JSON.stringify((await gql(`query { githubIntegration { ${STATUS} } }`)).githubIntegration)); },
  async addSource(dir) {
    const sources = (await gql("mutation($p: String!) { addSkillSource(path: $p) { path } }", { p: dir })).addSkillSource;
    const skills = (await gql("query { skills { name rootPath isDisabled } }")).skills.filter((s) => s.name === "github-integration");
    console.log(JSON.stringify({ sources, skills }));
  },
  async agent(key) {
    const id = (await gql("mutation($input: CreateAgentDefinitionInput!) { createAgentDefinition(input: $input) { id skillNames skillScope } }",
      { input: { name: `gh-int-live-${key}-${randomUUID().slice(0, 6)}`, role: "assistant", category: "api-e2e",
        description: "autobyteus-integrations-1 live check agent.", instructions: INSTRUCTIONS,
        skillNames: ["github-integration"], skillScope: "CONFIGURED" } })).createAgentDefinition;
    state.agents = { ...(state.agents ?? {}), [key]: id.id }; save();
    console.log(JSON.stringify(id));
  },
  async tick(...keys) {
    const ids = keys.map((k) => state.agents[k]);
    console.log(JSON.stringify((await gql(`mutation($ids: [String!]!) { setGitHubIntegrationAgentAccess(agentDefinitionIds: $ids) { ${STATUS} } }`,
      { ids })).setGitHubIntegrationAgentAccess));
  },
  async models() {
    const snaps = (await gql("query($r: String) { providerModelCatalogSnapshots(runtimeKind: $r) { llmModels { modelIdentifier } } }",
      { r: "codex_app_server" })).providerModelCatalogSnapshots;
    console.log(snaps.flatMap((p) => p.llmModels.map((m) => m.modelIdentifier)).join("\n"));
  },
  async run(key, agentKey, model, workspace) {
    fs.mkdirSync(workspace, { recursive: true });
    const r = (await gql("mutation($input: CreateAgentRunInput!) { createAgentRun(input: $input) { success message runId } }",
      { input: { agentDefinitionId: state.agents[agentKey], workspaceRootPath: workspace, llmModelIdentifier: model,
        llmConfig: { reasoning_effort: "low" }, autoExecuteTools: true, runtimeKind: "codex_app_server" } })).createAgentRun;
    if (!r.success) throw new Error(r.message);
    state.runs = { ...(state.runs ?? {}), [key]: r.runId }; save();
    console.log(JSON.stringify(r));
  },
  async terminate(key) {
    console.log(JSON.stringify((await gql("mutation($id: String!) { terminateAgentRun(agentRunId: $id) { success message } }",
      { id: state.runs[key] })).terminateAgentRun));
  },
  // One chat turn. Writes the full (masked) wire transcript to <out>.jsonl and prints tool commands, outputs and the reply.
  async chat(key, messageFile, out, timeoutSec = "600") {
    const runId = state.runs[key];
    const url = new URL(state.backendUrl);
    const socket = new WebSocket(`ws://${url.host}/ws/agent/${runId}`);
    const messages = [];
    socket.addEventListener("message", (ev) => { try { const m = JSON.parse(String(ev.data)); if (m.type) messages.push(m); } catch {} });
    await new Promise((resolve, reject) => { socket.addEventListener("open", resolve); socket.addEventListener("error", reject); });
    const messageId = `e2e-${randomUUID()}`;
    socket.send(JSON.stringify({ type: "SEND_MESSAGE", payload: { message_id: messageId, dedupe_key: `agent_run_input:e2e:${messageId}`,
      context_file_paths: [], image_urls: [], agent_run_id: runId, content: fs.readFileSync(messageFile, "utf8") } }));
    const ends = new Set(["TURN_COMPLETED", "ERROR", "TOOL_APPROVAL_REQUESTED"]);
    const deadline = Date.now() + Number(timeoutSec) * 1000;
    while (Date.now() < deadline && !messages.some((m) => ends.has(m.type))) await wait(300);
    await wait(500);
    socket.close();
    fs.writeFileSync(`${out}.jsonl`, messages.map((m) => mask(JSON.stringify(m))).join("\n") + "\n");
    const types = {};
    for (const m of messages) types[m.type] = (types[m.type] ?? 0) + 1;
    console.log(mask(JSON.stringify({ end: messages.filter((m) => ends.has(m.type)).map((m) => m.type), types })));
  },
};

const [cmd, ...args] = process.argv.slice(2);
if (!commands[cmd]) { console.error(`unknown command ${cmd}`); process.exit(2); }
commands[cmd](...args).catch((e) => { console.error(mask(e.stack ?? e)); process.exit(1); });
