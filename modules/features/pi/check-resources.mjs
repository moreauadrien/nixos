// Usage: node check-resources.mjs /path/to/pi-monorepo /nix/store/...-pi-personal-resources-1.0.0
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const { DefaultResourceLoader } = await import(
  pathToFileURL(resolve(process.argv[2], "dist/core/resource-loader.js"))
);
const cwd = mkdtempSync(`${tmpdir()}/pi-resources-check-`);
try {
  const loader = new DefaultResourceLoader({
    cwd,
    agentDir: `${cwd}/agent`,
    additionalExtensionPaths: [resolve(process.argv[3])],
    noExtensions: true,
    noSkills: true,
    noPromptTemplates: true,
    noThemes: true,
    noContextFiles: true,
  });
  await loader.reload();
  const { extensions, errors } = loader.getExtensions();
  assert.deepEqual(errors, []);
  assert.equal(extensions.length, 4);
  const names = loader.getSkills().skills.map((skill) => skill.name).sort();
  assert.deepEqual(names, ["caveman", "council-mode", "pi-subagents", "ponytail"]);
  const tools = extensions.flatMap((extension) => [...extension.tools.keys()]);
  assert(tools.includes("ask_user_question"));
  assert(tools.includes("subagents_enable"));
  console.log("OK: four extensions and four skills loaded from the bundled package.");
} finally {
  rmSync(cwd, { recursive: true, force: true });
}
