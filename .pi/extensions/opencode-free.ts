// Provider "opencode" limité aux modèles gratuits (coût 0 en input et output).
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	let done = false;
	pi.on("session_start", async (_event, ctx) => {
		if (done) return;
		const provider = ctx.modelRegistry.getProvider("opencode");
		if (!provider) return;
		const clone = Object.create(
			Object.getPrototypeOf(provider),
			Object.getOwnPropertyDescriptors(provider),
		);
		clone.filterModels = (models: readonly any[]) =>
			models.filter((m) => !m.cost || (m.cost.input === 0 && m.cost.output === 0));
		pi.registerProvider(clone);
		done = true;
	});
}
