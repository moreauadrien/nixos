/**
 * Paste clipboard images as files the agent can read.
 *
 * Ctrl+V with an image in the clipboard writes it to
 * /tmp/pi-pastes/<pid>/pasted-image-<n>.<ext> on the host and inserts a
 * `[pasted image n]` marker in the editor, expanded to the file path on
 * submit (same mechanism as the built-in `[paste #1 +N lines]` text markers).
 * Markers are merged into atomic editor segments, so backspace/delete and
 * cursor movement treat them as a single unit, like built-in paste markers.
 *
 * The gondolin VM mounts this process's paste directory (one VM = one pi
 * process, keyed by process.pid) at the SAME guest path, so the path is valid
 * both inside and outside the VM, and a VM only ever sees its own pastes —
 * other VMs' paste directories are not mounted in the guest. Without
 * gondolin the agent reads the host file directly.
 *
 * Ctrl+V without an image falls back to the built-in behavior: copied file
 * paths (uri-list / gnome-copied-files), then plain text.
 */

import { CustomEditor, type ExtensionAPI, type ExtensionUIContext } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";

/** Root directory for pasted images; each pi process owns <root>/<pid>. */
const PASTE_ROOT = "/tmp/pi-pastes";
/** This process's paste directory. Keep in sync with the gondolin extension mount. */
const PASTE_DIR = `${PASTE_ROOT}/${process.pid}`;

const IMAGE_MIME_TYPES = ["image/png", "image/jpeg", "image/webp", "image/gif"] as const;
type ImageMimeType = (typeof IMAGE_MIME_TYPES)[number];

const EXTENSIONS: Record<ImageMimeType, string> = {
	"image/png": "png",
	"image/jpeg": "jpg",
	"image/webp": "webp",
	"image/gif": "gif",
};

type ClipboardImage = { bytes: Buffer; mimeType: ImageMimeType };

// Paste registry lives at module level so markers survive editor re-creation
// (session reload / session switch) within the same pi process.
const imagePastes = new Map<number, string>();
let pasteCounter = 0;
let ui: ExtensionUIContext | undefined;

function notify(message: string, level: "info" | "warning" | "error" = "info") {
	if (ui?.notify) ui.notify(message, level);
}

/** Run a command, resolving its stdout, or undefined if it fails or times out. */
function runCmd(cmd: string, args: string[], timeoutMs = 1000): Promise<Buffer | undefined> {
	return new Promise((resolve) => {
		execFile(cmd, args, { timeout: timeoutMs, encoding: "buffer", maxBuffer: 64 * 1024 * 1024 }, (err, stdout) => {
			resolve(err ? undefined : Buffer.from(stdout));
		});
	});
}

function baseMimeType(value: string): string {
	return value.split(";")[0]?.trim().toLowerCase() ?? value.toLowerCase();
}

/** Sniff the real image type from magic bytes; null when unsupported. */
function detectImageMimeType(bytes: Buffer): ImageMimeType | null {
	if (
		bytes.length >= 8 &&
		bytes.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))
	)
		return "image/png";
	if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return "image/jpeg";
	if (bytes.length >= 6) {
		const head = bytes.subarray(0, 6).toString("latin1");
		if (head === "GIF87a" || head === "GIF89a") return "image/gif";
	}
	if (bytes.length >= 12 && bytes.subarray(0, 4).toString("latin1") === "RIFF" && bytes.subarray(8, 12).toString("latin1") === "WEBP")
		return "image/webp";
	return null;
}

function pickImageType(types: string[]): string | null {
	for (const preferred of IMAGE_MIME_TYPES) {
		if (types.some((t) => baseMimeType(t) === preferred)) return preferred;
	}
	return types.find((t) => baseMimeType(t).startsWith("image/")) ?? null;
}

async function readClipboardImage(): Promise<ClipboardImage | null> {
	// Wayland
	if (process.env.WAYLAND_DISPLAY || process.env.XDG_SESSION_TYPE === "wayland") {
		const list = await runCmd("wl-paste", ["--list-types"]);
		if (list) {
			const types = list.toString("utf8").split(/\r?\n/).map((t) => t.trim()).filter(Boolean);
			const type = pickImageType(types);
			if (type) {
				const data = await runCmd("wl-paste", ["--type", type, "--no-newline"]);
				const mime = data ? detectImageMimeType(data) : null;
				if (data?.length && mime) return { bytes: data, mimeType: mime };
			}
			if (list) return null; // wl-paste answered: clipboard has no (supported) image
		}
	}
	// X11
	if (process.env.DISPLAY) {
		const targets = await runCmd("xclip", ["-selection", "clipboard", "-t", "TARGETS", "-out"]);
		if (targets) {
			const types = targets.toString("utf8").split(/\r?\n/).map((t) => t.trim()).filter(Boolean);
			const type = pickImageType(types);
			if (type) {
				const data = await runCmd("xclip", ["-selection", "clipboard", "-t", type, "-out"]);
				const mime = data ? detectImageMimeType(data) : null;
				if (data?.length && mime) return { bytes: data, mimeType: mime };
			}
			return null; // xclip answered: clipboard has no (supported) image
		}
	}
	return null;
}

/** Paths of files copied in a file manager (uri-list / gnome-copied-files). */
async function readClipboardFilePaths(): Promise<string[] | null> {
	let raw: Buffer | undefined;
	if (process.env.WAYLAND_DISPLAY) {
		raw =
			(await runCmd("wl-paste", ["--type", "x-special/gnome-copied-files"])) ??
			(await runCmd("wl-paste", ["--type", "text/uri-list"]));
	}
	if (!raw && process.env.DISPLAY) {
		raw =
			(await runCmd("xclip", ["-selection", "clipboard", "-t", "x-special/gnome-copied-files", "-out"])) ??
			(await runCmd("xclip", ["-selection", "clipboard", "-t", "text/uri-list", "-out"]));
	}
	if (!raw) return null;
	const paths: string[] = [];
	for (const line of raw.toString("utf8").split(/[\r\n]+/)) {
		const value = line.trim();
		if (!value || /^(copy|cut)$/i.test(value)) continue;
		if (value.startsWith("file://")) {
			try {
				paths.push(decodeURIComponent(new URL(value).pathname));
			} catch {
				// Ignore malformed URIs.
			}
		}
	}
	return paths.length ? paths : null;
}

async function readClipboardText(): Promise<string | null> {
	let raw: Buffer | undefined;
	if (process.env.WAYLAND_DISPLAY) raw = await runCmd("wl-paste", ["--no-newline", "--type", "text"], 5000);
	if (!raw && process.env.DISPLAY) {
		raw =
			(await runCmd("xclip", ["-selection", "clipboard", "-out"], 5000)) ??
			(await runCmd("xsel", ["--clipboard", "--output"], 5000));
	}
	const text = raw?.toString("utf8") ?? "";
	return text || null;
}

/**
 * Spans of `[pasted image n]` markers present in the text. A marker only
 * merges while its text is intact: hand-editing it degrades it to normal
 * characters, like a built-in paste marker whose id is no longer valid.
 */
function imageMarkerSpans(text: string): Array<{ start: number; end: number }> {
	const spans: Array<{ start: number; end: number }> = [];
	for (const id of imagePastes.keys()) {
		const marker = `[pasted image ${id}]`;
		let start = text.indexOf(marker);
		while (start !== -1) {
			spans.push({ start, end: start + marker.length });
			start = text.indexOf(marker, start + marker.length);
		}
	}
	spans.sort((a, b) => a.start - b.start);
	return spans;
}

class PasteImageEditor extends CustomEditor {
	onPasteImage = () => {
		void this.handlePaste();
	};

	private busy = false;

	private async handlePaste() {
		if (this.busy) return;
		this.busy = true;
		try {
			const image = await readClipboardImage();
			if (image) {
				this.insertImage(image);
				return;
			}
			const filePaths = await readClipboardFilePaths();
			if (filePaths) {
				this.insertTextAtCursor(filePaths.join("\n"));
				this.tui.requestRender();
				return;
			}
			const text = await readClipboardText();
			if (text) {
				this.insertTextAtCursor(text);
				this.tui.requestRender();
			}
		} catch (error) {
			notify(`Clipboard paste failed: ${error instanceof Error ? error.message : String(error)}`, "error");
		} finally {
			this.busy = false;
		}
	}

	private insertImage(image: ClipboardImage) {
		pasteCounter += 1;
		const fileName = `pasted-image-${pasteCounter}.${EXTENSIONS[image.mimeType]}`;
		fs.mkdirSync(PASTE_DIR, { recursive: true, mode: 0o700 });
		const filePath = path.join(PASTE_DIR, fileName);
		fs.writeFileSync(filePath, image.bytes);
		imagePastes.set(pasteCounter, filePath);
		this.insertTextAtCursor(`[pasted image ${pasteCounter}]`);
		this.tui.requestRender();
		notify(`Pasted image saved to ${filePath}`);
	}

	/**
	 * Merge `[pasted image n]` markers into single atomic segments so cursor
	 * movement, deletion, and wrapping treat them as one unit, like the
	 * built-in `[paste #n]` markers (see pi-tui Editor.segment).
	 */
	segment(text: string, mode: "grapheme" | "word"): Iterable<{ segment: string; index: number; input: string }> {
		const base = super.segment(text, mode);
		if (!text.includes("[pasted image ")) return base;
		const spans = imageMarkerSpans(text);
		if (spans.length === 0) return base;
		const result: Array<{ segment: string; index: number; input: string }> = [];
		let spanIdx = 0;
		for (const seg of base) {
			while (spanIdx < spans.length && spans[spanIdx].end <= seg.index) spanIdx++;
			const span = spanIdx < spans.length ? spans[spanIdx] : undefined;
			if (span && seg.index >= span.start) {
				// Emit one merged segment for the first grapheme of the marker,
				// skip the rest.
				if (seg.index === span.start) {
					result.push({ segment: text.slice(span.start, span.end), index: span.start, input: text });
				}
			} else {
				result.push(seg);
			}
		}
		return result;
	}

	/** Expand `[pasted image n]` markers to their file path on submit. */
	expandPasteMarkers(text: string): string {
		let result = super.expandPasteMarkers(text);
		for (const [id, filePath] of imagePastes) {
			result = result.replaceAll(`[pasted image ${id}]`, filePath);
		}
		return result;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ui = ctx.ui;
		if (ctx.mode === "tui") {
			ctx.ui.setEditorComponent((_tui, theme, keybindings) => new PasteImageEditor(_tui, theme, keybindings));
		}
	});

	pi.on("session_shutdown", () => {
		ui = undefined;
	});
}