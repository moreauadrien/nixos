// Run with: node --test modules/features/pi/gondolin-extension/github-app.test.ts
import assert from "node:assert/strict";
import { generateKeyPairSync, verify } from "node:crypto";
import { chmodSync, linkSync, mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { setImmediate } from "node:timers/promises";
import { test, type TestContext } from "node:test";
import { loadGithubAppConfig, startGithubApp, type GithubAppSession } from "./github-app.ts";

const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
const config = { appId: "123", installationId: "456", privateKey };
const now = Date.parse("2030-01-01T00:00:00Z");
const secret = "host-only-secret";
const requestError = "GitHub App token request failed; check connectivity, App credentials and installation permissions";
const configError = "Invalid GitHub App configuration: use string IDs, an absolute RSA key path, and private host-only files (chmod 600)";
const mockFetch = (fn: (...args: Parameters<typeof fetch>) => unknown) => fn as typeof fetch;
const tokenResponse = (token = secret, lifetime = 600_000) => Response.json({
	token, expires_at: new Date(Date.now() + lifetime).toISOString(),
});
const clock = (t: TestContext) => t.mock.timers.enable({ apis: ["setTimeout", "Date"], now });
const settle = async () => { await setImmediate(); };
const request = async (session: GithubAppSession, host = "api.github.com") => session.httpHooks.onRequest!(
	new Request(`https://${host}/user`, { headers: { Authorization: `Bearer ${session.env.GH_TOKEN}` } }),
);
async function authorization(session: GithubAppSession) {
	const result = await request(session);
	assert.ok(result instanceof Request);
	return result.headers.get("Authorization");
}

test("App JWT is signed RS256 with bounded claims and a fixed, redirect-refusing API request", async (t) => {
	clock(t);
	const session = await startGithubApp(config, () => assert.fail("unexpected warning"), mockFetch(async (url, init) => {
		assert.equal(url, "https://api.github.com/app/installations/456/access_tokens");
		assert.equal(init?.method, "POST");
		assert.equal(init?.redirect, "error");
		assert.ok(init?.signal instanceof AbortSignal);
		const headers = new Headers(init?.headers);
		assert.equal(headers.get("Accept"), "application/vnd.github+json");
		assert.equal(headers.get("X-GitHub-Api-Version"), "2022-11-28");
		assert.equal(headers.get("User-Agent"), "pi-gondolin");
		const [header, claims, signature] = headers.get("Authorization")!.slice(7).split(".");
		assert.deepEqual(JSON.parse(Buffer.from(header, "base64url").toString()), { alg: "RS256", typ: "JWT" });
		assert.deepEqual(JSON.parse(Buffer.from(claims, "base64url").toString()), {
			iat: now / 1000 - 60, exp: now / 1000 + 540, iss: "123",
		});
		assert.ok(verify("RSA-SHA256", Buffer.from(`${header}.${claims}`), publicKey, Buffer.from(signature, "base64url")));
		return tokenResponse();
	}));
	t.after(() => session.close());
	assert.notEqual(session.env.GH_TOKEN, secret);
	assert.equal(await authorization(session), `Bearer ${secret}`);
	assert.match(session.status(), /GitHub App 123, installation 456/);
});

test("invalid token responses and network errors expose only a sanitized error", async (t) => {
	clock(t);
	const invalidBodies = [null, {}, { token: "", expires_at: "2031-01-01" },
		{ token: 123, expires_at: "2031-01-01" }, { token: secret, expires_at: "bad" },
		{ token: secret, expires_at: now + 600_000 },
		{ token: secret, expires_at: new Date(now).toISOString() },
		{ token: secret, expires_at: new Date(now + 60_000).toISOString() }];
	const failures = [
		...invalidBodies.map((body) => () => Response.json(body)),
		() => new Response(secret, { status: 403 }),
		() => new Response(secret),
		(_url: Parameters<typeof fetch>[0], init?: RequestInit) => {
			throw new Error(`${secret}: ${new Headers(init?.headers).get("Authorization")}`);
		},
	];
	for (const fail of failures) {
		await assert.rejects(startGithubApp(config, () => assert.fail("unexpected warning"), mockFetch(fail)),
			{ message: requestError });
	}
});

test("configuration distinguishes missing from malformed and validates IDs and RSA keys", (t) => {
	const root = mkdtempSync(path.join(tmpdir(), "github-app-"));
	t.after(() => rmSync(root, { recursive: true, force: true }));
	const file = path.join(root, "config.json");
	const key = path.join(root, "key.pem");
	writeFileSync(key, privateKey.export({ type: "pkcs8", format: "pem" }), { mode: 0o600 });
	const valid = { appId: "123", installationId: "456", privateKeyFile: key };
	const save = (value: unknown) => writeFileSync(file, JSON.stringify(value), { mode: 0o600 });
	assert.equal(loadGithubAppConfig(file, []), undefined);
	symlinkSync(path.join(root, "absent.json"), file);
	assert.throws(() => loadGithubAppConfig(file, []), { message: configError });
	rmSync(file);
	save(valid);
	assert.equal(loadGithubAppConfig(file, [])?.privateKey.asymmetricKeyType, "rsa");
	const invalid = [null, [], {}, ...["appId", "installationId"].flatMap((field) =>
		[123, "", "0", "-1", "1.5", "01", "1e2", "123\n"].map((id) => ({ ...valid, [field]: id }))),
		{ ...valid, privateKeyFile: "relative.pem" }, { ...valid, privateKeyFile: 123 },
		{ ...valid, privateKeyFile: path.join(root, "missing.pem") }];
	for (const value of invalid) {
		save(value);
		assert.throws(() => loadGithubAppConfig(file, []), { message: configError });
	}
	writeFileSync(file, `{"secret": "${secret}"`, { mode: 0o600 });
	assert.throws(() => loadGithubAppConfig(file, []), { message: configError });
	save(valid);
	writeFileSync(key, `invalid PEM ${secret}`);
	assert.throws(() => loadGithubAppConfig(file, []), { message: configError });
	const ec = generateKeyPairSync("ec", { namedCurve: "prime256v1" }).privateKey;
	writeFileSync(key, ec.export({ type: "pkcs8", format: "pem" }));
	assert.throws(() => loadGithubAppConfig(file, []), { message: configError });
});

test("credentials must be private, unlinked, host-only files including symlink aliases and targets", (t) => {
	const root = mkdtempSync(path.join(tmpdir(), "github-app-mounts-"));
	t.after(() => rmSync(root, { recursive: true, force: true }));
	const host = path.join(root, "host"), mount = path.join(root, "guest");
	mkdirSync(host); mkdirSync(mount);
	const key = path.join(host, "key.pem"), file = path.join(host, "config.json");
	writeFileSync(key, privateKey.export({ type: "pkcs8", format: "pem" }), { mode: 0o600 });
	const save = (privateKeyFile = key) => writeFileSync(file, JSON.stringify({ ...config, privateKey: undefined, privateKeyFile }), { mode: 0o600 });
	save();
	assert.ok(loadGithubAppConfig(file, [mount]));
	for (const credential of [file, key]) {
		chmodSync(credential, 0o644);
		assert.throws(() => loadGithubAppConfig(file, [mount]), { message: configError });
		chmodSync(credential, 0o600);
		const hardlink = `${credential}.link`;
		linkSync(credential, hardlink);
		assert.throws(() => loadGithubAppConfig(file, [mount]), { message: configError });
		rmSync(hardlink);
	}
	const alias = path.join(root, "mount-alias");
	symlinkSync(host, alias);
	assert.throws(() => loadGithubAppConfig(file, [alias]), { message: configError });
	assert.throws(() => loadGithubAppConfig(path.join(alias, "config.json"), [host]), { message: configError });
	const guestAlias = path.join(mount, "key-alias.pem");
	symlinkSync(key, guestAlias);
	save(guestAlias);
	assert.throws(() => loadGithubAppConfig(file, [mount]), { message: configError });
	const guestKey = path.join(mount, "key.pem"), hostAlias = path.join(host, "key-alias.pem");
	writeFileSync(guestKey, privateKey.export({ type: "pkcs8", format: "pem" }), { mode: 0o600 });
	symlinkSync(guestKey, hostAlias);
	save(hostAlias);
	assert.throws(() => loadGithubAppConfig(file, [mount]), { message: configError });
	save(host);
	assert.throws(() => loadGithubAppConfig(file, []), { message: configError });
});

test("scheduled renewal updates the secret behind a stable guest placeholder", async (t) => {
	clock(t);
	let calls = 0;
	const session = await startGithubApp(config, () => assert.fail("unexpected warning"), mockFetch(() => tokenResponse(`token-${++calls}`)));
	t.after(() => session.close());
	const placeholder = session.env.GH_TOKEN;
	t.mock.timers.tick(299_999);
	await settle();
	assert.equal(calls, 1);
	t.mock.timers.tick(1);
	await settle();
	assert.equal(calls, 2);
	assert.equal(session.env.GH_TOKEN, placeholder);
	assert.equal(await authorization(session), "Bearer token-2");
	assert.ok(!session.status().includes("token-2"));
	await session.close();
	t.mock.timers.tick(3_600_000); await settle();
	assert.equal(calls, 2);
});

test("transient renewal retries in 30 seconds, warns once, and clears warning on recovery", async (t) => {
	clock(t);
	let calls = 0;
	const warnings: string[] = [];
	const session = await startGithubApp(config, (message) => warnings.push(message), mockFetch(() => {
		calls++;
		if (calls === 2 || calls === 3) throw new Error(secret);
		return tokenResponse(`token-${calls}`);
	}));
	t.after(() => session.close());
	t.mock.timers.tick(300_000); await settle();
	assert.equal(warnings.length, 1);
	assert.ok(!warnings[0].includes(secret));
	assert.match(session.status(), /Renewal failed/);
	assert.equal(await authorization(session), "Bearer token-1");
	t.mock.timers.tick(29_999); await settle();
	assert.equal(calls, 2);
	t.mock.timers.tick(1); await settle();
	assert.equal(calls, 3);
	assert.equal(warnings.length, 1);
	t.mock.timers.tick(30_000); await settle();
	assert.equal(calls, 4);
	assert.equal(await authorization(session), "Bearer token-4");
	assert.doesNotMatch(session.status(), /Renewal failed/);
});

test("expired GitHub requests block on failed renewal and concurrent hooks coalesce on recovery", async (t) => {
	clock(t);
	let calls = 0;
	let recover: ((value: Response) => void) | undefined;
	const session = await startGithubApp(config, () => {}, mockFetch(() => {
		calls++;
		if (calls === 1) return tokenResponse();
		if (calls === 2) throw new Error(secret);
		return new Promise<Response>((resolve) => { recover = resolve; });
	}));
	t.after(() => session.close());
	// Jump the clock without running the scheduled proactive renewal.
	t.mock.timers.setTime(now + 600_000);
	await assert.rejects(request(session, "api.github.com."), { message: "GitHub App token renewal failed" });
	for (let i = 0; i < 3; i++) {
		await assert.rejects(request(session), { message: "GitHub App token renewal is backing off" });
	}
	assert.equal(calls, 2);
	t.mock.timers.setTime(now + 630_000);
	const first = authorization(session);
	const second = request(session, "github.com");
	assert.equal(calls, 3);
	recover!(tokenResponse("recovered"));
	assert.equal(await first, "Bearer recovered");
	const result = await second;
	assert.ok(result instanceof Request);
	assert.equal(result.headers.get("Authorization"), "Bearer recovered");
});

test("close aborts inflight renewal, clears timers, and prevents hooks or retries", async (t) => {
	clock(t);
	let calls = 0;
	let signal: AbortSignal | undefined;
	const warnings: string[] = [];
	const session = await startGithubApp(config, (message) => warnings.push(message), mockFetch((_url, init) => {
		if (++calls === 1) return tokenResponse();
		signal = init!.signal!;
		return new Promise<Response>((_resolve, reject) => {
			signal!.addEventListener("abort", () => reject(new Error(secret)), { once: true });
		});
	}));
	t.mock.timers.tick(300_000);
	assert.equal(calls, 2);
	const timers = t.mock.method(globalThis, "setTimeout");
	await session.close();
	assert.equal(signal!.aborted, true);
	assert.equal(timers.mock.callCount(), 0);
	t.mock.timers.tick(3_600_000); await settle();
	assert.equal(calls, 2);
	assert.deepEqual(warnings, []);
	await assert.rejects(request(session), { message: "GitHub App session closed" });
	await session.close();
});
