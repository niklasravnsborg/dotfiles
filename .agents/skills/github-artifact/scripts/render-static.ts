// Usage: bun render-static.ts <page.html> <out.html>
//
// Runs the page's inline scripts once in linkedom and writes the DOM without
// them. Layout reads like clientWidth return 0, and events never fire.
import { parseHTML } from "linkedom@0.18.12";

const [input, output] = Bun.argv.slice(2);
if (!input || !output) {
  console.error("Usage: bun render-static.ts <page.html> <out.html>");
  process.exit(1);
}

let source = await Bun.file(input).text();
// linkedom drops fragments without <html>; browsers accept styles in the body.
if (!/<html[\s>]/i.test(source)) {
  source = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body>${source}</body></html>`;
}
const { window, document } = parseHTML(source);

// linkedom parses <circle/> as an open tag and nests the rest of an SVG
// inside it, so expand self-closing tags that aren't void elements.
const innerHTML = Object.getOwnPropertyDescriptor(
  window.Element.prototype,
  "innerHTML",
)!;
Object.defineProperty(window.Element.prototype, "innerHTML", {
  get: innerHTML.get,
  set(this: Element, html: string) {
    innerHTML.set!.call(
      this,
      String(html).replace(
        /<([a-zA-Z][\w-]*)([^<>]*?)\s*\/>/g,
        (tag, name: string, attrs: string) =>
          /^(br|hr|img|input|meta|link)$/i.test(name)
            ? tag
            : `<${name}${attrs}></${name}>`,
      ),
    );
  },
});
Object.defineProperty(window.HTMLElement.prototype, "clientWidth", {
  get: () => 0,
});
Object.assign(globalThis, {
  window,
  document,
  ResizeObserver: class {
    observe() {}
  },
});

for (const script of document.querySelectorAll("script")) {
  new Function(script.textContent ?? "")();
  script.remove();
}
await Bun.write(
  output,
  `<!doctype html>\n${document.documentElement.outerHTML}`,
);
