#!/usr/bin/env node
// SafeCoder CLI
// Usage:
//   npx safecoder install          # install skill for Hermes Agent
//   npx safecoder init             # add SafeCoder files to current project
//   npx safecoder add              # alias for install

const fs = require("fs");
const path = require("path");
const os = require("os");
const { execSync } = require("child_process");

const args = process.argv.slice(2);
const command = args[0];

const repoDir = path.resolve(__dirname, "..");
const hermesHome = process.env.HERMES_HOME || path.join(os.homedir(), ".hermes");
const skillSource = path.join(repoDir, "skills", "software-development", "safecoder");
const skillDest = path.join(hermesHome, "skills", "software-development", "safecoder");

function help() {
  console.log(`SafeCoder CLI

Commands:
  install, add    Install the safecoder skill for Hermes Agent
  init            Add SafeCoder files (AGENT_SECURITY.md, audit script, etc.) to the current project
  help            Show this help

Examples:
  npm install @szymonsdev/safecoder
  npx safecoder install
  npx safecoder init
`);
}

function installSkill() {
  if (!fs.existsSync(skillSource)) {
    console.error(`Error: skill source not found at ${skillSource}`);
    process.exit(1);
  }

  fs.mkdirSync(path.dirname(skillDest), { recursive: true });
  fs.rmSync(skillDest, { recursive: true, force: true });
  fs.cpSync(skillSource, skillDest, { recursive: true });
  console.log(`SafeCoder skill installed to ${skillDest}`);

  addShellAliases();
}

function addShellAliases() {
  const shells = [
    path.join(os.homedir(), ".bashrc"),
    path.join(os.homedir(), ".zshrc"),
    path.join(os.homedir(), ".bash_aliases"),
  ];

  for (const file of shells) {
    if (!fs.existsSync(file)) continue;
    const marker = "alias hermes-web='hermes -s safecoder'";
    const content = fs.readFileSync(file, "utf8");
    if (content.includes(marker)) {
      console.log(`Aliases already present in ${file}`);
      continue;
    }
    fs.appendFileSync(
      file,
      `\n# SafeCoder aliases - auto-load security skill for web/app projects\nalias hermes-web='hermes -s safecoder'\nalias hermes-app='hermes -s safecoder'\nalias hermes-api='hermes -s safecoder'\n`
    );
    console.log(`Added aliases to ${file}`);
  }

  console.log("\nStart a new terminal or run: source ~/.bashrc");
  console.log("Then use: hermes-web, hermes-app, or hermes-api");
}

function initProject() {
  const initScript = path.join(repoDir, "init-project.sh");
  if (!fs.existsSync(initScript)) {
    console.error(`Error: ${initScript} not found`);
    process.exit(1);
  }
  execSync(`bash "${initScript}"`, { stdio: "inherit" });
}

switch (command) {
  case "install":
  case "add":
    installSkill();
    break;
  case "init":
    initProject();
    break;
  case "help":
  case "--help":
  case "-h":
    help();
    break;
  default:
    help();
    process.exit(command ? 1 : 0);
}
