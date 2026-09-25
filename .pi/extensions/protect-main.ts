/**
 * Protect the `main` worktree AND the `main` branch.
 *
 * Hard-blocks any attempt to modify files under the main worktree:
 *  - `write` / `edit` tool calls targeting /nixos/main (or the host path)
 *  - `bash` tool calls (model) and `!` user commands that would mutate it
 *
 * Also hard-blocks anything that would update the `main` *branch* itself —
 * in particular merging INTO main:
 *  - `git merge` / `git pull` / `git rebase` / `git reset` / `git commit` /
 *    `git cherry-pick` / `git revert` / `git am` running inside the main
 *    worktree (via cwd, `cd /nixos/main && ...`, or `git -C main ...`)
 *  - moving the ref behind git's back: `git push . x:main`,
 *    `git branch -f main`, `git update-ref refs/heads/main`,
 *    `git symbolic-ref ... refs/heads/main`
 *  - `git worktree add <path> main` and worktree ops on the main path
 *
 * Allowed: read-only operations (ls, cat, grep, git status/log/diff...),
 * plus mutating git ops that don't update the main branch — e.g.
 * `git merge main` run from a feature worktree (brings main INTO the
 * feature branch), or `git worktree add/remove` for feature worktrees.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { resolve } from "node:path";

const MAIN_ROOTS = ["/nixos/main", "/home/adrien/nixos/main"];

const REASON =
	"'main' worktree and branch are protected. Work in a feature worktree instead: " +
	"cd /nixos && git worktree add <feature-name>, then work in ./<feature-name>. " +
	"Merging INTO 'main' is forbidden for the agent — the user merges manually. " +
	"See /nixos/AGENTS.md.";

/** Is a path inside the main worktree (resolved against `base`)? */
function inMain(p: string, base = "/"): boolean {
	const abs = resolve(base, p);
	return MAIN_ROOTS.some((r) => abs === r || abs.startsWith(r + "/"));
}

/** Does a shell command reference the main worktree (explicit path or bare `main`)? */
function mentionsMain(cmd: string): boolean {
	if (cmd.includes("/nixos/main") || cmd.includes("/home/adrien/nixos/main")) return true;
	// bare `main` token: ./main, main/, " main", GIT_WORK_TREE=main...
	return /(^|[\s"'(=./])main([/'"\s;)&|]|$)/.test(cmd);
}

/** Read-only git subcommands (fine even when they mention main). */
const GIT_READONLY =
	/\bgit\b(?:\s+-[^\s]+\s+|\s+)(?:status|log|diff|show|branch|rev-parse|ls-tree|describe|shortlog|worktree\s+list)\b/;

/** Mutating git ops on a main *path* that stay allowed from feature worktrees. */
const GIT_ALLOWED_MAIN_PATH =
	/\bgit\b(?:\s+-[^\s]+\s+|\s+)(?:merge|restore|worktree\s+(?:add|remove))\b/;

/** Direct-write indicators aimed at a main path (never allowed, even with GIT_ALLOWED). */
function isDirectWrite(cmd: string): boolean {
	// redirection / tee / rm ... with a main path anywhere in the same segment
	const segs = cmd.split(/[;|&]+/);
	return segs.some((s) => {
		const hasMain = s.includes("/nixos/main") || s.includes("/home/adrien/nixos/main");
		if (!hasMain) return false;
		return /\b(tee|rm|mv|cp|ln|touch|truncate|dd|install|rsync|sed\s+-i|chmod|chown|chattr)\b/.test(s) || />>?/.test(s);
	});
}

type GitSegment = { runsInMain: boolean; sub: string; flags: string[]; args: string[] };

/** Git global options that take a separate value word. */
const GIT_GLOBAL_OPTS_WITH_VALUE = new Set([
	"-C",
	"-c",
	"--git-dir",
	"--work-tree",
	"--namespace",
	"--exec-path",
	"--super-project",
]);

/** Parse a shell command into per-segment git invocations. */
function gitSegments(cmd: string, cwd: string | undefined): GitSegment[] {
	const segs: GitSegment[] = [];
	let cdDir: string | null = null;
	for (const raw of cmd.split(/[;|&]+/)) {
		// strip parens / quotes left over from subshells like (cd x && git ...)
		const seg = raw.trim().replace(/^[({\["'`\s]+/, "").replace(/[)}\]"'`\s]+$/, "");
		if (!seg) continue;
		const cd = seg.match(/^cd\s+(\S+)$/);
		if (cd) {
			cdDir = resolve(cwd ?? "/", cd[1]);
			continue;
		}
		if (!/^git(?:\s|$)/.test(seg)) continue;

		const words = seg.split(/\s+/).slice(1);
		let sub = "";
		const flags: string[] = [];
		const args: string[] = [];
		for (let i = 0; i < words.length; i++) {
			const w = words[i];
			if (GIT_GLOBAL_OPTS_WITH_VALUE.has(w)) {
				i++; // skip its value
				continue;
			}
			if (w.startsWith("-")) {
				flags.push(w);
				continue;
			}
			if (!sub) sub = w;
			else args.push(w);
		}

		// Where does this git command run? `-C dir` / `--git-dir=...` /
		// `--work-tree=...` override the cwd; otherwise a preceding `cd`, else ctx.cwd.
		const cArg = seg.match(/\bgit\s+(?:-C\s*=?\s*(\S+)|--(?:git|work)-dir[=\s]+(\S+))/);
		const dir = cArg ? (cArg[1] ?? cArg[2]) : null;
		const runsInMain = dir ? inMain(dir, cwd ?? "/") : inMain(cdDir ?? cwd ?? "/", "/");

		segs.push({ runsInMain, sub, flags, args });
	}
	return segs;
}

/** Git subcommands that never mutate anything (safe even inside main). */
const GIT_SUB_READONLY = new Set([
	"status", "log", "diff", "show", "rev-parse", "ls-tree", "ls-files",
	"describe", "shortlog", "cat-file", "blame", "grep", "remote", "tag",
]);

/**
 * Would this command mutate the main worktree or update the `main` branch
 * itself (merge INTO main, ref update, worktree checkout of main, ...)?
 * Never allowed, even from a feature worktree.
 */
function updatesMainBranch(cmd: string, cwd?: string): boolean {
	// env-var overrides pointing at the main worktree
	if (/\bGIT_(?:DIR|WORK_TREE)=\S*main\b/.test(cmd)) return true;

	return gitSegments(cmd, cwd).some(({ runsInMain, sub, flags, args }) => {
		// any non-read-only git command inside the main worktree is out
		if (runsInMain && sub && !GIT_SUB_READONLY.has(sub) && !(sub === "worktree" && args[0] === "list"))
			return true;

		const refMovers = ["push", "branch", "update-ref", "symbolic-ref", "worktree"];
		if (!runsInMain && !refMovers.includes(sub)) return false;
		const rest = args.join(" ");

		switch (sub) {
			// branch-updating ops, forbidden when run in the main worktree
			case "merge":
			case "pull":
			case "rebase":
			case "reset":
			case "commit":
			case "cherry-pick":
			case "revert":
			case "am":
			case "stash":
				return runsInMain;

			case "push": {
				// only local ref updates move the local main branch
				const repo = args[0] ?? "";
				const local =
					repo === "." ||
					repo.startsWith("/") ||
					repo.startsWith("./") ||
					repo.startsWith("../") ||
					repo.startsWith("file:");
				if (!local) return false;
				return /\S*:(?:refs\/heads\/)?main\b/.test(rest);
			}

			case "branch": {
				const force =
					flags.includes("--force") ||
					flags.some((f) => /^-(?!-)/.test(f) && /[fdDB]/.test(f.slice(1)));
				const namesMain = args.some((a) => a === "main" || a === "refs/heads/main");
				return force && namesMain;
			}

			case "update-ref":
				return /refs\/heads\/main\b/.test(rest) && !args.some((a) => a === "-d" || a === "--delete");

			case "symbolic-ref":
				return /refs\/heads\/main\b/.test(rest);

			case "worktree": {
				const op = args[0];
				if (op === "add") {
					if (args.slice(1).some((a) => inMain(a, cwd ?? "/"))) return true;
					// explicit start point `main` (AGENTS.md forbids it anyway)
					return /(^|\s)main$/.test(rest);
				}
				if (op === "move" || op === "remove") {
					return args.slice(1).some((a) => inMain(a, cwd ?? "/"));
				}
				return false;
			}

			default:
				return false;
		}
	});
}

/** Decide whether a shell command touching main should be blocked. */
function shouldBlockCommand(cmd: string, cwd?: string): string | null {
	if (updatesMainBranch(cmd, cwd)) return REASON;
	if (!mentionsMain(cmd)) return null;
	if (isDirectWrite(cmd)) return REASON;
	// allowlist: plain read-only commands with a main path
	const readOnlyCmd =
		/^\s*(?:sudo\s+)?(?:ls|cat|head|tail|grep|rg|find|stat|file|wc|diff|tree|bat|less|nix(?:os-version)?\s+(?:build|eval)|nix-shell|nix-shell-)?\b/.test(
			cmd,
		) && !/\b(rm|mv|cp|tee|touch|chmod|sed|truncate|dd|install|rsync)\b/.test(cmd);
	if (readOnlyCmd) return null;
	if (GIT_READONLY.test(cmd)) return null;
	if (GIT_ALLOWED_MAIN_PATH.test(cmd)) return null;
	return REASON;
}

export default function (pi: ExtensionAPI) {
	// 1) File tools: write / edit targeting main
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName === "write" || event.toolName === "edit") {
			const p = event.input.path as string | undefined;
			if (p && inMain(p, ctx.cwd ?? process.cwd())) {
				if (ctx.hasUI) ctx.ui.notify(`Blocked: ${p} is in the protected main worktree`, "warning");
				return { block: true, reason: REASON };
			}
			return undefined;
		}

		// 2) Model bash tool
		if (event.toolName === "bash") {
			const cmd = (event.input.command as string) ?? "";
			const reason = shouldBlockCommand(cmd, ctx.cwd ?? process.cwd());
			if (reason) {
				if (ctx.hasUI) ctx.ui.notify(`Blocked bash command touching main: ${cmd.slice(0, 80)}`, "warning");
				return { block: true, reason };
			}
		}

		return undefined;
	});

	// 3) User `!` shell commands
	pi.on("user_bash", async (event, ctx) => {
		const reason = shouldBlockCommand(event.command, ctx.cwd ?? process.cwd());
		if (reason) {
			if (ctx.hasUI) ctx.ui.notify(`Blocked: command would modify the main worktree or main branch`, "warning");
			return {
				result: { output: `BLOCKED: ${reason}`, exitCode: 1, cancelled: false, truncated: false },
			};
		}
		return undefined;
	});
}
