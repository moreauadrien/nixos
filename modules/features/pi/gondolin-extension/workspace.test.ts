// Run with: node --test modules/features/pi/gondolin-extension/workspace.test.ts
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";
import { isInsideHostPath, workspaceMountPaths } from "./workspace.ts";

test("preserve Git paths for plain directories, repositories and linked worktrees", () => {
	const root = mkdtempSync(path.join(tmpdir(), "pi-worktree-"));
	const git = (cwd: string, ...args: string[]) => execFileSync("git", ["-C", cwd, ...args], {
		encoding: "utf8",
		stdio: ["ignore", "pipe", "pipe"],
	}).trim();
	try {
		assert.deepEqual(workspaceMountPaths(root), [root]);
		assert.equal(isInsideHostPath(root, `${root}-sibling`), false);
		assert.equal(isInsideHostPath(root, path.join(root, "..hidden")), true);

		const main = path.join(root, "main repo");
		mkdirSync(main);
		git(main, "init");
		git(main, "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "--allow-empty", "-m", "init");
		assert.deepEqual(workspaceMountPaths(main), [main]);

		const linked = path.join(root, "linked worktree");
		git(main, "worktree", "add", "-b", "linked", linked);
		const common = path.join(main, ".git");
		assert.deepEqual(workspaceMountPaths(linked), [linked, common]);
		// Both the forward .git link and Git's backlink retain their host paths.
		const gitDir = readFileSync(path.join(linked, ".git"), "utf8").trim().slice("gitdir: ".length);
		assert.ok(isInsideHostPath(common, gitDir));
		assert.equal(readFileSync(path.join(gitDir, "gitdir"), "utf8").trim(), path.join(linked, ".git"));
		assert.equal(git(linked, "status", "--porcelain"), "");

		// Layout used by the NixOS configuration: bare .git plus sibling worktrees.
		const bareRoot = path.join(root, "bare repo");
		mkdirSync(bareRoot);
		git(root, "clone", "--bare", main, path.join(bareRoot, ".git"));
		assert.deepEqual(workspaceMountPaths(bareRoot), [bareRoot]);
		const feature = path.join(bareRoot, "feature");
		git(bareRoot, "worktree", "add", feature);
		assert.deepEqual(workspaceMountPaths(feature), [feature, path.join(bareRoot, ".git")]);
		assert.equal(git(feature, "status", "--porcelain"), "");
	} finally {
		rmSync(root, { recursive: true, force: true });
	}
});
