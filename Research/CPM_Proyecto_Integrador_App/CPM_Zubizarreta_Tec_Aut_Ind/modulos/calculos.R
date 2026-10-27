# =============================================================================
# calculos.R — Ecuaciones y algoritmos de la tesis implementados en R
# Los números de ecuación y de algoritmo se refieren al documento de la tesis.
# =============================================================================

deg <- function(r) r * 180 / pi
rad <- function(d) d * pi / 180
clamp <- function(x, lo, hi) pmin(pmax(x, lo), hi)
wrap_pi <- function(a) (a + pi) %% (2 * pi) - pi            # intervalo (−π, π]
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = " ")

# ---- Constantes del vehículo (Tabla 3.9) -----------------------------------
VEH <- list(l_fis = 0.333, b_fis = 0.29, l_sw = 0.34, b_sw = 0.30, r = 0.0525,
            rho_min = 0.50, kappa_max = 2.0, v_min = 0.08, v_max = 0.20,
            s2_min = 40, s2_max = 140, u_min = 40, u_max = 100)

# ---- Capítulo 2: fundamentos eléctricos ------------------------------------
# Serie E12 para sugerir valores comerciales
E12 <- c(1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, 6.8, 8.2)
valor_comercial <- function(R) {
  if (!is.finite(R) || R <= 0) return(NA)
  dec <- 10^floor(log10(R)); serie <- c(E12 * dec, 10 * dec)
  serie[serie >= R][1]                           # siguiente valor ≥ R (corriente menor)
}
fmt_ohm <- function(R) {
  if (is.na(R)) return("—")
  if (R >= 1e6) paste0(fmt(R / 1e6, 2), " MΩ") else if (R >= 1e3) paste0(fmt(R / 1e3, 2), " kΩ")
  else paste0(fmt(R, 0), " Ω")
}

# Ec. (2.3) y (2.13): divisor y ADC
divisor_van <- function(vbat, R1 = 20e3, R2 = 10e3) vbat * R2 / (R1 + R2)
adc_cuentas <- function(van, vref = 5) clamp(round(van / vref * 1023), 0, 1023)
adc_a_vbat <- function(n, R1 = 20e3, R2 = 10e3, vref = 5) n * vref / 1023 * (R1 + R2) / R2
vbat_mv_entero <- function(n) floor(15000 * n / 1023)        # ec. (4.4)
estado_carga <- function(v) {
  if (v >= 12.7) "100 % — lista para pruebas"
  else if (v >= 12.4) "≈ 75 % — operación normal"
  else if (v >= 12.2) "≈ 50 % — terminar la sesión y cargar"
  else if (v > 11.9) "entre 25 % y 50 % — cargar pronto"
  else "< 25 % — no usar"
}

# Ec. (2.8): convertidor reductor
buck <- function(vin, vout, fs, L, C) {
  D <- vout / vin
  dIL <- (vin - vout) * D / (L * fs)
  dV <- dIL / (8 * fs * C)
  list(D = D, dIL = dIL, dV = dV)
}

# Ec. (2.11): velocidad serie del PIC (BRGH = 1 → divisor 16; BRGH = 0 → 64)
baud_pic <- function(B, fosc = 4e6, brgh = 1) {
  div <- if (brgh == 1) 16 else 64
  spbrg <- clamp(round(fosc / (div * B) - 1), 0, 255)
  real <- fosc / (div * (spbrg + 1))
  list(spbrg = spbrg, ideal = fosc / (div * B) - 1, real = real, err = (real - B) / B * 100)
}
# ATmega con U2X = 1 (modo de doble velocidad de la biblioteca Serial)
baud_avr <- function(B, fosc = 16e6) {
  ubrr <- clamp(round(fosc / (8 * B) - 1), 0, 4095)
  real <- fosc / (8 * (ubrr + 1))
  list(ubrr = ubrr, real = real, err = (real - B) / B * 100)
}

# Ec. (2.17): resistencias de pull-up del bus I2C
pullup_i2c <- function(vdd = 5, vol = 0.4, iol = 3e-3, tr = 1000e-9, cb = 200e-12) {
  list(rmin = (vdd - vol) / iol, rmax = tr / (0.8473 * cb))
}

# Ec. (2.15) y (3.5): codificador óptico
encoder_ds <- function(r = 0.0525, nenc = 400, kg = 0.625) 2 * pi * r / (nenc * kg)

# Ec. (2.19) y (2.20): Ackermann y diferencial
delta_de_rho <- function(rho, l = VEH$l_sw) atan(l / rho)
diferencial <- function(rho, b = VEH$b_sw, lambda = 1) {
  list(ext = 1 + lambda * b / (2 * rho), int = 1 - lambda * b / (2 * rho))
}

# Ec. (2.21): curvatura de Menger con signo (positivo = giro a la izquierda)
# Coordenadas (x, z); ψ medido desde +z hacia +x; el giro a la izquierda aumenta ψ.
menger <- function(A, B, C) {
  ab <- B - A; ac <- C - A
  cruz <- ab[2] * ac[1] - ab[1] * ac[2]          # signo positivo = izquierda en este marco
  area <- 0.5 * cruz
  den <- sqrt(sum(ab^2)) * sqrt(sum((C - B)^2)) * sqrt(sum(ac^2))
  if (den < 1e-12) return(0)
  4 * area / den
}

# Ec. (6.7): ganancia de Kalman en régimen permanente
kalman_estacionario <- function(sq, sr, f = 72) {
  P <- (sq + sqrt(sq^2 + 4 * sq * sr)) / 2
  K <- P / (P + sr)
  Nt <- -1 / log(1 - K)
  list(P = P, K = K, Nt = Nt, t = Nt / f)
}

# ---- Capítulo 4 --------------------------------------------------------------
timer0_periodo <- function(tmr0, npre, fosc = 4e6) (256 - tmr0) * 4 * npre / fosc
pwm_periodo <- function(pr2, npre2, fosc = 4e6) (pr2 + 1) * 4 * npre2 / fosc
md22_registro <- function(u) round(128 + 127 * u / 100)       # ec. (4.6), modo 0
servo_tp <- function(theta) 1000 + 1000 * theta / 180          # ec. (4.10), µs

# Trama 8N1 de un carácter, bit menos significativo primero (Figura 4.2)
trama_8n1 <- function(ch, baud = 9600) {
  code <- utf8ToInt(substr(ch, 1, 1))
  if (length(code) == 0 || is.na(code)) code <- 65L
  code <- code %% 256
  bits <- c(0, as.integer(intToBits(code))[1:8], 1)
  list(code = code, bits = bits, tbit = 1 / baud,
       etiquetas = c("Inicio", paste0("b", 0:7), "Paro"))
}

# ---- Capítulo 5: firmware de actuadores y seguridad -------------------------
# Suma de verificación XOR (ec. 2.12) entre '$' y '*'
xor_checksum <- function(cuerpo) {
  b <- utf8ToInt(cuerpo)
  if (length(b) == 0) return("00")
  cs <- 0L
  for (v in b) cs <- bitwXor(cs, v)
  sprintf("%02X", cs)
}

# Intérprete de comandos.
# modo = "D7"  → firmware vigente (Listado D.7): rechaza la trama fuera de rango.
# modo = "N5"  → programa de referencia N5: satura según la ec. (5.1).
interpretar_comando <- function(linea, modo = "D7", estado = list(M1 = 0, M2 = 0, S1 = 90, S2 = 90)) {
  linea <- toupper(trimws(linea))
  ok_motor <- function(v) is.finite(v) && (v == 0 || (v >= 40 && v <= 100))
  ok_servo <- function(v) is.finite(v) && v >= 40 && v <= 140
  sat_motor <- function(u) if (u == 0) 0 else sign(u) * min(max(abs(u), 40), 100)
  resp <- function(e) sprintf("OK:M1:%d:M2:%d:S1:%d:S2:%d", e$M1, e$M2, e$S1, e$S2)
  num <- function(x) suppressWarnings(as.numeric(x))
  if (linea == "") return(list(resp = "ERR:EMPTY", estado = estado, valido = FALSE))
  if (linea == "PING") return(list(resp = "PONG", estado = estado, valido = TRUE))
  if (linea == "STATUS") return(list(resp = paste0("STATUS ", resp(estado)), estado = estado, valido = TRUE))
  if (linea %in% c("STOP_ALL_MOTORS", "STOP")) {
    estado$M1 <- 0; estado$M2 <- 0
    return(list(resp = "OK:STOP", estado = estado, valido = TRUE))
  }
  if (startsWith(linea, "ALL:")) {
    p <- strsplit(linea, ":", fixed = TRUE)[[1]]
    if (length(p) != 9 || !identical(p[c(2, 4, 6, 8)], c("M1", "M2", "S1", "S2")))
      return(list(resp = "ERR:FORMAT", estado = estado, valido = FALSE))
    v <- num(p[c(3, 5, 7, 9)])
    if (any(is.na(v))) return(list(resp = "ERR:FORMAT", estado = estado, valido = FALSE))
    if (modo == "D7") {
      malos <- c(!ok_motor(v[1]), !ok_motor(v[2]), !ok_servo(v[3]), !ok_servo(v[4]))
      if (any(malos)) {
        campos <- c("M1", "M2", "S1", "S2")[malos]
        return(list(resp = paste0("ERR:RANGE:", paste(campos, collapse = ",")), estado = estado, valido = FALSE))
      }
      estado[c("M1", "M2", "S1", "S2")] <- as.list(as.integer(v))
    } else {
      estado$M1 <- as.integer(sat_motor(v[1])); estado$M2 <- as.integer(sat_motor(v[2]))
      estado$S1 <- as.integer(clamp(v[3], 0, 180)); estado$S2 <- as.integer(clamp(v[4], 40, 140))
    }
    return(list(resp = resp(estado), estado = estado, valido = TRUE))
  }
  m <- regmatches(linea, regexec("^(MOTORS|MOTOR1|MOTOR2|SERVO1|SERVO2):(-?[0-9.]+)$", linea))[[1]]
  if (length(m) == 3) {
    v <- num(m[3]); cmd <- m[2]
    if (startsWith(cmd, "MOTOR")) {
      if (modo == "D7" && !ok_motor(v)) return(list(resp = paste0("ERR:RANGE:", cmd), estado = estado, valido = FALSE))
      v <- if (modo == "D7") v else sat_motor(v)
      if (cmd %in% c("MOTORS", "MOTOR1")) estado$M1 <- as.integer(v)
      if (cmd %in% c("MOTORS", "MOTOR2")) estado$M2 <- as.integer(v)
    } else {
      if (modo == "D7" && !ok_servo(v)) return(list(resp = paste0("ERR:RANGE:", cmd), estado = estado, valido = FALSE))
      v <- if (modo == "D7") v else clamp(v, 40, 140)
      if (cmd == "SERVO1") estado$S1 <- as.integer(v) else estado$S2 <- as.integer(v)
    }
    return(list(resp = resp(estado), estado = estado, valido = TRUE))
  }
  list(resp = "ERR:UNKNOWN", estado = estado, valido = FALSE)
}

# Algoritmo 2: filtro de seguridad de la Jetson
filtro_seguridad <- function(paro, t_sen, vbat, temp, dist = Inf) {
  if (paro) return("paro de emergencia")
  if (t_sen > 1) return("sin datos del nodo de sensores")
  if (vbat < 11.8) return("batería baja")
  if (temp > 60) return("temperatura alta")
  if (dist < 0.30) return("obstáculo a menos de 30 cm")
  ""
}

# Ec. (5.4): resistencia de base del transistor del relevador
rb_relevador <- function(ic = 0.070, hfe = 100, sat = 3, voh = 5, vbe = 0.7) {
  ib <- sat * ic / hfe
  list(ib = ib, rb = (voh - vbe) / ib)
}

# Lazo PID de velocidad propuesto (ec. 5.5) sobre un motor de primer orden.
# Simulación ilustrativa: la planta es un modelo genérico, no una medición.
sim_pid <- function(kp, ki, kd, T = 0.05, vref = 0.14, tau = 0.25, kmot = 0.0021,
                    carga_t = 3, carga = 0.03, tfin = 6) {
  n <- round(tfin / T); v <- numeric(n); u <- numeric(n); e_prev <- 0; integ <- 0
  dt_int <- 0.005; pasos <- round(T / dt_int); vel <- 0
  for (k in 1:n) {
    t <- (k - 1) * T
    e <- vref - vel
    integ_tent <- integ + e * T
    uk <- kp * e + ki * integ_tent + kd * (e - e_prev) / T
    if (uk > 100 || uk < 0) { uk <- clamp(uk, 0, 100) } else integ <- integ_tent   # anti-acumulación
    u[k] <- uk; e_prev <- e
    for (j in 1:pasos) {
      perturb <- if (t >= carga_t) carga else 0
      vel <- vel + dt_int / tau * (kmot * uk - perturb - vel)
    }
    v[k] <- vel
  }
  data.frame(t = (0:(n - 1)) * T, v = v, u = u, vref = vref)
}

# ---- Capítulo 6: proyección del mapa (ecs. 6.2 y 6.3) ----------------------
cargar_geojson <- function(ruta) jsonlite::fromJSON(ruta, simplifyVector = FALSE)

proyectar_lonlat <- function(lon, lat, S = 1) {
  lam0 <- 0.000045; phi0 <- 0.000125; rango <- 0.0037
  x <- (lon - lam0) / rango * 4.2 * S
  mz <- (lat - phi0) / rango * 2.1 * S              # −z (norte positivo)
  # Ec. (6.3): el mapa crece hacia los lados y hacia el usuario
  mz <- mz - (S - 1) * 1.05
  list(x = x, z = -mz)
}

geo_a_capas <- function(geo, S = 1) {
  lineas <- list(); puntos <- list(); zona <- NULL
  for (f in geo$features) {
    g <- f$geometry; nm <- f$properties$name
    if (g$type == "LineString") {
      m <- do.call(rbind, lapply(g$coordinates, function(p) unlist(p)))
      pr <- proyectar_lonlat(m[, 1], m[, 2], S)
      lineas[[length(lineas) + 1]] <- data.frame(x = pr$x, z = pr$z, nombre = nm, id = f$id,
                                                tipo = f$properties$type, stringsAsFactors = FALSE)
    } else if (g$type == "Polygon") {
      m <- do.call(rbind, lapply(g$coordinates[[1]], function(p) unlist(p)))
      pr <- proyectar_lonlat(m[, 1], m[, 2], S)
      zona <- data.frame(x = pr$x, z = pr$z, nombre = nm)
    } else if (g$type == "Point") {
      p <- unlist(g$coordinates); pr <- proyectar_lonlat(p[1], p[2], S)
      puntos[[length(puntos) + 1]] <- data.frame(x = pr$x, z = pr$z, nombre = nm,
                                                prioridad = f$properties$priority, stringsAsFactors = FALSE)
    }
  }
  list(lineas = do.call(rbind, lineas), puntos = do.call(rbind, puntos), zona = zona)
}

anillo_m25 <- function(geo, S = 1.1) {
  for (f in geo$features) if (identical(f$id, "m25_orbital")) {
    m <- do.call(rbind, lapply(f$geometry$coordinates, function(p) unlist(p)))
    pr <- proyectar_lonlat(m[, 1], m[, 2], S)
    return(cbind(x = pr$x, z = pr$z))
  }
  NULL
}

# ---- Utilidades de trayectorias ---------------------------------------------
longitudes <- function(P) c(0, cumsum(sqrt(rowSums(diff(P)^2))))

quitar_duplicados <- function(P, tol = 1e-6) {
  if (nrow(P) < 2) return(P)
  keep <- c(TRUE, sqrt(rowSums(diff(P)^2)) > tol)
  P[keep, , drop = FALSE]
}

remuestrear <- function(P, ds) {
  P <- quitar_duplicados(P)
  if (nrow(P) < 2) return(P)
  s <- longitudes(P); L <- max(s)
  if (L < ds) return(P[c(1, nrow(P)), , drop = FALSE])
  si <- seq(0, L, by = ds)
  if (L - tail(si, 1) > ds * 0.25) si <- c(si, L)
  cbind(x = approx(s, P[, 1], si)$y, z = approx(s, P[, 2], si)$y)
}

# Conserva solo puntos separados al menos d (ec. 6.4)
adelgazar <- function(P, d) {
  P <- quitar_duplicados(P)
  if (nrow(P) < 3) return(P)
  keep <- 1; ult <- P[1, ]
  for (i in 2:(nrow(P) - 1)) {
    if (sqrt(sum((P[i, ] - ult)^2)) >= d) { keep <- c(keep, i); ult <- P[i, ] }
  }
  # el último punto se conserva; si queda muy cerca del penúltimo conservado, lo sustituye
  if (length(keep) > 1 && sqrt(sum((P[nrow(P), ] - P[tail(keep, 1), ])^2)) < d / 2) keep <- keep[-length(keep)]
  P[c(keep, nrow(P)), , drop = FALSE]
}

es_cerrada <- function(P) {
  L <- max(longitudes(P))
  sqrt(sum((P[1, ] - P[nrow(P), ])^2)) < max(0.05 * L, 0.05)
}

# SPLINE (smooth): Catmull-Rom (ec. 6.5), 20 muestras por segmento
catmull_rom <- function(P, n = 20, cerrada = FALSE) {
  m <- nrow(P)
  if (m < 3) return(P)
  if (cerrada) {
    if (sqrt(sum((P[1, ] - P[m, ])^2)) < 1e-6) { P <- P[-m, , drop = FALSE]; m <- m - 1 }
    idx <- function(i) ((i - 1) %% m) + 1
    segs <- 1:m
  } else {
    P <- rbind(2 * P[1, ] - P[2, ], P, 2 * P[m, ] - P[m - 1, ])
    idx <- function(i) i
    segs <- 2:(m)
  }
  u <- seq(0, 1, length.out = n + 1)[-(n + 1)]
  out <- NULL
  for (s in segs) {
    if (cerrada) { p0 <- P[idx(s - 1), ]; p1 <- P[idx(s), ]; p2 <- P[idx(s + 1), ]; p3 <- P[idx(s + 2), ] }
    else { p0 <- P[s - 1, ]; p1 <- P[s, ]; p2 <- P[s + 1, ]; p3 <- P[s + 2, ] }
    for (uu in u) {
      c <- 0.5 * (2 * p1 + (p2 - p0) * uu + (2 * p0 - 5 * p1 + 4 * p2 - p3) * uu^2 + (3 * p1 - p0 - 3 * p2 + p3) * uu^3)
      out <- rbind(out, c)
    }
  }
  out <- if (cerrada) rbind(out, out[1, ]) else rbind(out, P[nrow(P) - 1, ])
  colnames(out) <- c("x", "z"); rownames(out) <- NULL
  out
}

# Curvatura discreta (ec. 6.6) y filtro por radio
curvatura_discreta <- function(P) {
  n <- nrow(P); k <- rep(0, n)
  if (n < 3) return(k)
  for (i in 2:(n - 1)) {
    a <- P[i, ] - P[i - 1, ]; b <- P[i + 1, ] - P[i, ]
    s1 <- sqrt(sum(a^2)); s2 <- sqrt(sum(b^2))
    if (s1 < 1e-9 || s2 < 1e-9) next
    d1 <- a / s1; d2 <- b / s2
    k[i] <- abs(d1[1] * d2[2] - d1[2] * d2[1]) / ((s1 + s2) / 2)
  }
  k
}
filtro_radio <- function(P, R) {
  k <- curvatura_discreta(P)
  keep <- k == 0 | (1 / pmax(k, 1e-12)) >= 0.8 * R
  keep[c(1, length(keep))] <- TRUE
  P2 <- P[keep, , drop = FALSE]
  if (nrow(P2) > 4) P2 <- P2[c(seq(1, nrow(P2) - 1, by = 2), nrow(P2)), , drop = FALSE]   # diezmado 2:1
  P2
}

# Algoritmo 4 — versión final (abril 2026)
suavizar_spline <- function(P, R, filtro = FALSE) {
  cerr <- es_cerrada(P)
  Q <- adelgazar(P, 2 * R)
  if (cerr && sqrt(sum((Q[1, ] - Q[nrow(Q), ])^2)) > 1e-6) Q <- rbind(Q, Q[1, ])
  if (nrow(Q) < 3) return(remuestrear(P, 0.05))
  C <- catmull_rom(Q, 20, cerrada = cerr)
  if (filtro) C <- filtro_radio(C, R)
  C
}

suavizar_arc <- function(P, R, paso = 2.5) {
  cerr <- es_cerrada(P)
  Q <- adelgazar(P, paso * R)
  if (cerr) { if (sqrt(sum((Q[1, ] - Q[nrow(Q), ])^2)) < 1e-6) Q <- Q[-nrow(Q), , drop = FALSE] }
  m <- nrow(Q)
  if (m < 3) return(remuestrear(P, 0.05))
  esquina <- function(pa, pv, pb) {
    a <- pv - pa; b <- pb - pv; la <- sqrt(sum(a^2)); lb <- sqrt(sum(b^2))
    if (la < 1e-9 || lb < 1e-9) return(matrix(pv, 1))
    ah <- a / la; bh <- b / lb
    cosang <- clamp(sum(ah * bh), -1, 1); theta <- acos(cosang)
    if (theta < 1e-3) return(matrix(pv, 1))
    Tt <- min(R * tan(theta / 2), 0.45 * min(la, lb))
    S <- pv - Tt * ah; E <- pv + Tt * bh
    u <- seq(0, 1, length.out = 13)
    t(sapply(u, function(t) (1 - t)^2 * S + 2 * (1 - t) * t * pv + t^2 * E))
  }
  out <- NULL
  if (cerr) {
    for (i in 1:m) {
      pa <- Q[ifelse(i == 1, m, i - 1), ]; pv <- Q[i, ]; pb <- Q[ifelse(i == m, 1, i + 1), ]
      out <- rbind(out, esquina(pa, pv, pb))
    }
    out <- rbind(out, out[1, ])
  } else {
    out <- matrix(Q[1, ], 1)
    for (i in 2:(m - 1)) out <- rbind(out, esquina(Q[i - 1, ], Q[i, ], Q[i + 1, ]))
    out <- rbind(out, Q[m, ])
  }
  colnames(out) <- c("x", "z")
  quitar_duplicados(out)
}

puntos_de_paso <- function(verde, ds = 0.20) {
  W <- remuestrear(verde, ds)
  n <- nrow(W)
  psi <- c(atan2(diff(W[, 1]), diff(W[, 2])), NA)                 # ec. (7.1)
  psi[n] <- psi[n - 1]
  data.frame(i = 0:(n - 1), x = W[, 1], z = W[, 2], psi = psi)
}

# Trayectorias de la campaña C4 y figuras de prueba (en metros; inicio en el origen
# con el vehículo mirando al norte, −z)
trayectoria_predefinida <- function(tipo) {
  a <- seq(0, pi, length.out = 70)
  t <- switch(tipo,
    recta = cbind(0, -seq(0, 2, by = 0.05)),
    arco  = cbind(1 - cos(a), -sin(a)),                                   # semicírculo de 1 m de radio
    ese   = rbind(cbind(0.75 - 0.75 * cos(a), -0.75 * sin(a)),             # "S": dos semicírculos de 0.75 m
                  cbind(2.25 - 0.75 * cos(a), 0.75 * sin(a))[-1, ]),
    ocho  = { b <- seq(0, 2 * pi, length.out = 120)                        # ocho: dos círculos de 0.75 m
              rbind(cbind(0.75 - 0.75 * cos(b), -0.75 * sin(b)),
                    cbind(-0.75 + 0.75 * cos(b), -0.75 * sin(b))[-1, ]) },
    cbind(0, -seq(0, 2, by = 0.05)))
  t <- quitar_duplicados(t)
  # centrar en la rejilla de trabajo de 2.1 × 2.1 m
  t[, 1] <- t[, 1] - mean(range(t[, 1])); t[, 2] <- t[, 2] - mean(range(t[, 2]))
  colnames(t) <- c("x", "z")
  t
}

# ---- Capítulo 7: generador de comandos (Algoritmo 5) ------------------------
generador_ackermann <- function(W, lambda = 0.25, ks = 40 / 30, l = VEH$l_sw, b = VEH$b_sw, vbar = 0.13) {
  n <- nrow(W)
  if (n < 3) return(NULL)
  s <- longitudes(as.matrix(W[, c("x", "z")])); L <- max(s)
  filas <- lapply(2:(n - 1), function(i) {
    k <- menger(c(W$x[i - 1], W$z[i - 1]), c(W$x[i], W$z[i]), c(W$x[i + 1], W$z[i + 1]))
    ksat <- sign(k) * min(abs(k), VEH$kappa_max)                     # ec. (7.2)
    delta <- atan(l * ksat)                                          # ec. (2.19)
    theta <- clamp(90 + ks * deg(delta), 40, 140)                     # ec. (7.3)
    rest <- L - s[i]
    v <- clamp(min(vbar, VEH$v_min + rest * 0.25), VEH$v_min, VEH$v_max)   # perfil según distancia restante
    dif <- lambda * b * abs(ksat) / 2                                 # ec. (7.4)
    v_ext <- v * (1 + dif); v_int <- v * (1 - dif)
    # izquierda (κ > 0): rueda interior = izquierda = M1
    v_izq <- if (ksat > 0) v_int else v_ext
    v_der <- if (ksat > 0) v_ext else v_int
    if (ksat == 0) { v_izq <- v; v_der <- v }
    u <- function(vv) round(clamp(VEH$u_min + (VEH$u_max - VEH$u_min) * (vv - VEH$v_min) / (VEH$v_max - VEH$v_min),
                                  VEH$u_min, VEH$u_max))                 # ec. (7.5)
    data.frame(i = i - 1, s = s[i], kappa = k, kappa_sat = ksat, delta = deg(delta), theta = round(theta),
               v = v, u1 = u(v_izq), u2 = u(v_der))
  })
  out <- do.call(rbind, filas)
  out$trama <- sprintf("ALL:M1:%d:M2:%d:S1:90:S2:%d", out$u1, out$u2, as.integer(out$theta))
  out
}

# ---- Estimador de pose (Algoritmo 6) ----------------------------------------
kalman1 <- function(x0, P0 = 1) list(x = x0, P = P0)
kalman_paso <- function(f, z, sq, sr) {
  Pm <- f$P + sq; K <- Pm / (Pm + sr)
  list(x = f$x + K * (z - f$x), P = (1 - K) * Pm)
}

# ---- Simulador del seguimiento (ilustrativo) --------------------------------
# Modelo de bicicleta (ec. 2.18) integrado a 72 Hz; pose medida con ruido y
# eventos opcionales de pérdida de rastreo; estimador con compuerta y Kalman;
# lazo de control a 5 Hz con la ley del modo 5 (ec. 7.6) o con el generador
# de curvatura del Algoritmo 5.
simular_seguimiento <- function(W, verde, cfg) {
  dt <- 1 / 72; Tc <- 0.2
  verde <- remuestrear(as.matrix(verde), 0.02)                      # densificar para medir la desviación
  l_real <- VEH$l_fis
  n_wp <- nrow(W)
  # pose inicial: en el primer punto, alineado con el primer tramo, con desplazamiento lateral
  psi0 <- W$psi[1]
  x <- W$x[1] + cfg$offset * cos(psi0); z <- W$z[1] - cfg$offset * sin(psi0); psi <- psi0
  fx <- kalman1(x); fz <- kalman1(z); fp <- kalman1(psi)
  delta_real <- 0; theta_cmd <- 90; theta_srv <- 90; u1 <- 0; u2 <- 0
  i_act <- 2; t <- 0; t_ctrl <- 0; rechazos <- 0; t_rech <- 0
  set.seed(cfg$semilla)
  # eventos de pérdida de rastreo
  eventos <- NULL
  if (cfg$perdidas > 0) {
    nev <- cfg$perdidas
    t_ev <- sort(runif(nev, 8, cfg$tmax - 10))
    ang <- runif(nev, 0, 2 * pi)
    eventos <- data.frame(t0 = t_ev, t1 = t_ev + cfg$dur_perdida, dx = cfg$salto * sin(ang), dz = cfg$salto * cos(ang))
  }
  L_total <- max(longitudes(as.matrix(W[, c("x", "z")])))
  s_wp <- longitudes(as.matrix(W[, c("x", "z")]))
  reg <- vector("list", ceiling(cfg$tmax / Tc) + 5); nreg <- 0
  traza <- vector("list", ceiling(cfg$tmax / dt) + 5); ntr <- 0
  fin <- "Tiempo máximo (2 min)"
  ks_c <- cfg$ks_ctrl; ks_r <- cfg$ks_real
  s_verde <- longitudes(verde); j_cerca <- 1
  if (is.null(cfg$d_la)) cfg$d_la <- 0.35
  vel_servo <- 60 / 0.14                                              # °/s (0.14 s por 60°)
  while (t < cfg$tmax) {
    # ---- medición (control izquierdo del visor) ----
    mx <- x + rnorm(1, 0, cfg$ruido_pos); mz <- z + rnorm(1, 0, cfg$ruido_pos)
    mpsi <- psi + rnorm(1, 0, rad(cfg$ruido_rumbo))
    if (!is.null(eventos)) {
      act <- which(t >= eventos$t0 & t <= eventos$t1)
      if (length(act)) { mx <- mx + eventos$dx[act[1]]; mz <- mz + eventos$dz[act[1]] }
    }
    # ---- estimador: desenvolver, compuerta, Kalman ----
    mpsi_u <- mpsi - 2 * pi * round((mpsi - fp$x) / (2 * pi))         # ec. (7.8)
    rechazar <- FALSE
    if (cfg$compuerta) {
      if (sqrt((mx - fx$x)^2 + (mz - fz$x)^2) > cfg$dp_max || abs(mpsi_u - fp$x) > rad(cfg$dpsi_max)) rechazar <- TRUE
    }
    if (rechazar) {
      t_rech <- t_rech + dt
      if (t_rech >= cfg$t_confirma) {      # confirmación: el salto persiste, se acepta la medición
        fx <- kalman1(mx, 0.01); fz <- kalman1(mz, 0.01); fp <- kalman1(mpsi_u, 0.01); t_rech <- 0
      }
    } else {
      t_rech <- 0
      fx <- kalman_paso(fx, mx, cfg$sq_pos, cfg$sr_pos); fz <- kalman_paso(fz, mz, cfg$sq_pos, cfg$sr_pos)
      fp <- kalman_paso(fp, mpsi_u, cfg$sq_psi, cfg$sr_psi)
    }
    # ---- lazo de control a 5 Hz ----
    if (t + 1e-9 >= t_ctrl) {
      t_ctrl <- t_ctrl + Tc
      xe <- fx$x; ze <- fz$x; pe <- fp$x
      # avance del punto de paso activo
      pasado <- function(j) {             # el vehículo ya rebasó el punto j a lo largo de su tramo
        if (j >= n_wp) return(FALSE)
        tx <- W$x[j + 1] - W$x[j]; tz <- W$z[j + 1] - W$z[j]
        ((xe - W$x[j]) * tx + (ze - W$z[j]) * tz) > 0 && sqrt((W$x[j] - xe)^2 + (W$z[j] - ze)^2) < 3 * cfg$r_acept
      }
      while (i_act < n_wp && (sqrt((W$x[i_act] - xe)^2 + (W$z[i_act] - ze)^2) < cfg$r_acept || pasado(i_act))) {
        if (i_act == n_wp - 1 && s_wp[i_act] < 0.8 * L_total) break
        i_act <- i_act + 1
      }
      d_act <- sqrt((W$x[i_act] - xe)^2 + (W$z[i_act] - ze)^2)
      ult <- i_act >= n_wp && d_act < cfg$r_acept
      # error lateral con signo respecto al tramo (i−1 → i); positivo a la izquierda
      ax <- W$x[i_act - 1]; az <- W$z[i_act - 1]; bx <- W$x[i_act]; bz <- W$z[i_act]
      dx <- bx - ax; dz <- bz - az; Ls <- max(sqrt(dx^2 + dz^2), 1e-9)
      e_lat <- (dz * (xe - ax) - dx * (ze - az)) / Ls
      psi_obj <- atan2(bx - xe, bz - ze)
      e_psi <- wrap_pi(W$psi[i_act] - pe)
      if (cfg$ley == "modo5") {
        termino_rumbo <- clamp(wrap_pi(psi_obj - pe), rad(-30), rad(30))
        lateral <- clamp(atan(2 * e_lat / 0.5), rad(-15), rad(15))
        delta_c <- clamp(termino_rumbo - lateral, rad(-30), rad(30))
        if (abs(e_lat) > 0.12) delta_c <- -sign(e_lat) * rad(30)       # maniobra de recuperación
        f <- abs(deg(delta_c)) / 30
        v_ext <- 85 + 15 * f; v_int <- 85 - 35 * f
        if (abs(delta_c) < rad(1)) { u1 <- 85; u2 <- 85 }
        else if (delta_c > 0) { u1 <- v_int; u2 <- v_ext } else { u1 <- v_ext; u2 <- v_int }
        kappa_ref <- NA
      } else if (cfg$ley == "pp") {
        # Persecución pura (ec. 2.22): punto objetivo a d_la sobre la trayectoria verde
        dmin <- (verde[, 1] - xe)^2 + (verde[, 2] - ze)^2
        rango <- max(1, j_cerca - 5):min(nrow(verde), j_cerca + 60)
        j_cerca <- rango[which.min(dmin[rango])]
        s_obj <- s_verde[j_cerca] + cfg$d_la
        j_obj <- which(s_verde >= s_obj)[1]; if (is.na(j_obj)) j_obj <- nrow(verde)
        alfa <- wrap_pi(atan2(verde[j_obj, 1] - xe, verde[j_obj, 2] - ze) - pe)
        delta_c <- clamp(atan(2 * VEH$l_sw * sin(alfa) / cfg$d_la), rad(-30), rad(30))
        f <- abs(deg(delta_c)) / 30
        v_ext <- 85 + 15 * f; v_int <- 85 - 35 * f
        if (abs(delta_c) < rad(1)) { u1 <- 85; u2 <- 85 }
        else if (delta_c > 0) { u1 <- v_int; u2 <- v_ext } else { u1 <- v_ext; u2 <- v_int }
        kappa_ref <- NA
      } else {
        i_c <- clamp(i_act, 2, n_wp - 1)
        k <- menger(c(W$x[i_c - 1], W$z[i_c - 1]), c(W$x[i_c], W$z[i_c]), c(W$x[i_c + 1], W$z[i_c + 1]))
        ksat <- sign(k) * min(abs(k), VEH$kappa_max)
        delta_c <- atan(VEH$l_sw * ksat)
        rest <- L_total - s_wp[i_act]
        v <- clamp(min(0.13, VEH$v_min + rest * 0.25), VEH$v_min, VEH$v_max)
        dif <- cfg$lambda * VEH$b_sw * abs(ksat) / 2
        vi <- v * (1 - dif); ve <- v * (1 + dif)
        uu <- function(vv) clamp(40 + 60 * (vv - 0.08) / 0.12, 40, 100)
        if (ksat > 0) { u1 <- uu(vi); u2 <- uu(ve) } else if (ksat < 0) { u1 <- uu(ve); u2 <- uu(vi) } else { u1 <- uu(v); u2 <- uu(v) }
        kappa_ref <- k
      }
      theta_cmd <- clamp(90 + ks_c * deg(delta_c), 40, 140)
      u1 <- round(u1); u2 <- round(u2)
      if (ult) { u1 <- 0; u2 <- 0; theta_cmd <- 90 }
      # desviación real: distancia de la pose verdadera a la trayectoria verde
      dv <- sqrt(min((verde[, 1] - x)^2 + (verde[, 2] - z)^2))
      nreg <- nreg + 1
      reg[[nreg]] <- data.frame(t = round(t, 3), i = i_act - 1, xi = W$x[i_act], zi = W$z[i_act],
                                x_hat = xe, z_hat = ze, psi_hat = pe,
                                ep = d_act, ect = e_lat, epsi = e_psi,
                                kappa = ifelse(is.na(kappa_ref),
                                               menger(c(W$x[max(1, i_act - 1)], W$z[max(1, i_act - 1)]),
                                                      c(W$x[i_act], W$z[i_act]),
                                                      c(W$x[min(n_wp, i_act + 1)], W$z[min(n_wp, i_act + 1)])), kappa_ref),
                                delta = deg(delta_c), theta_s = round(theta_cmd), u1 = u1, u2 = u2,
                                Vbat = round(12.6 - 0.0025 * t, 3), T = round(28 + 0.03 * t, 2),
                                x_real = x, z_real = z, desv_real = dv)
      if (ult) { fin <- "Vuelta completa: último punto de paso alcanzado"; break }
      if (d_act > 0.80) { fin <- "Abortada: punto de paso activo a más de 80 cm"; break }
    }
    # ---- servo con velocidad limitada y varillaje (ks real) ----
    paso_s <- vel_servo * dt
    theta_srv <- theta_srv + clamp(theta_cmd - theta_srv, -paso_s, paso_s)
    delta_real <- clamp(rad((theta_srv - 90) / ks_r), rad(-30), rad(30))
    # ---- planta: velocidades de rueda y modelo de bicicleta ----
    vL <- cfg$v85 * u1 / 85; vR <- cfg$v85 * u2 / 85; v <- (vL + vR) / 2
    w_dir <- v / l_real * tan(delta_real)
    w_dif <- (vR - vL) / VEH$b_fis
    w <- (1 - cfg$part_dif) * w_dir + cfg$part_dif * w_dif
    # sentido: vR > vL produce giro a la izquierda (ψ creciente)
    x <- x + v * sin(psi) * dt; z <- z + v * cos(psi) * dt; psi <- psi + w * dt
    ntr <- ntr + 1
    traza[[ntr]] <- c(t, x, z, mx, mz, fx$x, fz$x, deg(psi), deg(mpsi), deg(fp$x), rechazar)
    t <- t + dt
  }
  log <- do.call(rbind, reg[seq_len(nreg)])
  tr <- as.data.frame(do.call(rbind, traza[seq_len(ntr)]))
  names(tr) <- c("t", "x", "z", "mx", "mz", "fx", "fz", "psi", "mpsi", "fpsi", "rechazo")
  list(log = log, traza = tr, fin = fin, n_wp = n_wp, i_final = if (nreg) tail(log$i, 1) else 0)
}

clasificar_desviacion <- function(m_cm) {
  if (!is.finite(m_cm)) return("—")
  if (m_cm < 8) "Baja, aceptable" else if (m_cm <= 15) "Moderada" else "Alta"
}
recomendacion_desviacion <- function(m_cm) {
  if (!is.finite(m_cm)) return("—")
  if (m_cm < 8) "Ajuste fino opcional"
  else if (m_cm <= 15) "Afinar la velocidad, la respuesta del servo y la compensación anticipativa"
  else "Revisar calibración de motores, geometría Ackermann, ganancias y deslizamiento"
}
