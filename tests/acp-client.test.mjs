import assert from "node:assert/strict";
import { chmod, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";

const repositoryRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const clientPath = join(repositoryRoot, "tools", "cursor-acp-client.mjs");

test("answers cursor/ask_question and exits cleanly", async () => {
  const temporaryDirectory = await mkdtemp(join(tmpdir(), "acp-client-test-"));
  const fakeAgentPath = join(temporaryDirectory, "fake-agent.mjs");

  const fakeAgent = `#!/usr/bin/env node
import { createInterface } from "node:readline";

const protocol = createInterface({ input: process.stdin });
let promptRequestId;

function send(message) {
  process.stdout.write(JSON.stringify(message) + "\\n");
}

protocol.on("line", (line) => {
  const message = JSON.parse(line);

  if (message.method === "initialize") {
    send({ jsonrpc: "2.0", id: message.id, result: {} });
    return;
  }
  if (message.method === "authenticate") {
    send({ jsonrpc: "2.0", id: message.id, result: {} });
    return;
  }
  if (message.method === "session/new") {
    send({ jsonrpc: "2.0", id: message.id, result: { sessionId: "test-session" } });
    return;
  }
  if (message.method === "session/prompt") {
    promptRequestId = message.id;
    send({
      jsonrpc: "2.0",
      id: "question-1",
      method: "cursor/ask_question",
      params: {
        title: "테스트 질문",
        questions: [{
          id: "release",
          prompt: "SAP 릴리스",
          options: [
            { id: "750", label: "NW 7.50 / S/4HANA" },
            { id: "740", label: "NW 7.40" }
          ],
          allowMultiple: false
        }]
      }
    });
    return;
  }
  if (message.id === "question-1") {
    const selected = message.result?.outcome?.answers?.[0]?.selectedOptionIds;
    if (JSON.stringify(selected) !== JSON.stringify(["750"])) process.exit(2);
    send({ jsonrpc: "2.0", id: promptRequestId, result: { stopReason: "end_turn" } });
  }
});
`;

  await writeFile(fakeAgentPath, fakeAgent);
  await chmod(fakeAgentPath, 0o755);

  try {
    const child = spawn(process.execPath, [clientPath], {
      cwd: repositoryRoot,
      env: { ...process.env, CURSOR_AGENT_BIN: fakeAgentPath },
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
      if (stdout.includes("선택: ") && !stdout.includes("다음 요청")) {
        child.stdin.write("1\n");
      }
      if (stdout.includes("다음 요청 (/exit: 종료): ")) {
        child.stdin.end("/exit\n");
      }
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });

    const exitCode = await new Promise((resolveExit) => {
      child.on("exit", resolveExit);
    });

    assert.equal(exitCode, 0, stderr);
    assert.match(stdout, /테스트 질문/);
    assert.match(stdout, /NW 7\.50 \/ S\/4HANA/);
  } finally {
    await rm(temporaryDirectory, { recursive: true, force: true });
  }
});
