const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const source = fs.readFileSync(path.join(__dirname, "..", "preview.js"), "utf8");

function element(tagName, text = "x") {
  const classes = new Set();
  const properties = new Map();
  return {
    tagName: tagName.toUpperCase(),
    textContent: text,
    classList: {
      contains: value => classes.has(value),
      toggle: (value, enabled) => enabled ? classes.add(value) : classes.delete(value)
    },
    style: {
      setProperty: (key, value) => properties.set(key, value),
      getPropertyValue: key => properties.get(key) || ""
    },
    matches: selector => ["LINK", "STYLE", "SCRIPT"].includes(tagName.toUpperCase())
  };
}

function run(nodes) {
  const listeners = {};
  const root = { children: nodes };
  const window = { addEventListener: (type, fn) => { listeners[type] = fn; } };
  const document = { readyState: "complete", querySelector: () => root };
  vm.runInNewContext(source, { window, document }, { filename: "preview.js" });
  return { listeners, nodes };
}

function depth(node) { return node.style.getPropertyValue("--rhb-outline-depth"); }
function has(node, name) { return node.classList.contains("rhb-outline-" + name); }

test("heading depth follows each section, including skipped heading levels", () => {
  const nodes = [element("h1"), element("p"), element("pre"), element("h3"), element("p"), element("ul"), element("h2"), element("p")];
  run(nodes);
  assert.deepEqual(nodes.map(depth), ["0", "0", "0", "2", "2", "2", "1", "1"]);
  assert.deepEqual(nodes.map(x => has(x, "heading")), [true, false, false, true, false, false, true, false]);
  assert.deepEqual(nodes.map(x => has(x, "content")), [false, true, true, false, true, true, false, true]);
});

test("content before first heading remains unchanged", () => {
  const nodes = [element("p"), element("ul"), element("h2"), element("blockquote")];
  run(nodes);
  assert.equal(depth(nodes[0]), "");
  assert.equal(has(nodes[1], "content"), false);
  assert.equal(depth(nodes[3]), "1");
});

test("preview refresh recomputes depth without duplicate content wrappers", () => {
  const nodes = [element("h2"), element("p")];
  const state = run(nodes);
  assert.equal(depth(nodes[1]), "1");
  nodes[0].tagName = "H1";
  state.listeners["vscode.markdown.updateContent"]();
  assert.equal(depth(nodes[1]), "0");
});

test("empty source-position sentinel and embedded styles are left alone", () => {
  const nodes = [element("h1"), element("div", ""), element("link")];
  nodes[1].classList.toggle("code-line", true);
  run(nodes);
  assert.equal(has(nodes[1], "content"), false);
  assert.equal(has(nodes[2], "content"), false);
});
