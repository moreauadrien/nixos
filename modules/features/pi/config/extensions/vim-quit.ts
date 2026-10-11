import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Quit like /quit: ctx.shutdown() alone only exits when the agent is idle;
  // while it is running, it just sets a flag consumed at agent_settled.
  const quit = (ctx: { abort(): void; shutdown(): void }) => {
    ctx.abort();
    ctx.shutdown();
  };

  pi.on("input", (event, ctx) => {
    if (event.text === ":q" || event.text === ":q!") {
      quit(ctx);
      return { action: "handled" };
    }
  });

  pi.registerCommand("q", {
    description: "Quit pi (alias of /quit)",
    handler: async (_args, ctx) => {
      quit(ctx);
    },
  });
}
