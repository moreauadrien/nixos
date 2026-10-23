import { execFile } from "node:child_process";

export default function (pi) {
  pi.on("agent_end", () => {
    execFile("notify-send", ["Pi", "Conversation terminée"], (error) => {
      if (error) console.error("Échec de notify-send:", error.message);
    });
  });
}
