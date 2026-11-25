const { chromium } = require('playwright');
// Browser check of the Funding tabs (time zone dropdowns, calendar section); app on :3900, run with playwright installed.
const res = []; const ok = (n, c, d) => { res.push(c); console.log(`${c ? 'PASS' : 'FAIL'} ${n}${c ? '' : ' -> ' + d}`); };
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1400, height: 1000 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.route(/^https?:\/\/(?!127\.0\.0\.1)/, r => r.abort());
  await p.goto('http://127.0.0.1:3900/', { waitUntil: 'networkidle' });
  const nav = async (group, section, tab) => {
    await p.locator('.sidebar-menu a', { hasText: group }).first().click();
    if (section) await p.locator('.sidebar-menu a', { hasText: section }).first().click();
    await p.locator(`a[data-toggle="tab"][data-value="${tab}"]`).first().click();
    await p.waitForTimeout(700);
  };
  const sel = async (id) => p.$eval(`#${id}`, e => e.value).catch(() => null);
  await nav('Funding Programmes', 'Find & Add', 'generate_programme');
  ok('Find Programmes: time zone dropdown, starts on this computer\'s zone', (await sel('generate_programme-time_zone')) === 'Europe/London', await sel('generate_programme-time_zone'));
  await nav('Funding Programmes', 'Find & Add', 'funding_add_single');
  ok('Add Single Entry: time zone dropdown', (await sel('funding_add_single-time_zone')) === 'Europe/London');
  await nav('Funding Programmes', 'Find & Add', 'funding_bulk_import');
  ok('Bulk Import: time zone dropdown', (await sel('funding_bulk_import-time_zone')) === 'Europe/London');
  const opts = await p.evaluate(() => { const s = document.querySelector('#funding_bulk_import-time_zone'); return s && s.selectize ? Object.keys(s.selectize.options).length : -1; });
  ok('30 zones offered', opts === 30, opts);
  await nav('Funding Programmes', 'Review', 'funding_visualizations');
  ok('Visualizations: calendar download button', await p.isVisible('#funding_visualizations-export_ics'));
  ok('Visualizations: reminders + open-dates options', await p.isVisible('#funding_visualizations-ics_alarms') && await p.isVisible('#funding_visualizations-ics_include_opens'));
  await p.waitForFunction(() => (document.querySelector('#funding_visualizations-export_ics_status')?.innerText || '').length > 5, null, { timeout: 15000 });
  ok('Visualizations: status asks to load data first', /Load a view above first/.test(await p.innerText('#funding_visualizations-export_ics_status')));
  ok('Visualizations: Drive save bars still there', await p.isVisible('#funding_visualizations-save_chart-to_drive') && await p.isVisible('#funding_visualizations-save_overview-to_drive'));
  await p.locator('#funding_visualizations-export_ics').scrollIntoViewIfNeeded();
  await p.screenshot({ path: '/home/claude/e2e/funding_viz.png' });
  await nav('Funding Programmes', 'Review', 'funding_browse');
  ok('Browse: calendar button', await p.isVisible('#funding_browse-download_calendar'));
  ok('no page errors (besides the test-only datepicker and plotly shim notes)', errs.filter(e => !/datepicker|GLOBAL is not defined/.test(e)).length === 0, errs.join(' | '));
  await b.close(); const f = res.filter(x => !x).length; console.log(`\n${res.length - f} passed, ${f} failed`);
})().catch(e => { console.error('ERROR', e); process.exit(2); });
