#!/usr/bin/env node
const { execFileSync } = require("child_process");
const path = require("path");

const script = path.join(__dirname, "..", "runtime", "install.sh");

try {
  execFileSync("bash", [script], { stdio: "inherit" });
} catch {
  process.exit(1);
}
