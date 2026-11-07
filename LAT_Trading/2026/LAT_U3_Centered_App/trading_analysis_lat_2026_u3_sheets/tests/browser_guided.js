// tests/browser_guided.js - the Guided Desk ******: every piece of tabs 2-6 moves into its step card and back. Run the full app on :8863.
const { chromium } = require('playwright');
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1400, height: 1100 } }); let pass = 0, fail = 0; const errs = [];
  const known = [/datepicker is not a function/, /GLOBAL is not defined/]; p.on('pageerror', e => { if (!known.some(k => k.test(e.message))) errs.push(e.message); });
  const ok = (c, m) => { if (c) { pass++; console.log('  ok  ', m); } else { fail++; console.log('  FAIL', m); } };
  const where = k => p.evaluate(k => { const e = document.getElementById('desk-sec-' + k); return e ? e.parentNode.className : 'missing'; }, k);
  const all = async (keys, cls) => { for (const k of keys) if (await where(k) !== cls) return k; return true; };
  const S = { g1: ['ms1','ms2','ms3','ms4','ms5'], g2: ['mk1','mk2','mk3','mk4','po1','po2','po3','po4','po5','po6'], g3: ['ps1','ps2','ps3','ps4','jn1','jn2','jn3'] };
  await p.goto('http://127.0.0.1:8863', { timeout: 60000 }); await p.waitForTimeout(14000);
  await p.click('a[data-value="Guided Desk"]').catch(()=>{}); await p.waitForTimeout(1500);
  ok(await all(S.g1, 'desk-slot') === true, 'step 1 holds all 5 Morning Sheet pieces');
  ok(await p.isVisible('#trading_records-ms_save') && await p.isVisible('#trading_records-ms_yahoo'), 'pull and save buttons visible in step 1');
  ok(await p.locator('.gd-step').count() === 3, 'progress bar with 3 steps');
  await p.click('.gd-step[data-go="2. Analyse & Recommend"]'); await p.waitForTimeout(1500);
  ok(await all(S.g2, 'desk-slot') === true, 'step 2 holds all market, chart, plan and order pieces');
  ok(await p.isVisible('#cc_records-c_load') && await p.isVisible('#cc_records-p_claude') && await p.isVisible('#cc_records-p_hist_use'), 'load chart, past-trades option and recommendation visible');
  await p.click('.gd-nav .btn-success >> visible=true'); await p.waitForTimeout(1500);
  ok(await all(S.g3, 'desk-slot') === true, 'Next opens step 3 with every positions and journal piece');
  ok(await p.isVisible('#cc_records-j_save') && await p.isVisible('#cc_records-j_drop') && await p.isVisible('#cc_records-sync'), 'sync, save record and Dropbox buttons visible');
  ok(!(await p.isVisible('#cc_records-j_tbl')), 'More tools stay folded until opened');
  await p.click('.tab-pane.active details.gd-more summary >> visible=true'); await p.waitForTimeout(800);
  ok(await p.isVisible('#cc_records-j_dl'), 'More tools open: all trades and the download');
  await p.click('.tab-pane.active .gd-links a[data-go="8. Statistics"] >> visible=true'); await p.waitForTimeout(1000);
  ok(await p.evaluate(() => $('#trading_records-tabs li.active a').data('value')) === '8. Statistics', 'link opens a numbered tab');
  for (const [t, keys] of [['2. Morning Sheet', S.g1], ['3. Market & Patterns', ['mk1','mk2','mk3','mk4']], ['4. Plan & Order', S.g2.slice(4)], ['5. Positions & Sync', S.g3.slice(0,4)], ['6. Journal & Trade Sheet', S.g3.slice(4)]]) {
    await p.click(`a[data-value="${t}"]`); await p.waitForTimeout(900); ok(await all(keys, 'desk-home') === true, `${t}: its pieces back, in order`); }
  const dup = await p.evaluate(() => { const ids = [...document.querySelectorAll('[id]')].map(e => e.id).filter(i => /^(cc_records|trading_records|trading_decision|trading_evidence|desk)/.test(i)); return ids.filter((x, i) => ids.indexOf(x) !== i).join(', '); }); ok(dup === '', 'no duplicate ids in the page ' + dup); // = [...document.querySelectorAll('[id]')].map(e => e.id).filter(i => !/^ui-tab-/.test(i)); /* Shiny's random tab-link ids can collide; not used by the app */ return ids.length === new Set(ids).size; }), 'no duplicate ids in the page');
  ok(errs.length === 0, 'no page errors ' + errs.join('; '));
  console.log(`\n${pass} passed, ${fail} failed`); await b.close(); process.exit(fail ? 1 : 0); })();
