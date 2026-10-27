import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { closeSync, mkdirSync, openSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

export function imageTag(directory: string): string {
	const hash = createHash("sha256");
	// Include the builder version as well as every image input.
	for (const file of ["package-lock.json", "build-config.json", "provision-nix.sh"]) {
		hash.update(file).update("\0").update(readFileSync(path.join(directory, file))).update("\0");
	}
	return `gondolin-nix:${hash.digest("hex").slice(0, 16)}`;
}

function run(args: string[], log?: string): Promise<number | null> {
	return new Promise((resolve, reject) => {
		const fd = log ? openSync(log, "w", 0o600) : undefined;
		try {
			const child = spawn("gondolin", args, { stdio: fd === undefined ? "ignore" : ["ignore", fd, fd] });
			child.on("error", reject);
			child.on("close", resolve);
		} finally {
			if (fd !== undefined) closeSync(fd);
		}
	});
}

export async function ensureImage(directory: string, onBuild: (log: string) => void): Promise<string> {
	const tag = imageTag(directory);
	if ((await run(["image", "inspect", tag])) === 0) return tag;

	const cache = path.join(process.env.XDG_CACHE_HOME ?? path.join(homedir(), ".cache"), "gondolin");
	mkdirSync(cache, { recursive: true });
	const log = path.join(cache, `pi-build-${tag.split(":")[1]}-${process.pid}.log`);
	onBuild(log);
	const code = await run(["build", "--config", path.join(directory, "build-config.json"), "--tag", tag], log);
	if (code !== 0) throw new Error(`Gondolin image build failed (${code}). See ${log}`);
	return tag;
}
