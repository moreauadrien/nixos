import { createPrivateKey, sign, type KeyObject } from "node:crypto";
import { lstatSync, readFileSync, realpathSync, statSync } from "node:fs";
import path from "node:path";
import { githubNetwork } from "./secrets.ts";
import { isInsideHostPath } from "./workspace.ts";

export type GithubAppConfig = {
	appId: string;
	installationId: string;
	privateKey: KeyObject;
};

/** Reject both lexical and symlink aliases into any guest-visible host mount. */
function privateHostFile(file: string, mounts: string[]): string {
	const resolved = realpathSync(file);
	for (const mount of mounts) {
		for (const root of [path.resolve(mount), realpathSync(mount)]) {
			if (isInsideHostPath(root, path.resolve(file)) || isInsideHostPath(root, resolved)) {
				throw new Error("GitHub App credentials must be outside all Gondolin mounts");
			}
		}
	}
	const stat = statSync(resolved);
	if (!stat.isFile() || (stat.mode & 0o077) !== 0 || stat.nlink !== 1 || stat.uid !== process.getuid?.()) {
		throw new Error("GitHub App credential files must be owned by the current user, private (chmod 600), and not hard-linked");
	}
	return resolved;
}

export function loadGithubAppConfig(file: string, mounts: string[]): GithubAppConfig | undefined {
	// Only an absent default config disables App authentication. Invalid or
	// inaccessible credentials must not silently fall back to another identity.
	try {
		lstatSync(file);
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return undefined;
		throw new Error("Cannot access GitHub App configuration");
	}
	try {
		const config = JSON.parse(readFileSync(privateHostFile(file, mounts), "utf8"));
		if (!config || typeof config !== "object" ||
			typeof config.appId !== "string" || !/^[1-9]\d*$/.test(config.appId) ||
			typeof config.installationId !== "string" || !/^[1-9]\d*$/.test(config.installationId) ||
			typeof config.privateKeyFile !== "string" || !path.isAbsolute(config.privateKeyFile)) {
			throw new Error("Invalid configuration");
		}
		const keyFile = privateHostFile(config.privateKeyFile, mounts);
		const privateKey = createPrivateKey(readFileSync(keyFile));
		if (privateKey.asymmetricKeyType !== "rsa") throw new Error("Expected an RSA private key");
		return { appId: config.appId, installationId: config.installationId, privateKey };
	} catch {
		// Parser and crypto errors may include credential data. Never expose them.
		throw new Error("Invalid GitHub App configuration: use string IDs, an absolute RSA key path, and private host-only files (chmod 600)");
	}
}

async function installationToken(config: GithubAppConfig, fetcher: typeof fetch, signal: AbortSignal) {
	const now = Math.floor(Date.now() / 1000);
	const encode = (value: unknown) => Buffer.from(JSON.stringify(value)).toString("base64url");
	const payload = `${encode({ alg: "RS256", typ: "JWT" })}.${encode({ iat: now - 60, exp: now + 540, iss: config.appId })}`;
	const jwt = `${payload}.${sign("RSA-SHA256", Buffer.from(payload), config.privateKey).toString("base64url")}`;
	try {
		const response = await fetcher(`https://api.github.com/app/installations/${config.installationId}/access_tokens`, {
			method: "POST",
			redirect: "error",
			headers: {
				Authorization: `Bearer ${jwt}`,
				Accept: "application/vnd.github+json",
				"X-GitHub-Api-Version": "2022-11-28",
				"User-Agent": "pi-gondolin",
			},
			signal: AbortSignal.any([signal, AbortSignal.timeout(15_000)]),
		});
		if (!response.ok) throw new Error("Token request failed");
		const body = await response.json();
		const expiresAt = typeof body?.expires_at === "string" ? Date.parse(body.expires_at) : NaN;
		if (typeof body?.token !== "string" || !body.token || !Number.isFinite(expiresAt) || expiresAt <= Date.now() + 60_000) {
			throw new Error("Invalid installation token");
		}
		return { token: body.token as string, expiresAt };
	} catch {
		// No response body, JWT, token or raw network error reaches the UI/tools.
		throw new Error("GitHub App token request failed; check connectivity, App credentials and installation permissions");
	}
}

export type GithubAppSession = Awaited<ReturnType<typeof startGithubApp>>;

export async function startGithubApp(
	config: GithubAppConfig,
	onWarning: (message: string) => void,
	fetcher: typeof fetch = fetch,
) {
	const controller = new AbortController();
	const initial = await installationToken(config, fetcher, controller.signal);
	const network = githubNetwork(initial.token);
	let expiresAt = initial.expiresAt;
	let warning = false;
	let retryAt = 0;
	let closed = false;
	let timer: ReturnType<typeof setTimeout> | undefined;
	let refreshing: Promise<void> | undefined;

	function schedule(delay: number) {
		if (timer) clearTimeout(timer);
		if (!closed) timer = setTimeout(() => { void refresh().catch(() => {}); }, delay).unref();
	}
	function scheduleRenewal() {
		const remaining = expiresAt - Date.now();
		schedule(Math.max(1_000, remaining - Math.min(5 * 60_000, remaining / 2)));
	}
	function refresh(): Promise<void> {
		if (closed) return Promise.reject(new Error("GitHub App session closed"));
		if (refreshing) return refreshing;
		if (Date.now() < retryAt) return Promise.reject(new Error("GitHub App token renewal is backing off"));
		refreshing = installationToken(config, fetcher, controller.signal).then((next) => {
			if (closed) return;
			network.secretManager.updateSecret("GH_TOKEN", { value: next.token });
			expiresAt = next.expiresAt;
			warning = false;
			retryAt = 0;
			scheduleRenewal();
		}).catch(() => {
			if (!closed) {
				retryAt = Date.now() + 30_000;
				schedule(30_000);
				if (!warning) {
					warning = true;
					onWarning("GitHub App token renewal failed; retrying automatically. GitHub requests will be blocked after expiry until renewal succeeds.");
				}
			}
			throw new Error("GitHub App token renewal failed");
		}).finally(() => { refreshing = undefined; });
		return refreshing;
	}

	const substitute = network.httpHooks.onRequest!;
	network.httpHooks.onRequest = async (request) => {
		if (closed) throw new Error("GitHub App session closed");
		const host = new URL(request.url).hostname.replace(/\.$/, "");
		if ((host === "api.github.com" || host === "github.com") && Date.now() >= expiresAt) {
			await refresh();
		}
		return substitute(request);
	};
	scheduleRenewal();
	return {
		env: network.env,
		httpHooks: network.httpHooks,
		status: () => `GitHub App ${config.appId}, installation ${config.installationId}\nToken expires: ${new Date(expiresAt).toISOString()}${warning ? "\nRenewal failed; retrying" : ""}`,
		close: async () => {
			closed = true;
			if (timer) clearTimeout(timer);
			controller.abort();
			await refreshing?.catch(() => {});
			network.secretManager.deleteSecret("GH_TOKEN");
		},
	};
}
