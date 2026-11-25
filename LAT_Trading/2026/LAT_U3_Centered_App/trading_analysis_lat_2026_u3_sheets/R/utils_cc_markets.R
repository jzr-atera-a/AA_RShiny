# R/utils_cc_markets.R
# Every Capital.com market on the Trading Desk, whatever its asset class (forex, energy, metals, agriculture, indices,
# shares, crypto, ETFs, bonds / rates):
#   - cc_class_of()        the asset class from Capital.com's instrument type, epic and name
#   - cc_market_profile()  what the desk needs to know about a market: drivers, scheduled reports, calendar currencies and
#                          countries, sessions (UK time), news focus, related markets, its Yahoo symbol, exposure group
#   - cc_hours_*()         Capital.com opening hours: open now? next open / close
#   - cc_nav_*()           Capital.com market navigation (all asset classes and markets)
#   - cc_watch             the trader's list of markets (watchlist), shared by A Morning Sheet, B Analyse & Place, H ML
#   - cc_epic_code()       Capital.com epic -> the app's market code used on the Morning Sheet (BRENT, WTI, EURUSD, ...)
#   - cc_morning_levels()  overnight low / high / price, previous session and ADX from Capital.com candles for any market
#   - cc_news_relevant(), cc_profile_prompt(), cc_exposure_note(), cc_size_problems()

`%||%` <- function(x, y) if (is.null(x)) y else x

# ---- currencies: central bank, country names as the calendars write them, main releases ---------------------------
cc_ccy <- list(
  USD = list(cb = "Federal Reserve (FOMC)", countries = c("United States", "US", "USA", "USD"), data = "Non-Farm Payrolls, CPI / PCE inflation, ISM PMIs, retail sales, jobless claims, FOMC decision and minutes"),
  EUR = list(cb = "European Central Bank", countries = c("Euro Area", "Eurozone", "EU", "Germany", "France", "Italy", "Spain", "EUR"), data = "HICP inflation flash, PMIs, German Ifo / ZEW, GDP, ECB decision"),
  GBP = list(cb = "Bank of England", countries = c("United Kingdom", "UK", "GBP"), data = "CPI, labour market, GDP, PMIs, retail sales, BoE decision"),
  JPY = list(cb = "Bank of Japan", countries = c("Japan", "JPY"), data = "Tokyo CPI, national CPI, BoJ decision, wage data; Ministry of Finance intervention risk"),
  AUD = list(cb = "Reserve Bank of Australia", countries = c("Australia", "AUD"), data = "employment, CPI, RBA decision; China activity data"),
  CAD = list(cb = "Bank of Canada", countries = c("Canada", "CAD"), data = "employment, CPI, BoC decision; oil prices"),
  CHF = list(cb = "Swiss National Bank", countries = c("Switzerland", "CHF"), data = "CPI, SNB decision; safe-haven flows"),
  NZD = list(cb = "Reserve Bank of New Zealand", countries = c("New Zealand", "NZD"), data = "CPI, employment, RBNZ decision; dairy auctions"),
  CNH = list(cb = "People's Bank of China", countries = c("China", "CNY", "CNH"), data = "PMIs, trade balance, CPI / PPI, PBoC fixing"),
  CNY = list(cb = "People's Bank of China", countries = c("China", "CNY", "CNH"), data = "PMIs, trade balance, CPI / PPI, PBoC fixing"),
  HKD = list(cb = "Hong Kong Monetary Authority", countries = c("Hong Kong", "HKD"), data = "follows US rates (USD peg)"),
  SEK = list(cb = "Riksbank", countries = c("Sweden", "SEK"), data = "CPI, Riksbank decision"),
  NOK = list(cb = "Norges Bank", countries = c("Norway", "NOK"), data = "CPI, Norges Bank decision; oil prices"),
  DKK = list(cb = "Danmarks Nationalbank", countries = c("Denmark", "DKK"), data = "follows the ECB (EUR peg)"),
  PLN = list(cb = "National Bank of Poland", countries = c("Poland", "PLN"), data = "CPI, NBP decision"),
  HUF = list(cb = "Magyar Nemzeti Bank", countries = c("Hungary", "HUF"), data = "CPI, MNB decision"),
  CZK = list(cb = "Czech National Bank", countries = c("Czech Republic", "CZK"), data = "CPI, CNB decision"),
  TRY = list(cb = "Central Bank of Turkey", countries = c("Turkey", "TRY"), data = "CPI, CBRT decision"),
  ZAR = list(cb = "South African Reserve Bank", countries = c("South Africa", "ZAR"), data = "CPI, SARB decision; gold and platinum prices"),
  MXN = list(cb = "Banxico", countries = c("Mexico", "MXN"), data = "CPI, Banxico decision; US trade policy"),
  SGD = list(cb = "Monetary Authority of Singapore", countries = c("Singapore", "SGD"), data = "CPI, MAS policy statement"),
  INR = list(cb = "Reserve Bank of India", countries = c("India", "INR"), data = "CPI, RBI decision"),
  BRL = list(cb = "Banco Central do Brasil", countries = c("Brazil", "BRL"), data = "IPCA inflation, Selic decision"),
  ILS = list(cb = "Bank of Israel", countries = c("Israel", "ILS"), data = "CPI, BoI decision"))
cc_fiat <- names(cc_ccy)

# ---- asset class ------------------------------------------------------------------------------------------------
cc_class_labels <- c(forex = "Forex", energy = "Commodity: energy", metals = "Commodity: metals", agri = "Commodity: agriculture", index = "Index",
                     share = "Share", crypto = "Crypto", etf = "ETF", bond = "Bond / interest rate", other = "Other")
cc_rx <- list(
  energy = "BRENT|CRUDE|WTI|OIL|NATURAL.?GAS|NATGAS|HEATING|GASOLINE|RBOB|GASOIL|CARBON|EMISSION|URANIUM",
  metals = "GOLD|SILVER|COPPER|PLATINUM|PALLADIUM|ALUMIN|ZINC|NICKEL|LEAD|TIN\\b|IRON|STEEL|LITHIUM|COBALT|XAU|XAG|XPT|XPD",
  agri = "COFFEE|COCOA|SUGAR|WHEAT|CORN|SOYBEAN|SOY|COTTON|ORANGE|OATS|RICE|CATTLE|HOGS|LUMBER|CANOLA|PALM|MILK|RUBBER",
  crypto = "BITCOIN|ETHEREUM|RIPPLE|LITECOIN|SOLANA|CARDANO|DOGE|POLKADOT|CHAINLINK|AVALANCHE|BINANCE|POLYGON|SHIBA|TRON|STELLAR|COSMOS|UNISWAP|PEPE",
  index = "US ?30|US ?500|US ?100|US ?2000|WALL ?STREET|S&P|NASDAQ|TECH ?100|DOW|RUSSELL|UK ?100|FTSE|GERMANY|DAX|DE ?40|FRANCE|CAC|FR ?40|EU ?50|EURO ?STOXX|EUROPE ?50|SPAIN|IBEX|ITALY|NETHERLANDS|AEX|SWITZERLAND|SMI|JAPAN|NIKKEI|J225|HONG ?KONG|HANG ?SENG|HK ?50|AUSTRALIA|ASX|AU ?200|CHINA ?A50|CN ?50|SINGAPORE|INDIA|VIX|VOLATILITY|DOLLAR INDEX|DXY|USDX",
  bond = "BUND|GILT|T-?NOTE|T-?BOND|TREASURY|SCHATZ|BOBL|BTP|OAT\\b|10Y|30Y|2Y|YIELD")
cc_crypto_tickers <- c("BTC", "ETH", "XRP", "LTC", "BCH", "SOL", "ADA", "DOGE", "DOT", "LINK", "AVAX", "BNB", "MATIC", "POL", "SHIB", "TRX", "XLM", "ATOM", "UNI", "ETC", "XMR", "ALGO",
                       "NEAR", "APT", "ARB", "OP", "FIL", "ICP", "AAVE", "SAND", "MANA", "AXS", "EOS", "XTZ", "PEPE", "SUI", "TON", "HBAR", "INJ", "RNDR", "GRT", "MKR", "CRV", "WIF", "BONK", "FLOKI")
cc_class_of <- function(type = NA, epic = "", name = "") {
  ty <- toupper(as.character(type %||% NA)[1]); if (is.na(ty)) ty <- ""
  e <- toupper(as.character(epic %||% "")[1]); n <- toupper(as.character(name %||% "")[1]); en <- paste(e, n)
  if (grepl("CRYPTO", ty)) return("crypto")
  if (grepl("^CURRENC|FOREX|^FX$", ty)) {
    b <- substr(gsub("[^A-Z]", "", e), 1, 3); if (b %in% cc_crypto_tickers) return("crypto"); return("forex") }
  if (grepl("SHARE|STOCK|EQUIT", ty)) return(if (grepl("\\bETF\\b|ISHARES|SPDR|VANGUARD|INVESCO|\\bTRUST\\b", n)) "etf" else "share")
  if (grepl("ETF", ty)) return("etf")
  if (grepl("RATE|BOND", ty)) return("bond")
  if (grepl("INDIC|INDEX", ty)) return(if (grepl(cc_rx$bond, en) && !grepl(cc_rx$index, en)) "bond" else "index")
  if (grepl("COMMOD", ty)) { for (k in c("energy", "metals", "agri")) if (grepl(cc_rx[[k]], en)) return(k); return("energy") }
  # no type: from the epic / name
  g <- gsub("[^A-Z]", "", e)
  if (nchar(g) == 6 && substr(g, 1, 3) %in% cc_crypto_tickers) return("crypto")
  if (nchar(g) == 6 && substr(g, 1, 3) %in% cc_fiat && substr(g, 4, 6) %in% cc_fiat) return("forex")
  for (k in c("crypto", "energy", "metals", "agri", "index", "bond")) if (grepl(cc_rx[[k]], en)) return(k)
  if (grepl("\\bETF\\b|ISHARES|SPDR|VANGUARD", n)) return("etf")
  "other"   # no type and no known name: not guessed (a share needs Capital.com's type SHARES)
}

# ---- Yahoo Finance symbol (for the Morning Sheet levels, the Decision Panel and Yahoo candles) -----------------------
cc_yahoo_map <- c(OIL_BRENT = "BZ=F", OIL_CRUDE = "CL=F", BRENT = "BZ=F", WTI = "CL=F", NATURALGAS = "NG=F", NATGAS = "NG=F", HEATINGOIL = "HO=F", GASOLINE = "RB=F",
  GOLD = "GC=F", SILVER = "SI=F", COPPER = "HG=F", PLATINUM = "PL=F", PALLADIUM = "PA=F", ALUMINIUM = "ALI=F", ALUMINUM = "ALI=F",
  COFFEEARABICA = "KC=F", COFFEE = "KC=F", COCOA = "CC=F", SUGAR = "SB=F", WHEAT = "ZW=F", CORN = "ZC=F", SOYBEAN = "ZS=F", SOYBEANS = "ZS=F", COTTON = "CT=F",
  OATS = "ZO=F", RICE = "ZR=F", LIVECATTLE = "LE=F", LEANHOGS = "HE=F", ORANGEJUICE = "OJ=F", LUMBER = "LBS=F",
  US30 = "^DJI", US500 = "^GSPC", US100 = "^NDX", US2000 = "^RUT", RTY = "^RUT", UK100 = "^FTSE", DE40 = "^GDAXI", GER40 = "^GDAXI", FR40 = "^FCHI", EU50 = "^STOXX50E",
  ES35 = "^IBEX", IT40 = "FTSEMIB.MI", NL25 = "^AEX", CH20 = "^SSMI", J225 = "^N225", JP225 = "^N225", HK50 = "^HSI", AU200 = "^AXJO", CN50 = "XIN9.FGI", SG25 = "^STI", IN50 = "^NSEI",
  VIX = "^VIX", DXY = "DX-Y.NYB", USDX = "DX-Y.NYB", DOLLARINDEX = "DX-Y.NYB", DOW = "^DJI", SP500 = "^GSPC", NASDAQ = "^NDX", FTSE100 = "^FTSE")
cc_yahoo_names <- list(c("BRENT", "BZ=F"), c("CRUDE|WTI", "CL=F"), c("NATURAL ?GAS", "NG=F"), c("HEATING", "HO=F"), c("GASOLINE", "RB=F"), c("GOLD", "GC=F"), c("SILVER", "SI=F"),
  c("COPPER", "HG=F"), c("PLATINUM", "PL=F"), c("PALLADIUM", "PA=F"), c("COFFEE", "KC=F"), c("COCOA", "CC=F"), c("SUGAR", "SB=F"), c("WHEAT", "ZW=F"), c("CORN", "ZC=F"),
  c("SOYBEAN", "ZS=F"), c("COTTON", "CT=F"), c("WALL ?STREET|DOW", "^DJI"), c("US ?500|S&P", "^GSPC"), c("TECH ?100|NASDAQ", "^NDX"), c("RUSSELL|US ?2000", "^RUT"),
  c("UK ?100|FTSE ?100", "^FTSE"), c("GERMANY|DAX", "^GDAXI"), c("FRANCE|CAC", "^FCHI"), c("EU(RO)? ?(STOXX)? ?50|EUROPE ?50", "^STOXX50E"), c("SPAIN|IBEX", "^IBEX"),
  c("JAPAN|NIKKEI", "^N225"), c("HONG ?KONG|HANG ?SENG", "^HSI"), c("AUSTRALIA|ASX", "^AXJO"), c("NETHERLANDS|AEX", "^AEX"), c("SWITZERLAND|SMI", "^SSMI"), c("VOLATILITY|VIX", "^VIX"),
  c("DOLLAR ?INDEX|DXY", "DX-Y.NYB"))
cc_yahoo_symbol <- function(epic, name = "", type = NA, currency = NA) {
  e <- toupper(as.character(epic %||% "")[1]); g <- gsub("[^A-Z0-9]", "", e)
  if (g %in% names(cc_yahoo_map)) return(unname(cc_yahoo_map[[g]]))
  if (e %in% names(cc_yahoo_map)) return(unname(cc_yahoo_map[[e]]))
  cl <- cc_class_of(type, epic, name)
  if (cl == "crypto") { b <- substr(gsub("[^A-Z]", "", g), 1, nchar(gsub("[^A-Z]", "", g)) - 3); q <- substr(g, nchar(g) - 2, nchar(g))
    if (nchar(b) >= 2 && q %in% c("USD", "EUR", "GBP")) return(sprintf("%s-%s", b, q)) }
  if (cl == "forex" && nchar(g) == 6) return(if (substr(g, 1, 3) == "USD") paste0(substr(g, 4, 6), "=X") else paste0(g, "=X"))
  n <- toupper(as.character(name %||% "")[1])
  if (cl %in% c("energy", "metals", "agri", "index")) for (x in cc_yahoo_names) if (grepl(x[1], n)) return(x[2])
  if (cl %in% c("share", "etf") && grepl("^[A-Z]{1,5}(\\.[A-Z])?$", e)) {
    ccy <- toupper(as.character(currency %||% NA)[1])
    if (is.na(ccy) || ccy == "USD") return(sub("\\.", "-", e))
    if (ccy %in% c("GBP", "GBX", "GBp")) return(paste0(e, ".L"))
  }
  NA_character_
}

# ---- profile of one market --------------------------------------------------------------------------------------
cc_sub_rules <- list(   # first match wins: sub-type, drivers, scheduled reports (calendar words), related markets, exposure group, sessions (UK)
  list(class = "energy", rx = "BRENT", sub = "Brent crude oil", drivers = c("OPEC+ supply decisions and compliance", "EIA / API weekly US inventories", "global demand (China, Europe), refinery runs", "Middle East / Russia supply risk, shipping", "US dollar"),
       reports = "EIA Crude Oil Inventories|API Weekly|OPEC|Baker Hughes|rig count|petroleum|crude", related = c("OIL_CRUDE", "NATURALGAS", "USDCAD"), group = "Energy (oil and gas)", hours = "about 01:00-22:00, most active 13:00-19:30 (New York)"),
  list(class = "energy", rx = "CRUDE|WTI|\\bOIL", sub = "WTI crude oil", drivers = c("EIA / API weekly US inventories and Cushing stocks", "OPEC+ supply", "US driving season and refinery runs", "geopolitical supply risk", "US dollar"),
       reports = "EIA Crude Oil Inventories|API Weekly|OPEC|Baker Hughes|rig count|petroleum|crude", related = c("OIL_BRENT", "NATURALGAS", "USDCAD"), group = "Energy (oil and gas)", hours = "about 23:00-22:00, most active 13:00-19:30 (New York)"),
  list(class = "energy", rx = "NATURAL.?GAS|NATGAS", sub = "Natural gas", drivers = c("weather: heating / cooling degree days and forecasts", "EIA weekly storage (Thursday)", "LNG exports and outages", "production levels"),
       reports = "Natural Gas Storage|EIA|natural gas", related = c("OIL_CRUDE", "OIL_BRENT"), group = "Energy (oil and gas)", hours = "about 23:00-22:00, most active 13:00-19:30 (New York)"),
  list(class = "energy", rx = "HEATING|GASOIL|GASOLINE|RBOB", sub = "Refined products", drivers = c("refinery margins and outages", "EIA distillate / gasoline stocks", "crude oil price", "seasonal demand"),
       reports = "EIA|distillate|gasoline|crude", related = c("OIL_CRUDE", "OIL_BRENT"), group = "Energy (oil and gas)", hours = "about 23:00-22:00"),
  list(class = "energy", rx = ".", sub = "Energy", drivers = c("supply and demand balance", "policy and regulation", "crude oil and gas prices"), reports = "EIA|OPEC", related = c("OIL_BRENT"), group = "Energy (oil and gas)", hours = "exchange hours"),
  list(class = "metals", rx = "GOLD|XAU", sub = "Gold", drivers = c("US real yields and Fed rate expectations", "US dollar", "US inflation (CPI, PCE)", "safe-haven demand (geopolitics, equity sell-offs)", "central-bank buying"),
       reports = "CPI|PCE|Non-Farm|Payrolls|FOMC|Fed|Unemployment|GDP|Jobless", related = c("SILVER", "EURUSD", "USDJPY"), group = "Precious metals and USD", hours = "about 23:00-22:00, most active 13:00-17:00"),
  list(class = "metals", rx = "SILVER|XAG", sub = "Silver", drivers = c("gold and US real yields", "industrial demand (solar, electronics)", "US dollar", "Fed expectations"),
       reports = "CPI|PCE|Non-Farm|Payrolls|FOMC|ISM|PMI", related = c("GOLD", "COPPER"), group = "Precious metals and USD", hours = "about 23:00-22:00"),
  list(class = "metals", rx = "PLATINUM|PALLADIUM|XPT|XPD", sub = "Platinum-group metals", drivers = c("car production and catalyst demand", "South African and Russian supply", "US dollar"),
       reports = "PMI|car|auto|CPI", related = c("GOLD", "USDZAR"), group = "Precious metals and USD", hours = "about 23:00-22:00"),
  list(class = "metals", rx = ".", sub = "Industrial metals", drivers = c("China activity (PMIs, property, stimulus)", "global manufacturing PMIs", "LME / Comex stocks and supply disruptions", "US dollar"),
       reports = "PMI|China|Industrial Production|GDP|Trade Balance", related = c("AUDUSD", "US500"), group = "Industrial metals and China", hours = "about 01:00-22:00"),
  list(class = "agri", rx = "COFFEE|COCOA|SUGAR|ORANGE|COTTON", sub = "Softs", drivers = c("weather in the growing regions (Brazil, West Africa, India)", "crop and harvest estimates", "exporter currencies (BRL)", "stocks and shipments"),
       reports = "USDA|WASDE|crop|harvest", related = c("USDBRL"), group = "Agriculture", hours = "ICE hours, about 09:00-18:30"),
  list(class = "agri", rx = ".", sub = "Grains and livestock", drivers = c("USDA WASDE and crop progress reports", "weather in the US, Brazil, Black Sea", "export demand (China)", "US dollar"),
       reports = "USDA|WASDE|crop|export sales|Grain Stocks|Prospective Plantings", related = c("CORN", "WHEAT", "SOYBEAN"), group = "Agriculture", hours = "CBOT hours, about 01:00-13:45 and 14:30-19:20"),
  list(class = "index", rx = "US ?30|US ?500|US ?100|US ?2000|WALL ?STREET|S&P|NASDAQ|TECH ?100|DOW|RUSSELL|RTY|^US", sub = "US index", ccy = "USD", drivers = c("Fed rate expectations and US yields", "US data: CPI, payrolls, ISM", "earnings of the largest companies", "risk sentiment and the VIX"),
       reports = "CPI|Non-Farm|Payrolls|FOMC|Fed|ISM|Retail Sales|GDP|PCE|Jobless|earnings", related = c("US500", "US100", "US30", "VIX"), group = "US equities", hours = "cash 14:30-21:00, futures almost 24 hours"),
  list(class = "index", rx = "UK ?100|FTSE", sub = "UK index", ccy = "GBP", drivers = c("Bank of England and UK data", "GBP (a weaker pound lifts the FTSE's overseas earners)", "oil and mining shares", "global risk sentiment"),
       reports = "CPI|GDP|BoE|Bank of England|PMI|Retail Sales|Claimant", related = c("GBPUSD", "DE40", "OIL_BRENT"), group = "European equities", hours = "cash 08:00-16:30"),
  list(class = "index", rx = "GERMANY|DAX|DE ?40|GER", sub = "German index", ccy = "EUR", drivers = c("ECB and euro-area data", "German Ifo / ZEW, PMIs, industrial orders", "exports to China and the US, tariffs", "global risk sentiment"),
       reports = "ECB|Ifo|ZEW|PMI|CPI|HICP|GDP|Industrial", related = c("EU50", "FR40", "EURUSD"), group = "European equities", hours = "cash 08:00-16:30"),
  list(class = "index", rx = "FRANCE|CAC|FR ?40|EU ?50|EURO ?STOXX|EUROPE|SPAIN|IBEX|ITALY|NETHERLANDS|AEX|SWITZERLAND|SMI", sub = "European index", ccy = "EUR", drivers = c("ECB and euro-area data", "PMIs and inflation", "global risk sentiment", "banks and luxury / industrial sectors"),
       reports = "ECB|PMI|CPI|HICP|GDP|Ifo|ZEW", related = c("DE40", "EU50", "EURUSD"), group = "European equities", hours = "cash 08:00-16:30"),
  list(class = "index", rx = "JAPAN|NIKKEI|J225|JP", sub = "Japanese index", ccy = "JPY", drivers = c("USD/JPY (a weaker yen lifts exporters)", "Bank of Japan", "US tech shares overnight", "Japanese data"),
       reports = "BoJ|Bank of Japan|CPI|Tankan|GDP", related = c("USDJPY", "US100"), group = "Asian equities", hours = "cash 00:00-06:00"),
  list(class = "index", rx = "HONG ?KONG|HANG ?SENG|HK|CHINA|CN ?50|A50", sub = "Chinese / Hong Kong index", ccy = "HKD", drivers = c("China stimulus and property sector", "China PMIs, trade, CPI", "US-China relations", "tech regulation"),
       reports = "China|PMI|PBoC|GDP|Trade Balance|CPI", related = c("AUDUSD", "COPPER"), group = "Asian equities", hours = "cash 01:30-08:00"),
  list(class = "index", rx = "AUSTRALIA|ASX|AU ?200", sub = "Australian index", ccy = "AUD", drivers = c("RBA and Australian data", "iron ore and mining shares", "China activity", "banks"),
       reports = "RBA|Employment|CPI|China", related = c("AUDUSD", "COPPER"), group = "Asian equities", hours = "cash 23:00-05:00"),
  list(class = "index", rx = "VIX|VOLATILITY", sub = "Volatility index", ccy = "USD", drivers = c("US equity sell-offs (rises when the S&P falls)", "event risk: CPI, FOMC, elections"), reports = "CPI|FOMC|Non-Farm|Payrolls",
       related = c("US500"), group = "US equities", hours = "about 23:00-22:00"),
  list(class = "index", rx = "DOLLAR|DXY|USDX", sub = "US dollar index", ccy = "USD", drivers = c("Fed vs other central banks", "US data", "risk sentiment"), reports = "CPI|Non-Farm|Payrolls|FOMC|Fed|ISM|PCE", related = c("EURUSD", "GOLD"),
       group = "US dollar", hours = "about 23:00-22:00"),
  list(class = "index", rx = ".", sub = "Equity index", drivers = c("central bank and local data", "earnings season", "global risk sentiment"), reports = "CPI|GDP|PMI|rate decision", related = c("US500"), group = "Equities", hours = "the exchange's cash hours"),
  list(class = "crypto", rx = ".", sub = "Crypto", ccy = "USD", drivers = c("risk sentiment and US tech shares", "ETF flows", "regulation and exchange news", "US dollar liquidity and Fed expectations", "weekend moves on thin liquidity"),
       reports = "CPI|FOMC|Fed|Non-Farm|Payrolls|SEC|ETF", related = c("BTCUSD", "ETHUSD", "US100"), group = "Crypto", hours = "24 hours, 7 days (thin at weekends)"),
  list(class = "bond", rx = ".", sub = "Bond / interest rate", drivers = c("central-bank rate expectations", "inflation data", "government borrowing and auctions"), reports = "CPI|PCE|FOMC|ECB|BoE|auction|GDP|Payrolls", related = c("US500", "GOLD"),
       group = "Rates", hours = "exchange hours"),
  list(class = "other", rx = ".", sub = "Other", drivers = c("supply and demand", "news on the market"), reports = "", related = character(0), group = "Other", hours = "see the market's opening hours"))

cc_share_sessions <- function(ccy) switch(toupper(ccy %||% ""), USD = "US cash 14:30-21:00 (pre-market from 09:00 on some markets)", GBP = , GBX = "London 08:00-16:30",
  EUR = "European cash 08:00-16:30", CHF = "Zurich 08:00-16:30", JPY = "Tokyo 00:00-06:00", HKD = "Hong Kong 01:30-08:00", AUD = "Sydney 23:00-05:00", CAD = "Toronto 14:30-21:00", "the exchange's cash hours")
cc_share_index <- function(ccy) switch(toupper(ccy %||% ""), USD = c("US500", "US100"), GBP = , GBX = "UK100", EUR = c("DE40", "EU50"), JPY = "J225", HKD = "HK50", AUD = "AU200", "US500")

cc_market_profile <- function(epic, name = "", type = NA, currency = NA) {
  epic <- as.character(epic %||% "")[1]; name <- as.character(name %||% "")[1]; if (is.na(name)) name <- ""
  cl <- cc_class_of(type, epic, name); en <- toupper(paste(epic, name)); ccy <- toupper(as.character(currency %||% NA)[1])
  p <- list(epic = epic, name = if (nzchar(name)) name else epic, class = cl, class_label = cc_class_labels[[cl]], currency = ccy, yahoo = cc_yahoo_symbol(epic, name, type, currency))
  if (cl == "forex") {
    g <- gsub("[^A-Z]", "", toupper(epic)); b <- substr(g, 1, 3); q <- substr(g, 4, 6); ib <- cc_ccy[[b]]; iq <- cc_ccy[[q]]
    g7 <- c("EUR", "GBP", "AUD", "NZD", "CAD", "CHF", "JPY")
    p$sub <- if ("USD" %in% c(b, q) && any(c(b, q) %in% g7)) "FX major" else if (all(c(b, q) %in% g7)) "FX cross" else "FX exotic"
    p$ccys <- c(b, q)
    p$drivers <- c(sprintf("interest-rate gap: %s vs %s", ib$cb %||% b, iq$cb %||% q), sprintf("%s data: %s", b, ib$data %||% "main releases"), sprintf("%s data: %s", q, iq$data %||% "main releases"),
                   "risk sentiment (safe havens USD, JPY, CHF vs AUD, NZD and emerging currencies)")
    p$reports <- "CPI|Payrolls|Non-Farm|Employment|Unemployment|GDP|PMI|Retail Sales|rate decision|Interest Rate|Central Bank|FOMC|ECB|BoE|BoJ|RBA|BoC|SNB|RBNZ|Minutes|Speech"
    p$cal_countries <- unique(c(b, q, ib$countries, iq$countries))
    p$related <- setdiff(unique(c(if (b != "USD" && q != "USD") c(paste0(b, "USD"), paste0("USD", q)) else character(0), if ("USD" %in% c(b, q)) c("DXY", "GOLD") else character(0))), toupper(epic))
    p$group <- if ("USD" %in% c(b, q)) "US dollar" else sprintf("%s and %s", b, q)
    p$hours <- "24 hours Sunday 22:00 to Friday 22:00; most active 08:00-17:00 (London, with New York from 13:00)"
    p$news_focus <- sprintf("%s and %s: central banks (%s, %s), inflation, jobs and growth data, risk sentiment", b, q, ib$cb %||% b, iq$cb %||% q)
    p$always_usd <- FALSE
    return(p)
  }
  if (cl %in% c("share", "etf")) {
    p$sub <- if (cl == "etf") "Exchange-traded fund" else "Single share"
    p$drivers <- c("the company's earnings date and guidance", "company news (deals, regulators, management, analysts' ratings)", sprintf("its sector and its home index (%s)", paste(cc_share_index(ccy), collapse = ", ")),
                   "rates and the market's risk sentiment")
    p$reports <- "earnings|results|CPI|FOMC|Fed|Payrolls|Non-Farm"; p$cal_countries <- unique(c(ccy, cc_ccy[[if (ccy %in% c("GBX")) "GBP" else ccy %||% "USD"]]$countries %||% character(0)))
    p$related <- cc_share_index(ccy); p$group <- sprintf("%s equities", switch(ccy %||% "", USD = "US", GBP = , GBX = "UK", EUR = "European", if (is.na(ccy)) "" else ccy))
    p$hours <- cc_share_sessions(ccy); p$news_focus <- sprintf("%s (%s): company news, earnings, analyst changes, sector news", p$name, epic); p$always_usd <- identical(ccy, "USD")
    return(p)
  }
  r <- NULL; for (x in cc_sub_rules) if (x$class == cl && grepl(x$rx, en)) { r <- x; break }
  if (is.null(r)) r <- cc_sub_rules[[length(cc_sub_rules)]]
  p$sub <- r$sub; p$drivers <- r$drivers; p$reports <- r$reports; p$related <- setdiff(r$related, toupper(epic)); p$group <- r$group; p$hours <- r$hours
  home <- r$ccy %||% (if (cl %in% c("energy", "metals", "agri", "crypto", "bond")) "USD" else ccy)
  p$cal_countries <- unique(c(home, cc_ccy[[home %||% "USD"]]$countries %||% character(0), if (cl %in% c("metals") && grepl("COPPER|ALUMIN|ZINC|NICKEL", en)) cc_ccy$CNH$countries))
  p$news_focus <- sprintf("%s: %s", p$name, paste(utils::head(r$drivers, 3), collapse = "; "))
  p$always_usd <- cl %in% c("energy", "metals", "agri", "crypto") || identical(home, "USD")
  p
}
# which calendar events matter for a market (country / currency, or a report named in its profile)
cc_news_relevant <- function(country, event, prof) {
  if (is.null(prof)) return(rep(TRUE, length(event)))
  ct <- toupper(trimws(as.character(country %||% ""))); ev <- as.character(event %||% "")
  by_ct <- ct %in% toupper(prof$cal_countries %||% character(0)) | (isTRUE(prof$always_usd) & ct %in% toupper(cc_ccy$USD$countries))
  by_ev <- if (nzchar(prof$reports %||% "")) grepl(prof$reports, ev, ignore.case = TRUE, perl = TRUE) else rep(FALSE, length(ev))
  by_ct | (by_ev & !nzchar(ct)) | (by_ev & prof$class %in% c("energy", "agri", "metals"))
}
# the profile as a short block for the Claude API prompts
cc_profile_prompt <- function(prof, hours = NULL) {
  if (is.null(prof)) return("")
  paste0("MARKET PROFILE (", prof$class_label, ", ", prof$sub, "): ", prof$name, " (", prof$epic, ")", if (!is.na(prof$currency %||% NA)) paste0(", quoted in ", prof$currency) else "", ".\n",
    "What usually moves it: ", paste(prof$drivers, collapse = "; "), ".\n",
    "Scheduled reports that matter: ", if (nzchar(prof$reports %||% "")) gsub("\\|", ", ", prof$reports) else "none special", ".\n",
    "Sessions (UK time): ", prof$hours, if (!is.null(hours) && nzchar(hours$text %||% "")) paste0("; Capital.com: ", hours$text) else "", ".\n",
    if (length(prof$related)) paste0("Related markets to check: ", paste(prof$related, collapse = ", "), ".\n") else "",
    "Use the levels, units and news of THIS market; do not borrow facts from other asset classes.\n")
}
# exposure note for the Morning Sheet: markets of the same group move together
cc_exposure_note <- function(profiles) {
  if (!length(profiles)) return(NA_character_)
  g <- vapply(profiles, function(p) p$group %||% "Other", ""); nm <- vapply(profiles, function(p) p$name %||% p$epic, "")
  tab <- split(nm, g); multi <- tab[lengths(tab) > 1]
  parts <- c(vapply(names(multi), function(k) sprintf("%s (%s) move together: their open risk is counted together", paste(multi[[k]], collapse = ", "), k), ""),
             if (length(tab) > 1) sprintf("Groups on the watchlist: %s", paste(names(tab), collapse = "; ")) else character(0))
  if (!length(parts)) return(sprintf("%s: one group (%s); the deal ticket checks correlated open risk before each trade.", paste(nm, collapse = ", "), names(tab)[1]))
  paste0(paste(parts, collapse = ". "), ". The deal ticket checks correlated open risk before each trade.")
}

# ---- opening hours (Capital.com instrument.openingHours: {mon: ["00:00 - 21:59", ...], ..., zone: "UTC"}) -------------
cc_hours_parse <- function(oh) {
  if (is.null(oh) || !length(oh)) return(NULL)
  zone <- as.character(oh$zone %||% "UTC")[1]; if (!nzchar(zone) || toupper(zone) %in% c("GMT", "Z")) zone <- "UTC"
  if (grepl("^[+-]?[0-9]", zone)) zone <- "UTC"
  days <- c("mon", "tue", "wed", "thu", "fri", "sat", "sun")
  rows <- list()
  for (i in seq_along(days)) { v <- unlist(oh[[days[i]]] %||% list()); for (s in v) { m <- regmatches(s, gregexpr("[0-9]{1,2}:[0-9]{2}", s))[[1]]
    if (length(m) >= 2) rows[[length(rows) + 1]] <- data.frame(wday = i, from = cc_hm(m[1]), to = cc_hm(m[2]), stringsAsFactors = FALSE) } }
  if (!length(rows)) return(list(zone = zone, slots = data.frame(wday = integer(0), from = numeric(0), to = numeric(0))))
  list(zone = zone, slots = do.call(rbind, rows))
}
cc_hours_open <- function(h, now = Sys.time()) {
  if (is.null(h) || !nrow(h$slots)) return(NA)
  z <- tryCatch(as.POSIXlt(now, tz = h$zone), error = function(e) as.POSIXlt(now, tz = "UTC"))
  wd <- ifelse(z$wday == 0, 7, z$wday); m <- z$hour * 60 + z$min
  s <- h$slots[h$slots$wday == wd, , drop = FALSE]; if (!nrow(s)) return(FALSE)
  to <- ifelse(s$to <= s$from, 24 * 60, s$to)   # "23:05 - 00:00" runs to midnight
  any(m >= s$from & m <= to)
}
cc_hours_text <- function(h, now = Sys.time()) {
  if (is.null(h)) return(list(open = NA, text = "opening hours not given by Capital.com"))
  if (!nrow(h$slots)) return(list(open = FALSE, text = "no opening hours listed"))
  o <- cc_hours_open(h, now); s <- h$slots
  wk <- if (all(1:7 %in% s$wday)) "every day" else if (all(1:5 %in% s$wday) && !any(6:7 %in% s$wday)) "Monday to Friday" else paste(c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")[sort(unique(s$wday))], collapse = ", ")
  fm <- function(x) sprintf("%02d:%02d", x %/% 60, x %% 60)
  d1 <- s[s$wday == s$wday[1], , drop = FALSE]
  list(open = o, text = sprintf("%s now; %s, %s (%s time)", if (isTRUE(o)) "OPEN" else "CLOSED", wk, paste(sprintf("%s-%s", fm(d1$from), fm(d1$to)), collapse = " and "), h$zone))
}
if (!exists("cc_hm", mode = "function")) cc_hm <- function(x) { x <- if (length(x)) as.character(x[1]) else ""; m <- regmatches(x, regexpr("^[0-9]{1,2}:[0-9]{2}$", trimws(x %||% ""))); if (length(m)) as.numeric(sub(":.*", "", m)) * 60 + as.numeric(sub(".*:", "", m)) else NA }

# ---- deal size against Capital.com's rules --------------------------------------------------------------------
cc_size_problems <- function(size, min_size = NA, max_size = NA, step = NA) {
  s <- suppressWarnings(as.numeric(size)); out <- character(0)
  if (!length(s) || !is.finite(s) || s <= 0) return("Size must be above 0.")
  if (is.finite(min_size %||% NA) && s < min_size - 1e-9) out <- c(out, sprintf("Size %s is below this market's minimum %s.", format(s), format(min_size)))
  if (is.finite(max_size %||% NA) && max_size > 0 && s > max_size + 1e-9) out <- c(out, sprintf("Size %s is above this market's maximum %s.", format(s), format(max_size)))
  if (is.finite(step %||% NA) && step > 0) { k <- s / step; if (abs(k - round(k)) > 1e-6) out <- c(out, sprintf("Size must be a multiple of %s (for example %s).", format(step), format(max(round(round(k) * step, 8), step, if (is.finite(min_size %||% NA)) min_size else 0)))) }
  out
}
cc_size_fix <- function(size, min_size = NA, step = NA) {
  s <- suppressWarnings(as.numeric(size)); if (!length(s) || !is.finite(s)) return(s)
  if (is.finite(step %||% NA) && step > 0) s <- round(floor(s / step + 1e-9) * step, 8)
  if (is.finite(min_size %||% NA) && s < min_size) s <- min_size
  s
}

# ---- Capital.com market navigation: every asset class and market ------------------------------------------------
cc_nav_nodes <- function(x) { n <- x$nodes %||% list(); if (!length(n)) return(data.frame(id = character(0), name = character(0), stringsAsFactors = FALSE))
  data.frame(id = vapply(n, function(z) as.character(z$id %||% NA), ""), name = vapply(n, function(z) as.character(z$name %||% z$id %||% NA), ""), stringsAsFactors = FALSE) }
cc_nav_markets <- function(x) { m <- x$markets %||% list(); if (!length(m)) return(data.frame(epic = character(0), name = character(0), type = character(0), bid = numeric(0), offer = numeric(0), status = character(0), stringsAsFactors = FALSE))
  num <- function(v) suppressWarnings(as.numeric(v %||% NA))
  data.frame(epic = vapply(m, function(z) as.character(z$epic %||% NA), ""), name = vapply(m, function(z) as.character(z$instrumentName %||% z$name %||% z$epic %||% NA), ""),
             type = vapply(m, function(z) as.character(z$instrumentType %||% NA), ""), bid = vapply(m, function(z) num(z$bid), 0), offer = vapply(m, function(z) num(z$offer %||% z$ask), 0),
             status = vapply(m, function(z) as.character(z$marketStatus %||% NA), ""), stringsAsFactors = FALSE) }
cc_market_choices <- function(df) if (is.null(df) || !nrow(df)) c("(none)" = "") else setNames(df$epic, sprintf("%s  [%s%s]", df$name, df$epic, ifelse(is.na(df$type), "", paste0(", ", df$type))))

# ---- the watchlist: one list of markets for the whole desk (kept in cc_settings, key cc_watchlist) -----------------
cc_watch_default <- c("OIL_BRENT", "OIL_CRUDE", "NATURALGAS", "EURUSD")
cc_watch <- new.env()
cc_watch$epics <- cc_watch_default; cc_watch$info <- list(); cc_watch$v <- 0L
cc_watch_parse <- function(x) { e <- unique(toupper(trimws(unlist(strsplit(paste(x, collapse = ","), "[,; ]+"))))); e[nzchar(e) & !is.na(e)] }
cc_watch_set <- function(epics, info = NULL) { e <- cc_watch_parse(epics); if (!length(e)) e <- cc_watch_default; cc_watch$epics <- e
  if (length(info)) for (k in names(info)) cc_watch$info[[k]] <- info[[k]]; cc_watch$v <- cc_watch$v + 1L; invisible(e) }
cc_watch_get <- function() cc_watch$epics
cc_watch_info <- function(epic) cc_watch$info[[toupper(epic)]] %||% list(epic = toupper(epic), name = toupper(epic), type = NA, currency = NA)
cc_watch_profiles <- function(epics = cc_watch_get()) lapply(epics, function(e) { i <- cc_watch_info(e); cc_market_profile(e, i$name, i$type, i$currency) })

# ---- Capital.com epic -> app market code (Morning Sheet rows, Yahoo levels, labels) ------------------------------------
cc_epic_code <- function(epic, name = "") {
  e <- toupper(as.character(epic %||% "")[1]); fixed <- c(OIL_BRENT = "BRENT", OIL_CRUDE = "WTI", NATURALGAS = "NATGAS", GOLD = "GOLD", SILVER = "SILVER", COPPER = "COPPER",
    PLATINUM = "PLATINUM", US30 = "DOW", US500 = "SP500", US100 = "NASDAQ", UK100 = "FTSE100", DE40 = "GER40", J225 = "JP225")
  if (e %in% names(fixed)) return(fixed[[e]])
  if (exists("tr_catalogue")) { key <- gsub("[^A-Z0-9]", "", e); if (key %in% tr_catalogue$code) return(key)
    nm <- gsub("[^A-Z0-9]", "", toupper(name %||% "")); for (i in seq_len(nrow(tr_catalogue))) if (nzchar(nm) && grepl(tr_catalogue$pattern[i], nm)) return(tr_catalogue$code[i]) }
  e
}
# make a market known to the Morning Sheet (label, class, pip, Yahoo symbol) when it is not in the built-in list
cc_register_watch <- function(epics = cc_watch_get()) {
  if (!exists("tr_register_market", mode = "function")) return(invisible(character(0)))
  codes <- character(0)
  for (e in epics) { i <- cc_watch_info(e); cd <- cc_epic_code(e, i$name); codes <- c(codes, cd)
    if (is.null(tr_instrument(cd)) || isTRUE(tr_instrument(cd)$registered)) { p <- cc_market_profile(e, i$name, i$type, i$currency)
      tr_register_market(cd, label = if (!is.na(i$name) && nzchar(i$name) && i$name != e) i$name else e, asset_class = p$class_label, market = p$sub, yahoo = p$yahoo, epic = e) } }
  invisible(stats::setNames(codes, epics))
}

# ---- Morning Sheet levels from Capital.com candles (any market) ------------------------------------------------
# rows like tr_yahoo_morning()$rows: code, low, high, cur, time, scale, offset, prior_high/low/close, adx, prior_day, source
cc_morning_levels <- function(client, epics, day, now = Sys.time(), codes = NULL, fetch = NULL) {
  win <- tr_overnight_window(day, now); rows <- list(); problems <- character(0)
  get <- fetch %||% function(e) cc_fetch_bars(client, e, "HOUR", win$from - 6 * 86400, win$to, max_calls = 3, log = function(...) NULL)
  for (k in seq_along(epics)) { e <- epics[k]; cd <- if (!is.null(codes)) codes[[k]] else cc_epic_code(e)
    b <- tryCatch(get(e), error = function(err) { problems <<- c(problems, sprintf("%s: %s", e, conditionMessage(err))); NULL }); if (is.null(b) || !nrow(b)) next
    o <- tr_overnight_from_bars(b, win$from, win$to); if (is.null(o)) { problems <- c(problems, paste0(e, ": no candles in the overnight window (market closed?)")); next }
    k_pts <- if (exists("tr_ig_points") && !is.na(tr_ig_points[cd])) tr_ig_points[[cd]] else 1
    dg <- tr_price_digits(cd); if (k_pts == 1) dg <- max(dg, cc_dec_of(b$close)); rd <- function(v) round(v, dg)
    ud <- as.Date(format(b$time, "%Y-%m-%d", tz = "Europe/London")); prev_d <- suppressWarnings(max(ud[ud < as.Date(day)]))
    ph <- pl <- pc <- NA_real_; if (is.finite(prev_d)) { ps <- b[ud == prev_d, , drop = FALSE]; if (nrow(ps)) { ph <- max(ps$high); pl <- min(ps$low); pc <- utils::tail(ps$close, 1) } }
    hb <- b[b$time < win$to, , drop = FALSE]
    adx <- if (nrow(hb) >= 30) tryCatch({ a <- stats::na.omit(as.data.frame(TTR::ADX(cbind(hb$high, hb$low, hb$close), n = 14))); round(utils::tail(a$ADX, 1), 1) }, error = function(err) NA_real_) else NA_real_
    rows[[length(rows) + 1]] <- data.frame(code = cd, low = rd(o$low * k_pts), high = rd(o$high * k_pts), cur = rd(o$cur * k_pts), time = o$time, scale = k_pts, offset = 0,
      prior_high = rd(ph * k_pts), prior_low = rd(pl * k_pts), prior_close = rd(pc * k_pts), adx = adx, prior_day = if (is.finite(prev_d)) format(prev_d, "%a %d/%m") else NA_character_,
      source = paste0("Capital.com ", e, " hourly"), stringsAsFactors = FALSE)
  }
  list(rows = if (length(rows)) do.call(rbind, rows) else NULL, problems = problems)
}
cc_dec_of <- function(x) { x <- x[is.finite(x)]; if (!length(x)) return(2L); min(6L, max(vapply(utils::tail(x, 20), function(v) { s <- sub("0+$", "", formatC(v, format = "f", digits = 6)); if (grepl("\\.", s)) nchar(sub("^[^.]*\\.", "", s)) else 0L }, 0L))) }
# merge two level results (Yahoo first, Capital.com for the rest)
cc_merge_levels <- function(a, b) { if (is.null(b$rows)) return(a); if (is.null(a$rows)) { a$rows <- b$rows } else { k <- intersect(names(a$rows), names(b$rows))
    a$rows <- rbind(a$rows[, k, drop = FALSE], b$rows[!b$rows$code %in% a$rows$code, k, drop = FALSE]) }
  a$problems <- c(a$problems, b$problems); a }

# a deal on a closed market is refused by Capital.com: say so before sending (status first, opening hours when no status)
cc_market_closed <- function(f, now = Sys.time()) {
  st <- toupper(as.character(f$status %||% NA)[1])
  if (!is.na(st) && st == "TRADEABLE") return(character(0))
  if (!is.na(st) && st %in% c("CLOSED", "OFFLINE", "SUSPENDED", "EDIT", "ON_AUCTION", "CLOSED_FOR_DAY")) return(sprintf("%s is not tradeable now (Capital.com status %s): the deal would be refused.", f$name %||% f$epic, st))
  h <- cc_hours_text(f$hours, now); if (isFALSE(h$open)) return(sprintf("%s is closed now (%s): the deal would be refused.", f$name %||% f$epic, h$text))
  character(0)
}

# app market code -> Capital.com epic (the reverse of cc_epic_code)
cc_code_epic <- function(code) { cd <- toupper(as.character(code %||% "")[1])
  r <- if (exists("tr_market_reg")) get0(cd, envir = tr_market_reg, inherits = FALSE) else NULL; if (!is.null(r) && !is.na(r$epic %||% NA)) return(r$epic)
  fixed <- c(BRENT = "OIL_BRENT", WTI = "OIL_CRUDE", NATGAS = "NATURALGAS", DOW = "US30", SP500 = "US500", NASDAQ = "US100", FTSE100 = "UK100", GER40 = "DE40", JP225 = "J225")
  if (cd %in% names(fixed)) fixed[[cd]] else cd }
# Morning Sheet levels for any set of markets: Yahoo where it has the market, Capital.com candles for the rest (and when Yahoo fails)
cc_ms_levels <- function(codes, day, ref = numeric(0), yahoo_fetch, client = NULL, now = Sys.time(), cc_fetch = NULL) {
  codes <- unique(toupper(codes[!is.na(codes) & nzchar(codes)])); ys <- codes[!is.na(vapply(codes, tr_yahoo_sym, ""))]
  y <- if (length(ys)) tr_yahoo_morning(ys, day, now = now, ref = ref, fetch = yahoo_fetch) else list(rows = NULL, problems = character(0))
  rest <- setdiff(codes, if (is.null(y$rows)) character(0) else y$rows$code)
  if (length(rest) && (!is.null(cc_fetch) || (!is.null(client) && isTRUE(client$connected())))) {
    cy <- cc_morning_levels(client, vapply(rest, cc_code_epic, ""), day, now = now, codes = rest, fetch = cc_fetch)
    if (!is.null(cy$rows)) y$problems <- c(y$problems, sprintf("Capital.com candles used for %s.", paste(cy$rows$code, collapse = ", ")))
    y <- cc_merge_levels(y, cy)
  } else if (length(rest)) y$problems <- c(y$problems, sprintf("No price source for %s: connect Capital.com (its candles are used for markets Yahoo does not have).", paste(rest, collapse = ", ")))
  y
}
# which of my markets a calendar event concerns (for the Morning Sheet's "releases in my window")
cc_event_markets <- function(country, event, profiles) {
  if (!length(profiles)) return(rep("", length(event)))
  hit <- vapply(profiles, function(p) cc_news_relevant(country, event, p), logical(length(event)))
  if (is.null(dim(hit))) hit <- matrix(hit, nrow = length(event))
  nm <- vapply(profiles, function(p) p$name %||% p$epic, "")
  apply(hit, 1, function(r) paste(nm[r], collapse = ", "))
}
