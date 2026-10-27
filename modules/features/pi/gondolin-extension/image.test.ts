// Run with: node --test modules/features/pi/gondolin-extension/*.test.ts
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { ensureImage, imageTag } from "./image.ts";

const source = path.dirname(fileURLToPath(import.meta.url));

test("image tag tracks image inputs, not their location", () => {
	const root = mkdtempSync(path.join(tmpdir(), "pi-image-"));
	try {
		for (const file of ["package-lock.json", "build-config.json", "provision-nix.sh"]) {
			writeFileSync(path.join(root, file), readFileSync(path.join(source, file)));
		}
		assert.equal(imageTag(root), imageTag(source));
		for (const file of ["package-lock.json", "build-config.json", "provision-nix.sh"]) {
			const original = readFileSync(path.join(root, file));
			writeFileSync(path.join(root, file), Buffer.concat([original, Buffer.from("\n")]));
			assert.notEqual(imageTag(root), imageTag(source));
			writeFileSync(path.join(root, file), original);
		}
	} finally {
		rmSync(root, { recursive: true, force: true });
	}
});

test("reuse cached images, build missing images and surface failures without fallback", async () => {
	const root = mkdtempSync(path.join(tmpdir(), "pi-image-cli-"));
	const oldPath = process.env.PATH;
	const oldCache = process.env.XDG_CACHE_HOME;
	process.env.PATH = `${root}:${oldPath}`;
	process.env.XDG_CACHE_HOME = path.join(root, "cache");
	const calls = path.join(root, "calls");
	const cli = (inspect: number, build: number) => writeFileSync(path.join(root, "gondolin"), `#!/bin/sh
printf '%s\\n' "$@" >> '${calls}'
if [ "$1" = image ]; then exit ${inspect}; fi
echo build-output
echo build-error >&2
exit ${build}
`, { mode: 0o700 });
	try {
		cli(0, 99);
		assert.equal(await ensureImage(source, () => assert.fail("cached image rebuilt")), imageTag(source));
		assert.equal(readFileSync(calls, "utf8"), `image\ninspect\n${imageTag(source)}\n`);

		let log = "";
		cli(1, 0);
		assert.equal(await ensureImage(source, (value) => { log = value; }), imageTag(source));
		assert.equal(readFileSync(log, "utf8"), "build-output\nbuild-error\n");
		assert.ok(readFileSync(calls, "utf8").includes(`build\n--config\n${path.join(source, "build-config.json")}\n--tag\n${imageTag(source)}\n`));

		cli(1, 42);
		await assert.rejects(ensureImage(source, () => {}), /build failed \(42\).*pi-build-/);
		rmSync(path.join(root, "gondolin"));
		process.env.PATH = root;
		await assert.rejects(ensureImage(source, () => assert.fail("missing CLI must not trigger build")), /ENOENT/);
	} finally {
		if (oldPath === undefined) delete process.env.PATH;
		else process.env.PATH = oldPath;
		if (oldCache === undefined) delete process.env.XDG_CACHE_HOME;
		else process.env.XDG_CACHE_HOME = oldCache;
		rmSync(root, { recursive: true, force: true });
	}
});
