# Chart patterns Claude can identify — Trades tab, box 3

Full catalogue sent to Claude by `tr_pat_llm_prompt()` (`R/utils_patterns_llm.R`), grouped the way the course and the app's own code already group them (Step 1 and Step 2 are the app's own rule-based engine in `R/utils_patterns.R`; Steps 3–6 are the patterns added so Claude's scan is complete). Claude reads the same candles as the chart on screen, plus indicators computed deterministically in R (never invented by Claude): EMA 20/50/200, SMA20, RSI14, MACD + signal + histogram, Bollinger bands, Keltner channel, ADX14 with DI+/DI-, Stochastic %K/%D, ATR14.

**Rules applied to every pattern, whichever step:**
- **Multi-candle only.** A pattern on a single candle (hammer, doji, shooting star, marubozu, spinning top) is never asked for and is refused on the way back even if Claude names one.
- **Must reach the right-hand edge.** Only a pattern whose last candle sits within the final 10 candles is accepted; anything that finished earlier is dropped.
- Every pattern returns the level that **cancels** it (stop side) and its **measured target** (limit side), read off the structure itself (neckline, pole, band, moving average, measured move) rather than invented.
- `confidence` (0–100) and `status` (forming / confirmed / broken) are reported honestly; an empty list is a valid answer.
- A key not in this catalogue is refused; a key is reported once, at its best instance.

Source column: **App** = found today by the app's own deterministic rules (`utils_patterns.R`) as well as offered to Claude; **Claude** = only Claude's scan reports it.

---

## Step 1 — Trend & market structure

| Pattern | Bias | Source | Criteria Claude is told to apply |
|---|---|---|---|
| Uptrend (Dow Theory) | Bullish | App | Higher swing highs **and** higher swing lows across the window; "early" if not yet confirmed by a fresh higher high. |
| Downtrend (Dow Theory) | Bearish | App | Lower swing highs **and** lower swing lows across the window. |
| Support level | Bullish | App | A price shelf touched 3+ separate times (bounces, not one continuous move) without a clean close through it. |
| Resistance level | Bearish | App | Same test on the upside: 3+ separate touches that reject. |
| Old support now resistance | Bearish | App | A broken support level later capping price from above (role reversal). |
| Old resistance now support | Bullish | App | A broken resistance level later holding price from below. |
| Uptrend line | Bullish | App | 3+ touches on rising swing lows, not steeper than ~0.6 ATR per candle (too steep = unsustainable, rejected). |
| Downtrend line | Bearish | App | 3+ touches on falling swing highs, same slope test. |
| Broken uptrend line | Bearish | App | A valid uptrend line closed through from above, break still recent (last ~5 candles) and holding. |
| Broken downtrend line | Bullish | App | Mirror: a downtrend line closed through from below, recent and holding. |
| Broken countertrend line (uptrend continues) | Bullish | App | A line counter to the prevailing uptrend (drawn against the pullback) is broken upward: the main trend resumes. |
| Broken countertrend line (downtrend continues) | Bearish | App | Mirror, downtrend resumes after its countertrend line breaks down. |
| Bullish (ascending) channel | Bullish | App | Parallel rising trend line + a parallel upper line, both with 3+ touches. |
| Bearish (descending) channel | Bearish | App | Parallel falling trend line + parallel lower line, both with 3+ touches. |
| Bullish Engulfing | Bullish | Claude | 2 candles: a down candle fully engulfed (open/close) by the next up candle's real body. |
| Bearish Engulfing | Bearish | App + Claude | Mirror: an up candle fully engulfed by the next down candle. |
| Piercing Pattern | Bullish | App + Claude | Down candle, then an up candle opening below its low and closing above its midpoint. |
| Dark Cloud Cover | Bearish | App + Claude | Up candle, then a down candle opening above its high and closing below its midpoint. |
| Bullish Harami | Bullish | Claude | A large down candle followed by a small up candle contained entirely within its body. |
| Bearish Harami | Bearish | Claude | A large up candle followed by a small down candle contained within its body. |
| Harami Cross | Trend | Claude | A harami whose second candle is a doji — indecision inside the prior range, direction set by what follows. |
| Morning Star | Bullish | Claude | 3 candles: a down candle, a small-bodied candle gapping/dipping lower, then an up candle closing well into the first candle's body. |
| Evening Star | Bearish | Claude | Mirror of Morning Star at a high. |
| Three White Soldiers | Bullish | Claude | 3 consecutive up candles, each opening within the prior body and closing near its own high. |
| Three Black Crows | Bearish | Claude | 3 consecutive down candles, each opening within the prior body and closing near its own low. |
| Tweezer Top | Bearish | Claude | 2 candles sharing (near enough) the same high, first up then down. |
| Tweezer Bottom | Bullish | Claude | 2 candles sharing the same low, first down then up. |
| Rising Three Methods | Bullish | Claude | A long up candle, 3 small down candles staying inside its range, then a new up candle closing above the first. |
| Falling Three Methods | Bearish | Claude | Mirror, continuation of a downtrend. |
| Three Inside Up | Bullish | Claude | A bullish harami followed by a third candle closing above the first candle's open. |
| Three Inside Down | Bearish | Claude | Mirror with a bearish harami. |
| Three Outside Up | Bullish | Claude | A bullish engulfing followed by a third candle closing even higher. |
| Three Outside Down | Bearish | Claude | Mirror with a bearish engulfing. |
| Bullish Kicker | Bullish | Claude | A down candle, then a gap up opening above the prior open, with no overlap. |
| Bearish Kicker | Bearish | Claude | Mirror, gap down with no overlap. |
| Stick Sandwich | Bullish | Claude | Down, up, down candles where the two down candles close at (near) the same price. |
| Matching Low | Bullish | Claude | Two down candles closing at (near) the same low, suggesting a floor. |
| Separating Lines (bullish) | Bullish | Claude | A down candle then an up candle sharing the same open, in an uptrend. |
| Separating Lines (bearish) | Bearish | Claude | Mirror in a downtrend. |

## Step 2 — Fibonacci & classic price patterns

| Pattern | Bias | Source | Criteria |
|---|---|---|---|
| Fibonacci retracement | Trend | App | Pullback from the latest swing measured against 38.2/50/61.8% of the prior leg; the level price is reacting to is reported. |
| Fibonacci 100% expansion | Trend | App | The prior leg's length projected from the retracement low/high as a target. |
| Symmetrical triangle | Trend | App | Converging trend line (lower highs) and support line (higher lows), 5+ turning points, not overly steep. |
| Ascending triangle | Bullish | App | Flat resistance + rising support line, 5+ turning points. |
| Descending triangle | Bearish | App | Flat support + falling resistance line, 5+ turning points. |
| Rising wedge | Bearish | App | Both boundary lines rising, converging, upper line less steep (a weakening uptrend that usually resolves down). |
| Falling wedge | Bullish | App | Both boundary lines falling, converging, lower line less steep. |
| Bullish flag | Bullish | App | A steep pole (4+ ATR) up, then 5–15 candles drifting down in a tight parallel channel. |
| Bearish flag | Bearish | App | Mirror: steep pole down, then a shallow rising parallel channel. |
| Pennant | Trend | App | Steep pole (either direction), then a small symmetrical triangle instead of a parallel channel. |
| Double top | Bearish | App | Two peaks within ~1 ATR of each other, separated by a valley 3+ ATR deep, 4+ candles apart. |
| Double bottom | Bullish | App | Mirror at a low. |
| Head & Shoulders | Bearish | App | Three peaks, the middle (head) higher, the two shoulders roughly level and evenly spaced either side, neckline across the two troughs. |
| Inverse Head & Shoulders | Bullish | App | Mirror at a low, neckline across the two intervening highs. |

## Step 3 — Further price structures, gaps & retests

| Pattern | Bias | Source | Criteria |
|---|---|---|---|
| Triple top | Bearish | Claude | Three peaks at (near enough) the same level, each separated by a real pullback. |
| Triple bottom | Bullish | Claude | Mirror at a low. |
| Rectangle / trading range | Trend | Claude | Price oscillating between a clear flat support and flat resistance, 3+ touches each. |
| Cup and handle | Bullish | Claude | A rounded U-shaped decline-and-recovery back to the prior high (the cup), then a short shallow pullback (the handle) before continuation. |
| Inverted cup and handle | Bearish | Claude | Mirror: a rounded rise-and-fall, then a small bounce before continuation down. |
| Rounding bottom (saucer) | Bullish | Claude | A slow, gradual U-shaped reversal with no sharp turning point. |
| Rounding top | Bearish | Claude | Mirror, a slow dome-shaped reversal. |
| Diamond top | Bearish | Claude | Volatility broadens then narrows at a high, forming a diamond outline, before a break down. |
| Diamond bottom | Bullish | Claude | Mirror at a low. |
| Broadening top (megaphone) | Bearish | Claude | Both a rising resistance line and a falling support line (diverging), higher highs and lower lows, at a market top. |
| Broadening bottom | Bullish | Claude | Mirror at a low. |
| Island reversal top | Bearish | Claude | A gap up, a cluster of candles isolated from the move either side by a gap, then a gap down. |
| Island reversal bottom | Bullish | Claude | Mirror at a low. |
| Measured move up | Bullish | Claude | An initial leg up, a consolidation, then a second leg projected to roughly the same length as the first. |
| Measured move down | Bearish | Claude | Mirror. |
| Round-number level | Trend | Claude | Price repeatedly reacting at a psychological round number (e.g. 11000, 11050) rather than a technically derived level. |
| Volatility squeeze / coil | Trend | Claude | Candle ranges and ATR visibly contracting over several candles, compressing into a tight coil before an expected breakout. |
| Failed breakout (bull trap) | Bearish | Claude | Price broke above resistance, failed to hold, and closed back below it within a few candles. |
| Failed breakdown (bear trap) | Bullish | Claude | Mirror below support. |
| Throwback to a broken level | Trend | Claude | After a breakout, price returns to retest the broken level from the new side before continuing. |
| Pullback to the breakout level | Trend | Claude | Same idea stated the other way round: a shallow retest of the level just broken. |
| Breakaway gap up | Bullish | Claude | A gap up that launches price away from a base/range with strong follow-through. |
| Breakaway gap down | Bearish | Claude | Mirror. |
| Runaway (measuring) gap up | Bullish | Claude | A gap up in the middle of an already-established uptrend, often used to measure the move's remaining length. |
| Runaway (measuring) gap down | Bearish | Claude | Mirror. |
| Exhaustion gap up | Bearish | Claude | A gap up at the end of an extended uptrend, quickly reversing — a sign the move is running out. |
| Exhaustion gap down | Bullish | Claude | Mirror at the end of a downtrend. |
| Spike reversal top | Bearish | Claude | A sharp, narrow one- or two-candle spike to a new high, immediately reversed. |
| Spike reversal bottom | Bullish | Claude | Mirror at a low. |

## Step 4 — Harmonic & Elliott structures

| Pattern | Bias | Source | Criteria |
|---|---|---|---|
| Bullish AB=CD | Bullish | Claude | Two roughly equal-length legs (AB and CD) in the same direction separated by a retracement (BC), completing at a harmonic support zone. |
| Bearish AB=CD | Bearish | Claude | Mirror at resistance. |
| Three drives up (exhaustion) | Bearish | Claude | Three successive higher highs of similar proportion, each a Fibonacci-like extension of the last — a classic exhaustion top. |
| Three drives down (exhaustion) | Bullish | Claude | Mirror at a low. |
| Bullish Wolfe wave | Bullish | Claude | Five swing points forming two roughly parallel channel lines that converge, with point 5 piercing the 1–3 trend line — target is the opposite channel line (the "sweet spot"). |
| Bearish Wolfe wave | Bearish | Claude | Mirror. |
| Elliott impulse up (1–5) | Bullish | Claude | A five-wave advancing sequence (1-2-3-4-5) where wave 3 is not the shortest and wave 4 does not overlap wave 1. |
| Elliott impulse down (1–5) | Bearish | Claude | Mirror, five waves down. |
| Elliott ABC correction | Trend | Claude | A three-wave corrective sequence (A-B-C) against the larger trend, typically retracing part of the prior impulse. |

## Step 5 — Moving averages, momentum, volatility & trend strength

Indicators are computed in R (not estimated by Claude) and handed over as a table plus the values at the last candle.

| Pattern | Bias | Source | Criteria |
|---|---|---|---|
| Golden cross (50 over 200) | Bullish | Claude | EMA50 crosses above EMA200. |
| Death cross (50 under 200) | Bearish | Claude | EMA50 crosses below EMA200. |
| Pullback to the moving average (uptrend) | Bullish | Claude | Price in an established uptrend dips to touch/retest EMA20 or EMA50 then holds. |
| Pullback to the moving average (downtrend) | Bearish | Claude | Mirror. |
| Moving averages stacked bullish | Bullish | Claude | EMA20 above EMA50 above EMA200, all rising — a clean trend alignment. |
| Moving averages stacked bearish | Bearish | Claude | Mirror, all falling. |
| Moving-average ribbon squeeze | Trend | Claude | EMA20/50/200 converging and flattening — a trend losing momentum or a range forming. |
| Price crossed above the moving average | Bullish | Claude | Close crosses from below to above EMA20 or EMA50. |
| Price crossed below the moving average | Bearish | Claude | Mirror. |
| Holy Grail long (ADX > 30, pullback to the 20 EMA) | Bullish | Claude | ADX14 above 30 (strong uptrend) with a shallow pullback to the EMA20, offering a continuation entry. |
| Holy Grail short | Bearish | Claude | Mirror in a strong downtrend. |
| MACD crossed above its signal | Bullish | Claude | MACD line crosses above the signal line. |
| MACD crossed below its signal | Bearish | Claude | Mirror. |
| MACD crossed above zero | Bullish | Claude | MACD line crosses the zero line upward (momentum turns positive). |
| MACD crossed below zero | Bearish | Claude | Mirror. |
| Bullish MACD divergence | Bullish | Claude | Price makes a lower low while MACD makes a higher low. |
| Bearish MACD divergence | Bearish | Claude | Price makes a higher high while MACD makes a lower high. |
| RSI overbought | Bearish | Claude | RSI14 above 70. |
| RSI oversold | Bullish | Claude | RSI14 below 30. |
| Bullish RSI divergence | Bullish | Claude | Price lower low, RSI higher low. |
| Bearish RSI divergence | Bearish | Claude | Price higher high, RSI lower high. |
| RSI bullish failure swing | Bullish | Claude | RSI dips below 30, rallies, pulls back without re-making the low, then breaks its own prior high. |
| RSI bearish failure swing | Bearish | Claude | Mirror above 70. |
| RSI crossed above 50 | Bullish | Claude | RSI14 crosses the 50 midline upward (momentum turns bullish). |
| RSI crossed below 50 | Bearish | Claude | Mirror. |
| Stochastic crossed up from oversold | Bullish | Claude | %K crosses above %D while both are below ~20. |
| Stochastic crossed down from overbought | Bearish | Claude | %K crosses below %D while both are above ~80. |
| Bullish stochastic divergence | Bullish | Claude | Price lower low, stochastic higher low. |
| Bearish stochastic divergence | Bearish | Claude | Price higher high, stochastic lower high. |
| Momentum exhaustion | Trend | Claude | Price still pushing to new highs/lows while every momentum reading (RSI, MACD histogram, stochastic) is flattening or turning — a warning rather than a trade signal on its own. |
| Bollinger squeeze | Trend | Claude | Band width (bb_width) contracts to a multi-candle low — volatility compressed, a breakout likely. |
| Bollinger breakout up | Bullish | Claude | Close breaks and holds above the upper band after a squeeze. |
| Bollinger breakout down | Bearish | Claude | Mirror, below the lower band. |
| Walking the upper Bollinger band | Bullish | Claude | Several consecutive closes hugging/riding the upper band — strong trend, not yet overbought in the mean-reversion sense. |
| Walking the lower Bollinger band | Bearish | Claude | Mirror. |
| Snap back from the lower band | Bullish | Claude | Price tags the lower band then sharply reverts toward the middle band. |
| Snap back from the upper band | Bearish | Claude | Mirror. |
| Keltner channel squeeze | Trend | Claude | Bollinger bands pull inside the Keltner channel — the same squeeze idea on a volatility (ATR) band rather than a standard-deviation band. |
| Volatility expanding (ATR rising) | Trend | Claude | ATR14 trending up over several candles — bigger ranges, often around a breakout or news. |
| Volatility contracting (ATR falling) | Trend | Claude | Mirror — a calming market, often before a squeeze breakout. |
| ADX above 25: the trend is strong | Trend | Claude | ADX14 > 25, confirming a trend is actually in force (not just noise). |
| ADX below 20: no trend, range conditions | Trend | Claude | ADX14 < 20 — range/mean-reversion conditions, trend signals less reliable. |
| DI+ crossed above DI- | Bullish | Claude | The +DI line crosses above -DI (directional movement turns up), especially meaningful with ADX rising. |
| DI- crossed above DI+ | Bearish | Claude | Mirror. |

## Step 6 — Course strategies

| Pattern | Bias | Source | Criteria |
|---|---|---|---|
| Pivot point bounce (long) | Bullish | Claude | Price reacts upward off a classic pivot support (PP, S1, S2) worked out from the prior day's high/low/close, as taught on the course. |
| Pivot point bounce (short) | Bearish | Claude | Mirror off a pivot resistance (PP, R1, R2). |
| Overnight-range straddle, upper side | Bullish | Claude | A buy-stop breakout above the 22:00–06:00 London overnight high, in line with the course's overnight-range straddle strategy. |
| Overnight-range straddle, lower side | Bearish | Claude | Mirror, a sell-stop breakout below the overnight low. |
| Opening-range breakout up | Bullish | Claude | A stop entry above the high of the defined opening range once the session starts trading. |
| Opening-range breakout down | Bearish | Claude | Mirror, below the opening range's low. |

---

**Coverage:** 141 patterns across 19 groups / the 6 steps above. The app's own rule-based engine (`utils_patterns.R`) independently finds 38 of these (all of Steps 1–2); Claude's scan (`utils_patterns_llm.R`, button "Ask Claude to find every pattern (multi-candle)" in Trades box 3) covers the full 141, including everything the app's rules already find (so Claude can confirm or sharpen them) plus the 103 patterns in Steps 3–6 that have no deterministic rule written for them yet.
