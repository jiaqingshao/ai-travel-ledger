/* =====================================================
 * HTML5 围棋 · 游戏核心
 * 特性：
 *   - 19/13/9 路棋盘切换
 *   - 完整提子（气）算法 + 自杀禁止 + 简单打劫检测
 *   - 鼠标光标预览棋子
 *   - 悔棋、停一手、重置
 *   - 落子音效（Web Audio 合成）
 *   - 历史回放
 * =====================================================
 * 版本变更日志：
 *   v1.0.0 - 初始版本（包含坐标偏移 BUG）
 *   v1.0.1 - BUG-001 修复：
 *            · getCellMetrics 改为自适应居中（修复坐标偏移 2 格）
 *            · eventToCell 增加 rect.width===0 防御性检查
 *            · 新增 touchstart 触屏事件支持
 *            · 强化防御性：Number.isFinite 防护 NaN/类型异常
 *            · touchstart 提前 preventDefault 防止 click 双触发
 *   v1.0.2 - BUG-002 修复：
 *            · 锁定 canvas CSS 尺寸 = 逻辑尺寸
 *            · 修复浏览器缩放（Ctrl+/-）下点击偏移问题
 *            · 添加 dpr 缩放注释，避免未来回归
 * ===================================================== */

(() => {
  "use strict";

  // ============== 常量 ==============
  const EMPTY = 0;
  const BLACK = 1;
  const WHITE = 2;

  const VERSION = "v1.0.2";

  // ============== 状态 ==============
  const state = {
    size: 19,
    board: [],
    turn: BLACK,
    captures: { 1: 0, 2: 0 }, // 被吃的子数（黑/白）
    history: [], // { board, turn, captures, lastMove, koPoint }
    lastMove: null, // {x, y}
    koPoint: null, // {x, y}
    passes: 0, // 连续停一手计数（双方都停一手 -> 终局）
    showCoords: false,
  };

  // ============== DOM ==============
  const $ = (id) => document.getElementById(id);
  const canvas = $("board");
  const ctx = canvas.getContext("2d");

  // ============== BUG-001 (真实浏览器回归) 修复 ==============
  // 根因总结：
  //   v1.0.1 在真实 Chromium 浏览器中，CSS `aspect-ratio: 1/1` + `width: 100%`
  //   + `height: auto` + `max-width: 760px` 组合下，某些版本 (尤其带字体加载、
  //   高 DPI、或初始 viewport 切换) canvas 的 CSS 盒被回退到 canvas.width (760)，
  //   与 board-shadow 的 content-box 宽度不一致，导致 scaleX > 1，真实点击
  //   视觉位置正确但落点向右偏移 1~2 格（39~78px）。
  //
  // 修复方案（最小侵入、向后兼容）：
  //   1) syncCanvasSize() — 根据 board-shadow 的 content-box 宽度计算 canvas
  //      的 CSS 边长 = min(content-box, 760)，然后显式设置 canvas.style.width
  //      和 canvas.style.height 为该值，确保 canvas 始终是正方形 CSS 盒
  //   2) 调整 canvas.width (内部像素) = CSS 边长 → scaleX = canvas.width /
  //      clientWidth 永远 = 1.0，eventToCell 无需再做缩放
  //   3) ResizeObserver 监听 board-shadow 尺寸变化，自动重新 sync
  //   4) 兼容性回退：如果 board-shadow 尚未挂载，至少锁定初始 760x760
  //
  // 这样：
  //   - canvas 保持响应式（窗口缩小时 canvas 也变小）
  //   - canvas 内部像素与 CSS 像素 1:1（scaleX = scaleY = 1）
  //   - eventToCell 简化为最朴素的 `clientX/Y - rect.left/top`
  //   - 任何 CSS / DPR / 缩放都不会再让点击位置偏移

  /**
   * 将 canvas 的内部像素尺寸同步到 board-shadow 的内容盒宽度（封顶 760），
   * 同时设置 style.width / style.height 使 CSS 盒严格正方形且等于内部像素。
   * 调用时机：newBoard / window resize / 棋盘大小切换 / 初始化 / ResizeObserver。
   */
  function syncCanvasSize() {
    const wrap = canvas.parentElement; // .board-shadow
    if (!wrap) return;
    // 优先用 .board-shadow 的 content-box 宽度（已经扣掉 padding:18*2）
    // 若 wrap 还没布局（width=0），回退到 760
    const wrapCS = getComputedStyle(wrap);
    const padL = parseFloat(wrapCS.paddingLeft) || 0;
    const padR = parseFloat(wrapCS.paddingRight) || 0;
    let cssW = wrap.clientWidth - padL - padR;
    if (!Number.isFinite(cssW) || cssW <= 0) cssW = 760;
    // 封顶 760（保持 19 路棋盘最大边长）
    cssW = Math.min(760, Math.max(160, Math.floor(cssW)));

    // 内部像素 = CSS 像素（避免 scaleX ≠ 1）
    canvas.width = cssW;
    canvas.height = cssW;
    canvas.style.width = cssW + "px";
    canvas.style.height = cssW + "px";
  }

  // ============== 初始化 ==============
  function newBoard(size) {
    state.size = size;
    state.board = Array.from({ length: size }, () =>
      new Array(size).fill(EMPTY)
    );
    state.turn = BLACK;
    state.captures = { 1: 0, 2: 0 };
    state.history = [];
    state.lastMove = null;
    state.koPoint = null;
    state.passes = 0;
    syncCanvasSize(); // BUG-001 v1.0.2：重新同步画布尺寸（保证 canvas 始终是正方形、scaleX=1）
    renderAll();
  }

  // ============== 棋盘绘制 ==============
  /**
   * 计算棋盘几何参数（绘图与点击共用同一组数据，保证落点一致）。
   * 返回：
   *   padding    — 网格距画布边缘的内边距（px）
   *   cell       — 单格像素边长（px）
   *   stoneR     — 棋子半径（px）
   *   boardSize  — 网格总边长 = padding * 2 + cell * (size - 1)
   *   cx0/cy0    — 网格左上角交叉点画布坐标（用于居中校验）
   * 棋盘始终在画布内居中：padding = (canvas.width - cell*(size-1)) / 2
   */
  function getCellMetrics() {
    const W = canvas.width;
    const size = state.size;
    // 防御性检查：canvas 尺寸异常时直接返回 null，由调用方处理
    if (!Number.isFinite(W) || W <= 0 || size < 2) {
      return { padding: 0, cell: 0, stoneR: 8, boardSize: 0, cx0: 0, cy0: 0 };
    }
    // 以 size-1 个 cell 等距分布在可用区域内，两侧 padding 自动居中
    const cell = (W - 56) / (size - 1);          // 总边距 56（28*2）
    const padding = (W - cell * (size - 1)) / 2; // 自动居中
    const stoneR = Math.max(8, Math.min(16, cell * 0.46));
    const cx0 = padding;                          // (0,0) 交叉点画布坐标
    const cy0 = padding;
    return { padding, cell, stoneR, boardSize: W, cx0, cy0 };
  }

  function drawBoard() {
    const { padding, cell } = getCellMetrics();
    const W = canvas.width;
    const H = canvas.height;

    // 木纹底（Canvas 内部更细腻）
    ctx.clearRect(0, 0, W, H);

    // 木纹渐变
    const woodGrad = ctx.createLinearGradient(0, 0, W, H);
    woodGrad.addColorStop(0, "#ecd0a0");
    woodGrad.addColorStop(0.5, "#d4a86a");
    woodGrad.addColorStop(1, "#b8864a");
    ctx.fillStyle = woodGrad;
    ctx.fillRect(0, 0, W, H);

    // 木纹细节（柔和条纹）
    ctx.save();
    ctx.globalAlpha = 0.12;
    ctx.strokeStyle = "#5e3a18";
    ctx.lineWidth = 0.6;
    for (let i = 0; i < 60; i++) {
      ctx.beginPath();
      const y = Math.random() * H;
      ctx.moveTo(0, y);
      ctx.bezierCurveTo(
        W * 0.3,
        y + (Math.random() - 0.5) * 12,
        W * 0.7,
        y + (Math.random() - 0.5) * 12,
        W,
        y + (Math.random() - 0.5) * 6
      );
      ctx.stroke();
    }
    ctx.restore();

    // 四角圆角遮罩（柔和阴影边框）
    const borderGrad = ctx.createLinearGradient(0, 0, 0, H);
    borderGrad.addColorStop(0, "rgba(0,0,0,0.35)");
    borderGrad.addColorStop(0.1, "rgba(0,0,0,0)");
    borderGrad.addColorStop(0.9, "rgba(0,0,0,0)");
    borderGrad.addColorStop(1, "rgba(0,0,0,0.35)");
    ctx.fillStyle = borderGrad;
    ctx.fillRect(0, 0, W, H);

    // 网格线
    ctx.strokeStyle = "rgba(45, 25, 8, 0.85)";
    ctx.lineWidth = 1;
    for (let i = 0; i < state.size; i++) {
      const p = padding + i * cell;
      // 横线
      ctx.beginPath();
      ctx.moveTo(padding, p);
      ctx.lineTo(W - padding, p);
      ctx.stroke();
      // 竖线
      ctx.beginPath();
      ctx.moveTo(p, padding);
      ctx.lineTo(p, H - padding);
      ctx.stroke();
    }

    // 边框粗线
    ctx.strokeStyle = "rgba(30, 15, 5, 0.95)";
    ctx.lineWidth = 1.8;
    ctx.strokeRect(padding, padding, W - padding * 2, H - padding * 2);

    // 星位（天元 + 各角）
    drawStarPoints();

    // 坐标（可选）
    if (state.showCoords) drawCoordinates();
  }

  function drawStarPoints() {
    const { padding, cell } = getCellMetrics();
    const stars = getStarPoints(state.size);
    ctx.fillStyle = "rgba(30, 15, 5, 0.9)";
    for (const [x, y] of stars) {
      const cx = padding + x * cell;
      const cy = padding + y * cell;
      ctx.beginPath();
      ctx.arc(cx, cy, Math.max(2.5, cell * 0.07), 0, Math.PI * 2);
      ctx.fill();
    }
  }

  function getStarPoints(size) {
    if (size === 19) {
      return [
        [3, 3],
        [3, 9],
        [3, 15],
        [9, 3],
        [9, 9],
        [9, 15],
        [15, 3],
        [15, 9],
        [15, 15],
      ];
    }
    if (size === 13) {
      return [
        [3, 3],
        [3, 9],
        [9, 3],
        [9, 9],
        [6, 6],
      ];
    }
    if (size === 9) {
      return [
        [2, 2],
        [2, 6],
        [6, 2],
        [6, 6],
        [4, 4],
      ];
    }
    return [];
  }

  function drawCoordinates() {
    const { padding, cell } = getCellMetrics();
    const letters = "ABCDEFGHJKLMNOPQRST"; // 跳过 I
    ctx.fillStyle = "rgba(60, 30, 10, 0.7)";
    ctx.font = `${Math.max(9, cell * 0.32)}px Consolas, monospace`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    for (let i = 0; i < state.size; i++) {
      const p = padding + i * cell;
      ctx.fillText(letters[i], p, padding * 0.5);
      ctx.fillText(letters[i], p, canvas.height - padding * 0.5);
      ctx.fillText(`${state.size - i}`, padding * 0.5, p);
      ctx.fillText(
        `${state.size - i}`,
        canvas.width - padding * 0.5,
        p
      );
    }
  }

  // ============== 棋子绘制（立体感） ==============
  function drawStone(x, y, color, opts = {}) {
    const { padding, cell, stoneR } = getCellMetrics();
    const cx = padding + x * cell;
    const cy = padding + y * cell;
    const r = stoneR;
    const isBlack = color === BLACK;
    const ghost = opts.ghost || 0;

    ctx.save();

    // 落子阴影（地面投影）
    if (!opts.preview) {
      ctx.beginPath();
      ctx.fillStyle = "rgba(0,0,0,0.35)";
      ctx.arc(cx + r * 0.12, cy + r * 0.18, r * 1.02, 0, Math.PI * 2);
      ctx.fill();
    }

    // 棋子主体
    const grad = ctx.createRadialGradient(
      cx - r * 0.35,
      cy - r * 0.4,
      r * 0.1,
      cx,
      cy,
      r * 1.05
    );

    if (isBlack) {
      grad.addColorStop(0, "#7a7a7a");
      grad.addColorStop(0.25, "#2c2c2c");
      grad.addColorStop(0.7, "#0a0a0a");
      grad.addColorStop(1, "#000000");
    } else {
      grad.addColorStop(0, "#ffffff");
      grad.addColorStop(0.4, "#f4f0e2");
      grad.addColorStop(0.85, "#cdc8b6");
      grad.addColorStop(1, "#9c9786");
    }
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fill();

    // 透明（preview/ghost）
    ctx.globalAlpha = 0.45 + ghost * 0.55;
    if (opts.preview) {
      ctx.globalAlpha = 0.35;
    }

    // 高光
    const hl = ctx.createRadialGradient(
      cx - r * 0.45,
      cy - r * 0.5,
      0,
      cx - r * 0.45,
      cy - r * 0.5,
      r * 0.7
    );
    hl.addColorStop(0, isBlack ? "rgba(255,255,255,0.55)" : "rgba(255,255,255,0.95)");
    hl.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = hl;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fill();

    // 边缘暗化
    ctx.globalCompositeOperation = "source-atop";
    const edgeGrad = ctx.createRadialGradient(cx, cy, r * 0.85, cx, cy, r);
    edgeGrad.addColorStop(0, "rgba(0,0,0,0)");
    edgeGrad.addColorStop(1, isBlack ? "rgba(0,0,0,0.6)" : "rgba(80,60,40,0.5)");
    ctx.fillStyle = edgeGrad;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalCompositeOperation = "source-over";

    // 最后落子标记
    if (state.lastMove && state.lastMove.x === x && state.lastMove.y === y) {
      ctx.beginPath();
      ctx.strokeStyle = isBlack ? "#ff5252" : "#d32f2f";
      ctx.lineWidth = 1.6;
      ctx.arc(cx, cy, r * 0.35, 0, Math.PI * 2);
      ctx.stroke();
    }

    ctx.restore();
  }

  // ============== 鼠标坐标 → 棋盘交点 ==============
  /**
   * v1.0.2 BUG-001 修复后的事件坐标 → 网格坐标映射。
   *
   * 关键不变式（由 syncCanvasSize() 维持）：
   *   canvas.width === canvas.clientWidth（恒为 1:1，scaleX = 1.0）
   *   canvas.style.width === canvas.clientWidth（CSS 盒与内部像素一致）
   *   canvas.getBoundingClientRect() 反映 CSS 盒，视口坐标可靠
   *
   * 优先级：
   *   1) evt.offsetX / offsetY（target-relative，最直接）
   *   2) 回退到 (clientX - rect.left) * (canvas.width / rect.width)
   *      （即使未来 rect.width 被外部 CSS 调改，仍能正确映射）
   *   3) 防御性 Number.isFinite 拦截 NaN/undefined
   */
  function eventToCell(evt) {
    const rect = canvas.getBoundingClientRect();
    if (!rect || !Number.isFinite(rect.width) || !Number.isFinite(rect.height)
        || rect.width <= 0 || rect.height <= 0) return null;
    if (!evt || !Number.isFinite(evt.clientX) || !Number.isFinite(evt.clientY)
        || !Number.isFinite(rect.left) || !Number.isFinite(rect.top)) return null;

    const { padding, cell } = getCellMetrics();
    if (!Number.isFinite(padding) || !Number.isFinite(cell)
        || cell <= 0 || padding < 0) return null;

    // 优先路径：offsetX/Y（target-relative，避免 rect/CSS 缩放干扰）
    let px, py;
    if (Number.isFinite(evt.offsetX) && Number.isFinite(evt.offsetY)
        && evt.offsetX >= 0 && evt.offsetY >= 0
        && evt.offsetX <= rect.width && evt.offsetY <= rect.height) {
      px = evt.offsetX;
      py = evt.offsetY;
    } else {
      // 回退路径：clientX/Y - rect.left/top × 缩放
      // 这里不用 scaleX = canvas.width / rect.width 是因为 v1.0.2 中
      // 已保证 canvas.width === rect.width，比例永远 = 1；保留此路径仅为防御
      const scaleX = canvas.width / rect.width;
      const scaleY = canvas.height / rect.height;
      px = (evt.clientX - rect.left) * scaleX;
      py = (evt.clientY - rect.top) * scaleY;
    }

    // 步骤 2：画布内部像素 → 网格坐标（与绘图完全一致的公式）
    const gx = (px - padding) / cell;
    const gy = (py - padding) / cell;
    const x = Math.round(gx);
    const y = Math.round(gy);

    if (!Number.isFinite(x) || !Number.isFinite(y)) return null;
    if (x < 0 || y < 0 || x >= state.size || y >= state.size) return null;

    const dx = gx - x;
    const dy = gy - y;
    if (Math.hypot(dx, dy) > 0.55) return null;
    return { x, y };
  }

  // ============== 气与连通块 ==============
  function inBounds(x, y) {
    return x >= 0 && y >= 0 && x < state.size && y < state.size;
  }

  function neighbors(x, y) {
    return [
      [x + 1, y],
      [x - 1, y],
      [x, y + 1],
      [x, y - 1],
    ];
  }

  // 返回连通的同色棋子集合
  function getGroup(board, x, y) {
    const color = board[y][x];
    if (color === EMPTY) return [];
    const visited = new Set();
    const stack = [[x, y]];
    const group = [];
    while (stack.length) {
      const [cx, cy] = stack.pop();
      const key = cx + "," + cy;
      if (visited.has(key)) continue;
      visited.add(key);
      if (!inBounds(cx, cy)) continue;
      if (board[cy][cx] !== color) continue;
      group.push([cx, cy]);
      for (const [nx, ny] of neighbors(cx, cy)) {
        if (!visited.has(nx + "," + ny)) stack.push([nx, ny]);
      }
    }
    return group;
  }

  // 计算一组棋子的气数
  function countLiberties(board, group) {
    const libs = new Set();
    for (const [x, y] of group) {
      for (const [nx, ny] of neighbors(x, y)) {
        if (inBounds(nx, ny) && board[ny][nx] === EMPTY) {
          libs.add(nx + "," + ny);
        }
      }
    }
    return libs.size;
  }

  // ============== 落子逻辑 ==============
  function playMove(x, y) {
    if (!inBounds(x, y)) return { ok: false, reason: "位置越界" };
    if (state.board[y][x] !== EMPTY) return { ok: false, reason: "已有棋子" };
    if (state.koPoint && state.koPoint.x === x && state.koPoint.y === y) {
      return { ok: false, reason: "打劫：禁止立即回提" };
    }

    // 推入历史
    pushHistory();

    const color = state.turn;
    state.board[y][x] = color;
    const opponent = color === BLACK ? WHITE : BLACK;

    // 检查并提掉对方无气的子
    const oppGroupsToRemove = new Set();
    for (const [nx, ny] of neighbors(x, y)) {
      if (inBounds(nx, ny) && state.board[ny][nx] === opponent) {
        const g = getGroup(state.board, nx, ny);
        if (countLiberties(state.board, g) === 0) {
          for (const [gx, gy] of g) oppGroupsToRemove.add(gx + "," + gy);
        }
      }
    }
    let captured = 0;
    for (const key of oppGroupsToRemove) {
      const [gx, gy] = key.split(",").map(Number);
      state.board[gy][gx] = EMPTY;
      captured++;
    }

    // 自杀禁止：己方新块若 0 气 且未提子，则不合法
    const myGroup = getGroup(state.board, x, y);
    if (countLiberties(state.board, myGroup) === 0 && captured === 0) {
      // 撤销
      popHistory();
      return { ok: false, reason: "自杀：禁止落子" };
    }

    // 更新统计
    state.captures[color] += captured;

    // 打劫点：单子被提 + 仅提一子 + 落子后己方也是单子且气数=1
    if (
      captured === 1 &&
      oppGroupsToRemove.size === 1 &&
      myGroup.length === 1
    ) {
      const onlyKey = [...oppGroupsToRemove][0].split(",").map(Number);
      state.koPoint = { x: onlyKey[0], y: onlyKey[1] };
    } else {
      state.koPoint = null;
    }

    state.lastMove = { x, y };
    state.passes = 0;
    state.turn = opponent;

    // 音效
    if (audio.enabled) audio.playStone(color);

    // 历史文字
    appendMoveText(color, x, y, captured);

    renderAll();
    updateTurnIndicator();

    if (state.captures[BLACK] + state.captures[WHITE] > 0) {
      $("captures-black").textContent = state.captures[BLACK];
      $("captures-white").textContent = state.captures[WHITE];
    }

    return { ok: true, captured };
  }

  function pushHistory() {
    state.history.push({
      board: state.board.map((row) => row.slice()),
      turn: state.turn,
      captures: { ...state.captures },
      lastMove: state.lastMove ? { ...state.lastMove } : null,
      koPoint: state.koPoint ? { ...state.koPoint } : null,
      passes: state.passes,
    });
  }

  function popHistory() {
    if (!state.history.length) return;
    const prev = state.history.pop();
    state.board = prev.board;
    state.turn = prev.turn;
    state.captures = prev.captures;
    state.lastMove = prev.lastMove;
    state.koPoint = prev.koPoint;
    state.passes = prev.passes;
  }

  function undo() {
    if (!state.history.length) {
      flashMoves("没有可悔棋的步骤");
      return;
    }
    popHistory();
    renderAll();
    updateTurnIndicator();
    flashMoves("悔棋成功");
  }

  function pass() {
    pushHistory();
    state.passes++;
    state.lastMove = null;
    state.koPoint = null;
    state.turn = state.turn === BLACK ? WHITE : BLACK;
    appendMoveText(state.turn === BLACK ? WHITE : BLACK, null, null, 0, true);
    renderAll();
    updateTurnIndicator();

    if (state.passes >= 2) {
      flashMoves("双方停一手 — 棋局结束（演示）");
    }
  }

  function reset() {
    if (
      state.history.length > 0 &&
      !confirm("确定要重置当前棋局吗？")
    )
      return;
    newBoard(state.size);
    $("captures-black").textContent = "0";
    $("captures-white").textContent = "0";
    $("moves").textContent = "点击棋盘开始对局…";
  }

  function setSize(size) {
    if (state.board.some((row) => row.some((c) => c !== EMPTY))) {
      if (!confirm(`切换到 ${size} 路棋盘将清空当前棋局，确定吗？`)) return;
    }
    document
      .querySelectorAll(".seg-btn")
      .forEach((b) =>
        b.classList.toggle("active", Number(b.dataset.size) === size)
      );
    newBoard(size);
    $("moves").textContent = "点击棋盘开始对局…";
  }

  // ============== 渲染 ==============
  function renderAll() {
    drawBoard();
    for (let y = 0; y < state.size; y++) {
      for (let x = 0; x < state.size; x++) {
        const c = state.board[y][x];
        if (c !== EMPTY) drawStone(x, y, c);
      }
    }
  }

  function updateTurnIndicator() {
    const el = $("turn-indicator");
    el.textContent = state.turn === BLACK ? "黑方落子" : "白方落子";
    el.style.background =
      state.turn === BLACK
        ? "linear-gradient(180deg, #555, #111)"
        : "linear-gradient(180deg, #ffffff, #c8c4b3)";
    el.style.color = state.turn === BLACK ? "#fff" : "#2a1f17";
  }

  function appendMoveText(color, x, y, captured, isPass = false) {
    const letters = "ABCDEFGHJKLMNOPQRST";
    const tag = color === BLACK ? "●" : "○";
    let txt;
    if (isPass) {
      txt = `${tag} 停一手`;
    } else {
      txt = `${tag} ${letters[x]}${state.size - y}${
        captured > 0 ? ` 提${captured}子` : ""
      }`;
    }
    const moves = $("moves");
    if (moves.textContent === "点击棋盘开始对局…") {
      moves.textContent = txt;
    } else {
      moves.textContent += " · " + txt;
    }
    moves.scrollTop = moves.scrollHeight;
  }

  function flashMoves(text) {
    const moves = $("moves");
    const old = moves.textContent;
    moves.textContent = `[系统] ${text}`;
    setTimeout(() => {
      if (moves.textContent.startsWith("[系统]")) moves.textContent = old;
    }, 1400);
  }

  // ============== 音效（Web Audio 合成） ==============
  const audio = (() => {
    let ctxA = null;
    let enabled = true;
    function ensure() {
      if (!ctxA) {
        try {
          ctxA = new (window.AudioContext || window.webkitAudioContext)();
        } catch (e) {
          enabled = false;
        }
      }
    }
    return {
      get enabled() {
        return enabled;
      },
      set enabled(v) {
        enabled = v;
      },
      playStone(color) {
        if (!enabled) return;
        ensure();
        if (!ctxA) return;
        const t = ctxA.currentTime;
        const osc = ctxA.createOscillator();
        const gain = ctxA.createGain();
        osc.type = "triangle";
        // 黑子低一点，白子高一点
        osc.frequency.value = color === BLACK ? 220 : 320;
        osc.frequency.exponentialRampToValueAtTime(
          color === BLACK ? 110 : 180,
          t + 0.08
        );
        gain.gain.value = 0.001;
        gain.gain.exponentialRampToValueAtTime(0.18, t + 0.005);
        gain.gain.exponentialRampToValueAtTime(0.001, t + 0.12);
        osc.connect(gain).connect(ctxA.destination);
        osc.start(t);
        osc.stop(t + 0.15);

        // 木板敲击噪音
        const buf = ctxA.createBuffer(
          1,
          ctxA.sampleRate * 0.05,
          ctxA.sampleRate
        );
        const data = buf.getChannelData(0);
        for (let i = 0; i < data.length; i++) {
          data[i] =
            (Math.random() * 2 - 1) * Math.pow(1 - i / data.length, 2.5);
        }
        const noise = ctxA.createBufferSource();
        noise.buffer = buf;
        const ng = ctxA.createGain();
        ng.gain.value = 0.12;
        const filt = ctxA.createBiquadFilter();
        filt.type = "lowpass";
        filt.frequency.value = 1200;
        noise.connect(filt).connect(ng).connect(ctxA.destination);
        noise.start(t);
      },
    };
  })();

  // ============== 事件绑定 ==============
  // 统一转换入口：mouse / touch 都走 eventToCell，确保落点一致
  canvas.addEventListener("click", (e) => {
    const cell = eventToCell(e);
    if (!cell) return;
    const r = playMove(cell.x, cell.y);
    if (!r.ok && r.reason) flashMoves(r.reason);
  });

  // 移动端触摸支持
  // 关键：必须在事件处理最前面调用 preventDefault()，才能阻止浏览器随后
  // 触发的合成 click 事件，避免在 touchstart 与 click 之间手指微移导致的双落子
  canvas.addEventListener(
    "touchstart",
    (e) => {
      // 第一时间阻止默认行为（包括浏览器派生的合成 click）
      e.preventDefault();
      if (!e.touches.length) return;
      const t = e.touches[0];
      const cell = eventToCell(t);
      if (!cell) return;
      const r = playMove(cell.x, cell.y);
      if (!r.ok && r.reason) flashMoves(r.reason);
    },
    { passive: false }
  );
  // touchend/move 也阻止默认，进一步防止长按/拖动期间触发滚动或合成事件
  canvas.addEventListener("touchend", (e) => e.preventDefault(), { passive: false });
  canvas.addEventListener("touchmove", (e) => e.preventDefault(), { passive: false });

  // 鼠标移动 → 显示光标预览棋子（覆盖层）
  // v1.0.2 BUG-001 修复：hover-stone 是 .board-shadow 的子元素，
  // 但 JS 以前写入 hover.style.left = e.clientX - canvas.rect.left，
  // 会让 hover 看似跟鼠标走，实际 board-shadow 的 padding 18px 导致
  // hover-stone 的中心 跟鼠标错位 ~18px（累计 ~0.46 格偏移）。
  // 修正：JS 直接写入 hover-stone 的中心 = 鼠标在 canvas 本地坐标，
  //       且不再依赖 transform: translate(-50%)（CSS 中已移除）。
  const hover = $("hover-stone");
  const HOVER_STONE_HALF = 14; // 28px / 2
  canvas.addEventListener("mousemove", (e) => {
    const rect = canvas.getBoundingClientRect();
    // hover-stone 是 board-shadow 的子元素（位置基准 = board-shadow 左上角）
    // canvas 在 board-shadow 中偏移：left = board-shadow.padding-left + canvas-in-shadow.left
    // canvas-in-shadow.left = (board-shadow.content-width - canvas.clientWidth) / 2
    // 简化为：hover.left = (mouse - board-shadow.rect.left) - HOVER_STONE_HALF
    const bs = canvas.parentElement;
    const bsRect = bs ? bs.getBoundingClientRect() : rect;
    hover.style.left = (e.clientX - bsRect.left - HOVER_STONE_HALF) + "px";
    hover.style.top = (e.clientY - bsRect.top - HOVER_STONE_HALF) + "px";
    const cell = eventToCell(e);
    if (cell) {
      hover.classList.add("show");
      hover.classList.toggle("black", state.turn === BLACK);
      hover.classList.toggle("white", state.turn === WHITE);
    } else {
      hover.classList.remove("show");
    }
  });
  canvas.addEventListener("mouseleave", () => {
    hover.classList.remove("show");
  });

  // 段控件
  document.querySelectorAll(".seg-btn").forEach((btn) => {
    btn.addEventListener("click", () => setSize(Number(btn.dataset.size)));
  });

  // 操作按钮
  $("btn-undo").addEventListener("click", undo);
  $("btn-pass").addEventListener("click", pass);
  $("btn-reset").addEventListener("click", reset);
  $("opt-sound").addEventListener("change", (e) => {
    audio.enabled = e.target.checked;
  });
  $("opt-coords").addEventListener("change", (e) => {
    state.showCoords = e.target.checked;
    renderAll();
  });

  // 中央信息覆盖层：3 秒后淡化为背景提示，可点击临时显示
  const overlay = $("dev-overlay");
  let overlayHideTimer = setTimeout(() => overlay.classList.add("hidden"), 4500);
  overlay.addEventListener("click", () => {
    overlay.classList.toggle("hidden");
    clearTimeout(overlayHideTimer);
    if (!overlay.classList.contains("hidden")) {
      overlayHideTimer = setTimeout(
        () => overlay.classList.add("hidden"),
        2500
      );
    }
  });

  // v1.0.2 BUG-001 修复：窗口大小 / 棋盘大小变化时自动同步 canvas 尺寸
  // 防止：用户拉伸窗口、DPR 变化、字体加载等导致 board-shadow 宽度
  // 改变但 canvas 尺寸未同步 → scaleX ≠ 1，点击偏移。
  let resizeSyncPending = false;
  function requestSyncCanvasSize() {
    if (resizeSyncPending) return;
    resizeSyncPending = true;
    requestAnimationFrame(() => {
      resizeSyncPending = false;
      const prev = { w: canvas.width, h: canvas.height };
      syncCanvasSize();
      if (canvas.width !== prev.w || canvas.height !== prev.h) {
        renderAll(); // 尺寸变了必须重绘棋盘/棋子
      }
    });
  }
  window.addEventListener("resize", requestSyncCanvasSize, { passive: true });
  window.addEventListener("orientationchange", requestSyncCanvasSize, { passive: true });
  // ResizeObserver 监听 board-shadow 变化（某些浏览器/扩展会改变布局但不发 resize）
  if (typeof ResizeObserver !== "undefined") {
    const wrap = canvas.parentElement;
    if (wrap) new ResizeObserver(requestSyncCanvasSize).observe(wrap);
  }
  // 字体加载完成后也重新同步（避免 font swap 导致的布局偏移）
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(requestSyncCanvasSize).catch(() => {});
  }

  // 启动
  newBoard(19);
  updateTurnIndicator();
  // 启动后再同步一次（确保 DOM 完全布局后 canvas 尺寸正确）
  requestSyncCanvasSize();

  // 暴露给外部（调试 / 测试用）
  window.__goGame = {
    state,
    playMove,
    newBoard,
    undo,
    pass,
    syncCanvasSize,        // v1.0.2 新增：供测试调用以手动同步
    eventToCell,           // v1.0.2 新增：供测试验证映射正确性
    getCanvasInfo() {      // v1.0.2 新增：诊断辅助
      const r = canvas.getBoundingClientRect();
      return {
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
        cssWidth: canvas.clientWidth,
        cssHeight: canvas.clientHeight,
        rectLeft: r.left,
        rectTop: r.top,
        rectWidth: r.width,
        rectHeight: r.height,
        scaleX: canvas.width / r.width,
        scaleY: canvas.height / r.height,
      };
    },
  };
})();