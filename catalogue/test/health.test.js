// Smoke test: the server boots and /health answers, even with no MongoDB running.
// Catches syntax errors, missing dependencies and crash-on-start before an image is built.
const { test } = require('node:test');
const assert = require('node:assert');
const { spawn } = require('node:child_process');
const path = require('node:path');

test('GET /health returns 200 with app OK', async (t) => {
  const srv = spawn(process.execPath, [path.join(__dirname, '..', 'server.js')], {
    env: { ...process.env, MONGO_URL: 'mongodb://127.0.0.1:1/catalogue' }, // unreachable on purpose
    stdio: 'ignore',
  });
  t.after(() => srv.kill());

  let res;
  for (let i = 0; i < 30 && !res; i++) {       // wait up to ~15 s for the port to open
    try { res = await fetch('http://127.0.0.1:8080/health'); }
    catch { await new Promise((r) => setTimeout(r, 500)); }
  }
  assert.ok(res, 'server never answered on :8080');
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.app, 'OK');          // adjust to what your grep in Step 1 showed
});
