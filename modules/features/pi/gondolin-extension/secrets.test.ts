// Run with: node --test modules/features/pi/gondolin-extension/*.test.ts
import assert from "node:assert/strict";
import { test } from "node:test";
import { githubNetwork, sanitizeEnv } from "./secrets.ts";

test("GitHub token stays behind a placeholder scoped to the GitHub API", async () => {
	const token = "test-host-only-token";
	const { env, httpHooks } = githubNetwork(token);
	assert.ok(env.GH_TOKEN);
	assert.notEqual(env.GH_TOKEN, token);
	assert.ok(!JSON.stringify(env).includes(token));

	const request = (host: string) => new Request(`https://${host}/user`, {
		headers: { Authorization: `Bearer ${env.GH_TOKEN}` },
	});
	const github = await httpHooks.onRequest!(request("api.github.com"));
	assert.ok(github instanceof Request);
	assert.equal(github.headers.get("Authorization"), `Bearer ${token}`);
	for (const host of ["example.com", "api.github.com.example.com", "github.com"]) {
		await assert.rejects(async () => httpHooks.onRequest!(request(host)));
	}
	// Unauthenticated requests elsewhere remain possible.
	await httpHooks.onRequest!(new Request("https://example.com"));
});

test("no host token means no guest token", () => {
	assert.deepEqual(githubNetwork(undefined).env, {});
	assert.deepEqual(githubNetwork("").env, {});
});

test("bash environment cannot overwrite the VM placeholder with the host token", () => {
	const host = { GH_TOKEN: "test-host-only-token", PATH: "/bin", MISSING: undefined };
	assert.deepEqual(sanitizeEnv(host), { PATH: "/bin" });
	assert.equal(host.GH_TOKEN, "test-host-only-token");
	assert.equal(sanitizeEnv(undefined), undefined);
});
