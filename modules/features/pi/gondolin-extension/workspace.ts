import { spawnSync } from "node:child_process";
import path from "node:path";

export function isInsideHostPath(root: string, value: string): boolean {
	const relative = path.relative(root, value);
	return relative === "" || (relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative));
}

/** Keep host paths intact: Git worktree links contain absolute paths. */
export function workspaceMountPaths(cwd: string): string[] {
	const mounts = [cwd];
	const result = spawnSync("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], {
		cwd,
		encoding: "utf8",
	});
	if (result.error) throw result.error;
	if (result.status === 0) {
		const commonDir = result.stdout.trimEnd();
		// A linked worktree needs writable refs, objects and index outside cwd.
		// Do not expose the main working tree (or the entire home directory).
		if (!isInsideHostPath(cwd, commonDir)) mounts.push(commonDir);
	}
	return mounts;
}
