#!/usr/bin/env node

import { spawn } from "node:child_process";
import { createInterface as createLineReader } from "node:readline";
import { createInterface as createPromptInterface } from "node:readline/promises";
import process from "node:process";

const agentBinary = process.env.CURSOR_AGENT_BIN || "agent";
const agent = spawn(agentBinary, ["acp"], {
  cwd: process.cwd(),
  env: process.env,
  stdio: ["pipe", "pipe", "inherit"],
});

const prompt = createPromptInterface({
  input: process.stdin,
  output: process.stdout,
});
const protocol = createLineReader({ input: agent.stdout });

let nextId = 1;
let uiQueue = Promise.resolve();
const pending = new Map();

function send(method, params) {
  const id = nextId++;
  agent.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", id, method, params })}\n`);

  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
  });
}

function respond(id, result) {
  agent.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", id, result })}\n`);
}

function enqueueUi(task) {
  uiQueue = uiQueue.then(task, task);
  return uiQueue;
}

async function askChoice(question) {
  const selected = new Set();

  while (selected.size === 0) {
    console.log(`\n${question.prompt}`);
    question.options.forEach((option, index) => {
      console.log(`  ${index + 1}. ${option.label}`);
    });

    const suffix = question.allowMultiple ? " (복수 선택: 1,2)" : "";
    const answer = (await prompt.question(`선택${suffix}: `)).trim();
    const indexes = answer
      .split(",")
      .map((value) => Number.parseInt(value.trim(), 10) - 1)
      .filter((index) => Number.isInteger(index) && question.options[index]);

    if (!question.allowMultiple && indexes.length > 1) {
      console.log("하나만 선택해 주세요.");
      continue;
    }

    indexes.forEach((index) => selected.add(question.options[index].id));
    if (selected.size === 0) {
      console.log("표시된 번호를 입력해 주세요.");
    }
  }

  return [...selected];
}

async function handleAskQuestion(message) {
  const request = message.params ?? {};
  console.log(`\n${request.title ? `=== ${request.title} ===` : "=== 질문 ==="}`);

  const answers = [];
  for (const question of request.questions ?? []) {
    answers.push({
      questionId: question.id,
      selectedOptionIds: await askChoice(question),
    });
  }

  respond(message.id, {
    outcome: {
      outcome: "answered",
      answers,
    },
  });
}

async function handlePermission(message) {
  const request = message.params ?? {};
  const toolName =
    request.toolCall?.title ||
    request.toolCall?.name ||
    request.title ||
    "도구 실행";

  console.log(`\n권한 요청: ${toolName}`);
  const answer = (
    await prompt.question("허용하시겠습니까? [y] 한 번 허용 / [a] 항상 허용 / [n] 거부: ")
  )
    .trim()
    .toLowerCase();

  const optionId =
    answer === "a"
      ? "allow-always"
      : answer === "y" || answer === ""
        ? "allow-once"
        : "reject-once";

  respond(message.id, {
    outcome: {
      outcome: "selected",
      optionId,
    },
  });
}

async function handleCreatePlan(message) {
  const request = message.params ?? {};
  console.log(`\n=== ${request.name || "계획 승인"} ===`);
  if (request.overview) console.log(request.overview);
  if (request.plan) console.log(`\n${request.plan}`);

  const answer = (await prompt.question("\n이 계획을 승인할까요? [Y/n]: "))
    .trim()
    .toLowerCase();

  respond(message.id, {
    outcome:
      answer === "n"
        ? { outcome: "rejected", reason: "사용자가 계획을 거부했습니다." }
        : { outcome: "accepted" },
  });
}

protocol.on("line", (line) => {
  let message;
  try {
    message = JSON.parse(line);
  } catch {
    console.error(`ACP 응답을 해석하지 못했습니다: ${line}`);
    return;
  }

  if (
    Object.hasOwn(message, "id") &&
    (Object.hasOwn(message, "result") || Object.hasOwn(message, "error"))
  ) {
    const waiter = pending.get(message.id);
    if (!waiter) return;
    pending.delete(message.id);
    if (message.error) waiter.reject(new Error(message.error.message || "ACP 요청 실패"));
    else waiter.resolve(message.result);
    return;
  }

  if (message.method === "session/update") {
    const update = message.params?.update;
    if (update?.sessionUpdate === "agent_message_chunk" && update.content?.text) {
      process.stdout.write(update.content.text);
    }
    return;
  }

  if (message.method === "cursor/ask_question") {
    enqueueUi(() => handleAskQuestion(message)).catch(fail);
    return;
  }

  if (message.method === "cursor/create_plan") {
    enqueueUi(() => handleCreatePlan(message)).catch(fail);
    return;
  }

  if (message.method === "session/request_permission") {
    enqueueUi(() => handlePermission(message)).catch(fail);
  }
});

agent.on("error", (error) => {
  if (error.code === "ENOENT") {
    console.error(
      "Cursor CLI를 찾을 수 없습니다. 먼저 https://cursor.com/docs/cli/installation 의 절차로 설치하세요.",
    );
  } else {
    console.error(`Cursor CLI 실행 실패: ${error.message}`);
  }
  process.exitCode = 1;
  prompt.close();
});

agent.on("exit", (code, signal) => {
  if (code && code !== 0) {
    console.error(`Cursor CLI가 종료되었습니다 (code=${code}, signal=${signal ?? "없음"}).`);
    process.exitCode = code;
  }
  prompt.close();
});

function fail(error) {
  console.error(`\n오류: ${error.message}`);
  process.exitCode = 1;
  agent.kill();
  prompt.close();
}

async function main() {
  await send("initialize", {
    protocolVersion: 1,
    clientCapabilities: {
      fs: { readTextFile: false, writeTextFile: false },
      terminal: false,
    },
    clientInfo: {
      name: "sap-gui-abap-acp-client",
      version: "1.0.0",
    },
  });

  await send("authenticate", { methodId: "cursor_login" });
  const { sessionId } = await send("session/new", {
    cwd: process.cwd(),
    mcpServers: [],
  });

  const commandLinePrompt = process.argv.slice(2).join(" ").trim();
  let nextPrompt =
    commandLinePrompt ||
    "세션 시작. 저장소의 AGENTS.md, SKILL.md, HARNESS.md와 Cursor 규칙을 읽고 따르세요. 사용자 질문에는 cursor/ask_question 선택형 질문 UI를 사용하세요.";

  while (nextPrompt !== "/exit") {
    await send("session/prompt", {
      sessionId,
      prompt: [{ type: "text", text: nextPrompt }],
    });
    console.log("");
    nextPrompt = (await prompt.question("\n다음 요청 (/exit: 종료): ")).trim();
    if (!nextPrompt) nextPrompt = "계속 진행하세요.";
  }

  agent.stdin.end();
  agent.kill();
  prompt.close();
}

main().catch(fail);
