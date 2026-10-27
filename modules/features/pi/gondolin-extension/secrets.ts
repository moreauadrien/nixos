import { createHttpHooks } from "@earendil-works/gondolin";

export function githubNetwork(token: string | undefined) {
	return createHttpHooks({
		secrets: token ? {
			GH_TOKEN: { hosts: ["api.github.com"], value: token },
		} : {},
	});
}

export function sanitizeEnv(env: NodeJS.ProcessEnv | undefined): Record<string, string> | undefined {
	if (!env) return undefined;
	const result: Record<string, string> = {};
	for (const [key, value] of Object.entries(env)) {
		// Pi's bash tool forwards the host environment. Keep the VM's placeholder
		// instead of overriding it with the real host token on each command.
		if (key === "GH_TOKEN") continue;
		if (typeof value === "string") result[key] = value;
	}
	return result;
}
