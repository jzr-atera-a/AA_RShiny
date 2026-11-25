// Browser test for the R app's "Save diagram" bars and the Google Drive tab (fake Drive on :8899).
const { chromium } = require('playwright');
const fs = require('fs');
// run from a folder where 'npm install playwright html2canvas@1.4.1 mermaid@10.9.1' was done: NODE_PATH or copy there
const NM = (process.env.NM_DIR || __dirname) + '/node_modules/';
const local = {
  'html2canvas.min.js': NM + 'html2canvas/dist/html2canvas.min.js',
  'mermaid.min.js': NM + 'mermaid/dist/mermaid.min.js',
};
const results = [];
const ok = (name, cond, detail) => { results.push([cond, name]); console.log(`${cond ? 'PASS' : 'FAIL'} ${name}${cond ? '' : '  -> ' + detail}`); };

async function routes(page) {
  await page.route(/^https?:\/\/(?!127\.0\.0\.1)/, (route) => {
    const u = route.request().url();
    for (const [k, f] of Object.entries(local)) if (u.endsWith(k)) return route.fulfill({ path: f, contentType: 'application/javascript' });
    return route.abort();
  });
}
async function status(page, sel, timeout = 45000) {
  await page.waitForFunction((s) => { const t = document.querySelector(s)?.innerText || ''; return /Uploaded|Not uploaded|could not|ready|Choose|nothing|not set up/i.test(t); }, sel, { timeout });
  return page.locator(sel).innerText();
}

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1400, height: 1000 }, acceptDownloads: true });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => console.log('PAGEERROR', e.message));
  await routes(page);

  // ---- harness: plotly, svg, mermaid, iframe
  await page.goto('http://127.0.0.1:3901/', { waitUntil: 'networkidle' });
  await page.waitForSelector('#chart.js-plotly-plot');
  await page.waitForSelector('#merbox svg', { timeout: 20000 });
  for (const [id, what] of [['s1', 'plotly'], ['s2', 'svg'], ['s3', 'mermaid'], ['s4', 'iframe']]) {
    await page.click(`#${id}-to_drive`);
    const t = await status(page, `#${id}-status`);
    ok(`harness ${what}: uploaded to Drive`, /Uploaded \d+ file/.test(t), t);
    fs.writeFileSync(`/home/claude/e2e/${id}_status.txt`, t);
  }
  const dlp = page.waitForEvent('download', { timeout: 45000 });
  await page.click('#s1-to_zip');
  const dl = await dlp;
  await dl.saveAs('/home/claude/e2e/harness_s1.zip');
  ok('harness plotly: zip download', fs.statSync('/home/claude/e2e/harness_s1.zip').size > 1000, dl.suggestedFilename());
  await page.screenshot({ path: '/home/claude/e2e/harness.png', fullPage: true });

  // ---- full app: Strategy Canvases > Business Model Canvas > View Canvas
  await page.goto('http://127.0.0.1:3900/', { waitUntil: 'networkidle' });
  await page.locator('.sidebar-menu a', { hasText: 'Strategy Canvases' }).first().click();
  await page.locator('.sidebar-menu a', { hasText: 'Business Model Canvas' }).first().click();
  await page.locator('a[data-toggle="tab"]', { hasText: 'View Canvas' }).first().click();
  await page.waitForSelector('#bm_canvas_view-save_canvas-to_drive', { state: 'visible' });
  await page.waitForTimeout(800);
  await page.click('#bm_canvas_view-save_canvas-to_drive');
  let t = await status(page, '#bm_canvas_view-save_canvas-status', 60000);
  ok('app BM canvas: uploaded to Drive', /Uploaded \d+ file/.test(t), t);
  ok('app BM canvas: folder = Strategy Canvases/Business Model Canvas/View Canvas/yyyy/yyyy-mm', /BusinessOpsSuite\/Strategy Canvases\/Business Model Canvas\/View Canvas\/\d{4}\/\d{4}-\d{2}/.test(t), t);
  await page.locator('#bm_canvas_view-save_canvas-status').scrollIntoViewIfNeeded();
  await page.screenshot({ path: '/home/claude/e2e/app_bm_canvas.png' });

  // ---- Analytics with no data: clear message, nothing uploaded
  await page.locator('.sidebar-menu a', { hasText: 'Audio Transcription' }).first().click();
  await page.locator('.sidebar-menu a', { hasText: 'Analysis' }).first().click();
  await page.locator('a[data-toggle="tab"][data-value="analytics"]').first().click();
  await page.waitForSelector('#analytics-save_word-to_drive', { state: 'visible' });
  await page.click('#analytics-save_word-to_drive');
  t = await status(page, '#analytics-save_word-status');
  ok('app Analytics without data: "nothing to save" message', /No transcriptions yet/.test(t), t);

  // ---- API Settings > Google Drive
  await page.locator('.sidebar-menu a', { hasText: 'API Settings' }).first().click();
  await page.locator('a[data-toggle="tab"]', { hasText: 'Google Drive' }).first().click();
  await page.waitForSelector('#gdrive_config-test', { state: 'visible' });
  await page.waitForFunction(() => (document.querySelector('#gdrive_config-example')?.innerText || '').length > 10, null, { timeout: 15000 });
  const ex = await page.locator('#gdrive_config-example').innerText();
  ok('Drive tab: example path', /^My Drive\/BusinessOpsSuite\/Audio Transcription\/Analysis\/Analytics Dashboard\/\d{4}\/\d{4}-\d{2}\/analytics_word_count_distribution_\d{8}_\d{6}\.html$/.test(ex), ex);
  await page.click('#gdrive_config-test');
  await page.waitForFunction(() => /Connected|failed|not/.test(document.querySelector('#gdrive_config-status')?.innerText || ''), null, { timeout: 30000 });
  t = await page.locator('#gdrive_config-status').innerText();
  ok('Drive tab: Test connection', /Connected/.test(t), t);
  const info = await page.locator('#gdrive_config-info').innerText();
  ok('Drive tab: account + storage shown', /person@example.com/.test(info) && /GB/.test(info), info);
  await page.click('#gdrive_config-test_upload');
  await page.waitForFunction(() => /Upload works|failed/.test(document.querySelector('#gdrive_config-status')?.innerText || ''), null, { timeout: 30000 });
  ok('Drive tab: Test upload', /Upload works/.test(await page.locator('#gdrive_config-status').innerText()));
  await page.click('#gdrive_config-sign_in');
  await page.waitForSelector('text=ABCD-EFGH', { timeout: 15000 });
  ok('Drive tab: sign-in code shown', true);
  await page.waitForFunction(() => /Signed in as/.test(document.querySelector('#gdrive_config-status')?.innerText || ''), null, { timeout: 40000 });
  ok('Drive tab: device sign-in completes', true);
  const up = await page.locator('#gdrive_config-uploads').innerText();
  ok('Drive tab: uploads of this session listed', /bm_canvas_view_/.test(up), up.slice(0, 200));
  await page.screenshot({ path: '/home/claude/e2e/app_drive_tab.png', fullPage: true });

  await browser.close();
  const f = results.filter((r) => !r[0]).length;
  console.log(`\n${results.length - f} passed, ${f} failed`);
  process.exit(f ? 1 : 0);
})().catch((e) => { console.error('ERROR', e); process.exit(2); });
