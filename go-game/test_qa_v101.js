// v1.0.1 额外防御性测试：NaN/异常输入
// 复用 game.js 中的核心逻辑（单独 copy 一份以验证防御性补丁）

function getCellMetrics(W, size) {
  if (!Number.isFinite(W) || W <= 0 || size < 2) {
    return { padding: 0, cell: 0, stoneR: 8 };
  }
  const cell = (W - 56) / (size - 1);
  const padding = (W - cell * (size - 1)) / 2;
  const stoneR = Math.max(8, Math.min(16, cell * 0.46));
  return { padding, cell, stoneR };
}

function eventToCell(evt, rect, W, size) {
  if (!rect || !Number.isFinite(rect.width) || !Number.isFinite(rect.height)
      || rect.width <= 0 || rect.height <= 0) return null;
  if (!evt || !Number.isFinite(evt.clientX) || !Number.isFinite(evt.clientY)
      || !Number.isFinite(rect.left) || !Number.isFinite(rect.top)) return null;
  const { padding, cell } = getCellMetrics(W, size);
  if (!Number.isFinite(padding) || !Number.isFinite(cell)
      || cell <= 0 || padding < 0) return null;
  const scaleX = W / rect.width;
  const scaleY = W / rect.height;
  const px = (evt.clientX - rect.left) * scaleX;
  const py = (evt.clientY - rect.top) * scaleY;
  const gx = (px - padding) / cell;
  const gy = (py - padding) / cell;
  const x = Math.round(gx);
  const y = Math.round(gy);
  if (!Number.isFinite(x) || !Number.isFinite(y)) return null;
  if (x < 0 || y < 0 || x >= size || y >= size) return null;
  const dx = gx - x, dy = gy - y;
  if (Math.hypot(dx, dy) > 0.55) return null;
  return { x, y };
}

let pass = 0, fail = 0;
function check(label, cond, detail) {
  if (cond) { pass++; console.log("  [PASS] " + label); }
  else { fail++; console.log("  [FAIL] " + label + " | " + detail); }
}

console.log("=== v1.0.1 防御性测试（NaN/异常输入） ===");

// NaN 防御
check("clientX=NaN → null", eventToCell({clientX: NaN, clientY: 100}, {width:760,height:760,left:0,top:0}, 760, 19) === null, "");
check("clientY=undefined → null", eventToCell({clientX: 100}, {width:760,height:760,left:0,top:0}, 760, 19) === null, "");
check("rect.left=NaN → null", eventToCell({clientX: 100, clientY: 100}, {width:760,height:760,left:NaN,top:0}, 760, 19) === null, "");
check("rect.width=NaN → null", eventToCell({clientX: 100, clientY: 100}, {width:NaN,height:760,left:0,top:0}, 760, 19) === null, "");
check("canvas.width=0 → null (避免 cell=-3.11 异常)", eventToCell({clientX: 100, clientY: 100}, {width:760,height:760,left:0,top:0}, 0, 19) === null, "");
check("canvas.width=-100 → null", eventToCell({clientX: 100, clientY: 100}, {width:760,height:760,left:0,top:0}, -100, 19) === null, "");
check("rect=null → null", eventToCell({clientX: 100, clientY: 100}, null, 760, 19) === null, "");
check("evt=null → null", eventToCell(null, {width:760,height:760,left:0,top:0}, 760, 19) === null, "");
check("rect.width=-50 → null", eventToCell({clientX: 100, clientY: 100}, {width:-50,height:760,left:0,top:0}, 760, 19) === null, "");
check("size=1 (异常) → null", eventToCell({clientX: 100, clientY: 100}, {width:760,height:760,left:0,top:0}, 760, 1) === null, "");

// 回归：正常输入仍然能命中
// 19路 W=760: cell=39.111, padding=28
// (7,7) -> px = 28 + 7*39.111 = 301.778
// (9,9) -> px = 28 + 9*39.111 = 380.0
check("正常 (301.78,301.78) 19路 → (7,7)", JSON.stringify(eventToCell({clientX:301.78,clientY:301.78},{width:760,height:760,left:0,top:0},760,19)) === JSON.stringify({x:7,y:7}), "");
check("正常 天元 (380,380) → (9,9)", JSON.stringify(eventToCell({clientX:380,clientY:380},{width:760,height:760,left:0,top:0},760,19)) === JSON.stringify({x:9,y:9}), "");

console.log("\n" + "=".repeat(60));
console.log("v1.0.1 防御性测试: " + (fail===0 ? "PASS" : "FAIL") + " | " + pass + "/" + (pass+fail) + " 通过");
console.log("=".repeat(60));
process.exit(fail === 0 ? 0 : 1);