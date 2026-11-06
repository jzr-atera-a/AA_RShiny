// tests/browser_cc.js - clicks through T Records C.C in Chromium and fails if a table or chart does not draw.
// Needs the harness running on :8799. Run: node tests/browser_cc.js
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1400, height: 1100 } });
  // two browser messages also raised by the ORIGINAL app with this machine's R packages are ignored (not from this tab)
  const known = [/datepicker is not a function/, /GLOBAL is not defined/];
  const jsErrors = []; p.on('pageerror', e => { if (!known.some(k => k.test(e.message))) jsErrors.push(e.message); });
  let pass = 0, fail = 0; const ok = (c, w) => { if (c) { pass++; console.log('  ok  ', w); } else { fail++; console.log('  FAIL', w); } };
  const idle = async (ms = 1500) => { await p.waitForTimeout(ms); await p.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 60000 }); };
  await p.goto('http://127.0.0.1:8833/', { waitUntil: 'networkidle' }); await idle();
  await p.click('a[data-value="2. Market & Patterns"]'); await idle(500);
  await p.fill('#cc-m_search', 'Brent'); await p.click('#cc-m_find'); await idle(2500);
  ok((await p.locator('#cc-m_facts').innerText()).includes('Brent Crude Oil'), 'market facts shown');
  await p.selectOption('#cc-c_res', 'MINUTE_30').catch(() => {}); await p.click('#cc-c_load'); await idle(5000);
  ok((await p.$$('#cc-c_chart .main-svg')).length > 0, 'chart drawn');
  await idle(2000);   // every pattern alive is ticked and drawn on load
  ok((await p.$$eval('#cc-c_pick input[type=checkbox]:checked', e => e.length)) > 0, 'one ticked checkbox per pattern');
  const shapes = await p.$$eval('#cc-c_chart .shapelayer path', e => e.length); ok(shapes > 3, `patterns drawn on the price (${shapes} shapes)`);
  const labels = await p.$$eval('#cc-c_chart .annotation-text', e => e.map(x => x.textContent)); ok(labels.some(t => /^1\. /.test(t)), `numbered pattern labels (${labels.length} annotations)`);
  ok((await p.$$eval('#cc-c_chart .subplot', e => e.length)) >= 2 || (await p.$$eval('#cc-c_chart .xy2, #cc-c_chart g.y2', e => e.length)) > 0, 'indicator panel drawn under the price');
  await p.locator('#cc-c_chart').screenshot({ path: '/tmp/browser_patterns.png' });
  ok((await p.$$eval('#cc-c_active tbody tr', e => e.length)) > 0, 'active patterns table drawn');
  await p.click('#cc-c_save'); await idle(2000); ok(await p.isVisible('text=Saved as SC_'), 'Save scan confirms');
  await p.click('a[data-value="3. Plan & Order"]'); await idle(1500);
  await p.click('#cc-p_refresh'); await idle(1500); ok(await p.isVisible('text=Read from Capital.com at'), 'Refresh balance shows when it was read');
  await p.fill('#cc-p_size', '2'); await p.click('#cc-p_build'); await idle(3000);
  ok(await p.isVisible('text=market scenarios (deals) worked out'), 'scenarios message (deals)');
  await p.check('#cc-p_show_bad'); await p.waitForTimeout(1500); const rows = await p.$$eval('#cc-p_scen tbody tr', e => e.length); ok(rows >= 2 && !(await p.isVisible('text=BUY LIMIT')), `scenarios table drawn: ${rows} deal rows, no limit / stop orders`);
  await p.screenshot({ path: '/tmp/browser_scen.png', fullPage: false });
  const heads = await p.$$eval('#cc-p_scen thead th', e => e.map(x => x.textContent)); ok(heads.includes('Stop vs now') && heads.includes('Chance target first: measured'), 'scenario table shows distances from the price now and the measured chance');
  ok(await p.isVisible('text=Today\'s Morning Sheet found in BigQuery'), 'Morning Sheet option shown (on by default)');
  await p.click('#cc-p_claude'); await idle(3000);
  const rows2 = await p.$$eval('#cc-p_scen tbody tr', e => e.length); ok(rows2 === rows + 1 && await p.isVisible('text=using today\'s Morning Sheet'), `Claude's trade added to the table (${rows2} rows)`);
  await p.locator('#cc-p_scen').screenshot({ path: '/tmp/browser_scen2.png' });
  const errs = await p.$$eval('.shiny-output-error', e => e.map(x => x.textContent).filter(t => t.trim()));
  ok(errs.length === 0, 'no output errors ' + JSON.stringify(errs.slice(0, 3)));
  ok(jsErrors.length === 0, 'no JavaScript errors ' + JSON.stringify(jsErrors.slice(0, 3)));
  console.log(`\n${pass} passed, ${fail} failed`); await b.close(); process.exit(fail ? 1 : 0);
})();
