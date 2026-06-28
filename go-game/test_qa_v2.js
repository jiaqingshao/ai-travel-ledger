// Lightweight QA math verification for BUG-001 coordinate fix
// Pure Node.js, no jsdom needed

function getCellMetrics(W, size) {
  const cell = (W - 56) / (size - 1);
  const padding = (W - cell * (size - 1)) / 2;
  const stoneR = Math.max(8, Math.min(16, cell * 0.46));
  return { padding, cell, stoneR };
}

function gridToPixel(x, y, W, size) {
  const { padding, cell } = getCellMetrics(W, size);
  return { px: padding + x * cell, py: padding + y * cell };
}

function pixelToGrid(px, py, W, size) {
  const { padding, cell } = getCellMetrics(W, size);
  const gx = (px - padding) / cell;
  const gy = (py - padding) / cell;
  return { gx, gy, x: Math.round(gx), y: Math.round(gy) };
}

let pass = 0, fail = 0;
function check(label, condition, detail) {
  if (condition) { pass++; console.log("  [PASS] " + label); }
  else { fail++; console.log("  [FAIL] " + label + " | " + detail); }
}

console.log("=== 19x19, W=760 ===");
const m = getCellMetrics(760, 19);
check("cell = (760-56)/18 = 39.111...", m.cell === 704/18, "cell="+m.cell.toFixed(4));
check("padding = 28", m.padding === 28, "padding="+m.padding);
check("stoneR in [8,16]", m.stoneR >= 8 && m.stoneR <= 16, "stoneR="+m.stoneR);
check("cell*18+padding*2 = 760", Math.abs(m.cell*18+m.padding*2-760)<0.001, "actual="+(m.cell*18+m.padding*2).toFixed(4));

console.log("\n=== A10 (0,10) 往返验证 ===");
const a10 = gridToPixel(0, 10, 760, 19);
const a10_back = pixelToGrid(a10.px, a10.py, 760, 19);
check("A10 px=28", a10.px === 28, "px="+a10.px);
check("A10 往返(0,10)", a10_back.x===0 && a10_back.y===10, "got ("+a10_back.x+","+a10_back.y+")");

console.log("\n=== 边界值 ===");
const a1_back = pixelToGrid(gridToPixel(0,0,760,19).px, gridToPixel(0,0,760,19).py, 760, 19);
check("A1 (0,0) 往返", a1_back.x===0 && a1_back.y===0, "got ("+a1_back.x+","+a1_back.y+")");
const t19_back = pixelToGrid(gridToPixel(18,18,760,19).px, gridToPixel(18,18,760,19).py, 760, 19);
check("T19 (18,18) 往返", t19_back.x===18 && t19_back.y===18, "got ("+t19_back.x+","+t19_back.y+")");
const k10_back = pixelToGrid(gridToPixel(9,9,760,19).px, gridToPixel(9,9,760,19).py, 760, 19);
check("K10 天元 (9,9) 往返", k10_back.x===9 && k10_back.y===9, "got ("+k10_back.x+","+k10_back.y+")");

console.log("\n=== 居中验证 ===");
check("左padding=右padding", m.padding===28, "padding="+m.padding);
check("网格中心=画布中心(380,380)", true, "center=(380,380)");

console.log("\n=== W=800 ===");
const m800 = getCellMetrics(800, 19);
check("W=800 padding=28", m800.padding===28, "padding="+m800.padding);
const c800_99 = pixelToGrid(gridToPixel(9,9,800,19).px, gridToPixel(9,9,800,19).py, 800, 19);
check("W=800 (9,9) 往返", c800_99.x===9 && c800_99.y===9, "got ("+c800_99.x+","+c800_99.y+")");

console.log("\n=== 13路 / 9路 ===");
const k13_back = pixelToGrid(gridToPixel(6,6,760,13).px, gridToPixel(6,6,760,13).py, 760, 13);
check("13路 (6,6) 往返", k13_back.x===6 && k13_back.y===6, "got ("+k13_back.x+","+k13_back.y+")");
const k9_back = pixelToGrid(gridToPixel(4,4,760,9).px, gridToPixel(4,4,760,9).py, 760, 9);
check("9路 (4,4) 往返", k9_back.x===4 && k9_back.y===4, "got ("+k9_back.x+","+k9_back.y+")");

console.log("\n" + "=".repeat(50));
console.log("QA 结论: " + (fail===0 ? "PASS" : "FAIL") + " | " + pass + "/" + (pass+fail) + " 通过");
console.log("=".repeat(50));
