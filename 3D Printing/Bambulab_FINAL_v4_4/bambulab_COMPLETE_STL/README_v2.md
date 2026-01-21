# 🚀 BAMBULAB A1 COMBO - DASHBOARD COMPLETO v2.0

## Control Total + Visualización 3D Real (STL/OBJ)

**Versión:** 2.0 - Complete Edition  
**Fecha:** 30 de Diciembre de 2025  
**Estado:** ✅ PRODUCCIÓN

---

## ✨ CARACTERÍSTICAS COMPLETAS

### 📡 Control de Impresora (MQTT)
- ✅ Conexión WiFi/LAN via MQTT
- ✅ Start/Pause/Stop/Resume prints
- ✅ Control de temperatura (nozzle, bed)
- ✅ Monitor en tiempo real
- ✅ Gestión de archivos
- ✅ Logs detallados

### 🎨 Visualización 3D Dual
#### **NUEVO: STL/OBJ Viewer**
- ✅ Geometría REAL con mesh 3D
- ✅ Rendering interactivo con **rgl**
- ✅ Soporte STL, OBJ, PLY
- ✅ Rotación, zoom, pan
- ✅ Wireframe mode
- ✅ Control de opacidad
- ✅ Dimensiones automáticas

#### **Clásico: G-code Viewer**
- ✅ Visualización de bounding box
- ✅ Preview de área de impresión
- ✅ Compatible con archivos G-code

### 📊 Todas las Tabs Funcionales
1. **Connection** - Setup MQTT
2. **File Management** - Upload/manage G-code
3. **3D Model Viewer** - STL + G-code viewers
4. **Print Control** - Control activo de impresión
5. **Monitor** - Status en tiempo real
6. **Settings** - Configuración
7. **Logs** - Sistema de logs

---

## 🎯 INICIO RÁPIDO

### 1️⃣ Instalar Paquetes R:
```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "DT",
  "plotly",
  "jsonlite",
  "rgl",      # ← Para STL viewer
  "Rvcg"      # ← Para leer STL/PLY
))
```

### 2️⃣ Instalar Python MQTT (opcional):
```bash
pip install paho-mqtt --break-system-packages
```

### 3️⃣ Ejecutar:
```r
library(shiny)
runApp("app.R")
```

---

## 🎨 USAR EL NUEVO VISUALIZADOR STL

### Paso a Paso:

1. **Ir a** tab "3D Model Viewer"
2. **Click en** sub-tab "STL/OBJ Viewer" (arriba)
3. **Upload** tu archivo STL (ej: F-16.stl)
4. **¡Verás geometría REAL!** - No más cubos/ladrillos
5. **Interactuar:**
   - Click + Drag = Rotar
   - Scroll = Zoom
   - Ajustar opacidad y wireframe

### Ejemplo con tu F-16:
```
ANTES (G-code tab):        AHORA (STL tab):
┌─────────┐               ✈️ F-16 COMPLETO
│ LADRILLO│      →        │ • Alas visibles
│  CUBO   │               │ • Motor detallado
└─────────┘               └ • Fuselaje real
```

---

## 📋 DUAL VIEWER SYSTEM

### Tab 1: STL/OBJ Viewer (NUEVO)
**Para:** Ver geometría real del modelo  
**Usa:** Archivos STL, OBJ, PLY  
**Tecnología:** rgl (OpenGL 3D)  
**Ventaja:** Geometría completa, superficies, detalles

### Tab 2: G-code Viewer (Original)
**Para:** Preview rápido de área de impresión  
**Usa:** Archivos G-code  
**Tecnología:** Plotly mesh3d  
**Ventaja:** Muestra bounding box y dimensiones

**💡 Usa ambos según necesites:**
- STL para ver el modelo real
- G-code para verificar que cabe en la cama

---

## 🔧 FLUJO COMPLETO DE TRABAJO

### 1. DISEÑO
```
CAD Software (Fusion 360, Blender)
  ↓ Export
STL File
```

### 2. PREVIEW (esta app)
```
Tab: "3D Model Viewer" → "STL/OBJ Viewer"
  ↓ Upload STL
Ver geometría real en 3D
Verificar dimensiones
```

### 3. SLICE
```
Bambu Studio
  ↓ Import STL
Configure settings
  ↓ Slice
Export .gcode.3mf
```

### 4. PRINT (esta app)
```
Tab: "File Management"
  ↓ Upload .gcode.3mf
Tab: "Print Control"
  ↓ Start print
Tab: "Monitor"
  ↓ Watch progress
```

---

## 📁 ARCHIVOS INCLUIDOS

```
bambulab_COMPLETE_STL/
├── app.R                      ← App principal (74KB, ACTUALIZADO)
│
├── Python MQTT:
│   ├── bambulab_mqtt.py
│   ├── test_mqtt_connection.py
│   ├── test_interactive.py
│   ├── diagnose_network.py
│   └── requirements.txt
│
├── Installers:
│   ├── install_mqtt.sh        (Linux/Mac)
│   └── install_mqtt.bat       (Windows)
│
├── Sample G-code:
│   ├── level1_base.gcode
│   └── level2_platform.gcode
│
└── Documentation:
    ├── README.md              (este archivo)
    ├── INSTALLATION.md
    ├── CONNECTION_GUIDE.md
    ├── TROUBLESHOOTING.md
    ├── WINDOWS_QUICKSTART.md
    └── varios fix guides
```

---

## 🎯 CARACTERÍSTICAS POR TAB

### 📡 Connection Tab
- Input: IP, Access Code, Serial
- Test de conexión
- Status indicators
- Logs de conexión

### 📁 File Management Tab
- Upload G-code files
- Lista de archivos
- Delete/Select files
- File info

### 🎨 3D Model Viewer Tab
- **STL/OBJ Viewer** (NUEVO)
  - Upload STL/OBJ/PLY
  - Rendering 3D real
  - Controles de opacidad/wireframe
  - Dimensiones automáticas
  
- **G-code Viewer** (Original)
  - Load G-code
  - Bounding box 3D
  - Sample models (level1, level2)

### 🖨️ Print Control Tab
- Start/Pause/Stop/Resume
- Progress indicator
- Temperature controls
- Speed adjustment
- Fan control

### 📺 Monitor Tab
- Real-time status
- Temperature graphs
- Print progress
- Layer info
- Time remaining

### ⚙️ Settings Tab
- Printer configuration
- Network settings
- Advanced options

### 📜 Logs Tab
- System logs
- MQTT messages
- Errors/warnings
- Timestamp

---

## 🐛 TROUBLESHOOTING

### "rgl not installed"
```r
install.packages("rgl")
```
Reinicia app.

### "Rvcg not installed"
```r
install.packages("Rvcg")
```
Necesario para STL.

### "STL viewer is empty"
1. Verifica que archivo sea STL válido
2. Asegúrate que rgl y Rvcg están instalados
3. Revisa tab "Logs" por errores

### "Cannot connect to printer"
1. Verifica IP correcta
2. Same network WiFi/LAN
3. Access code correcto
4. Lee CONNECTION_GUIDE.md

### "G-code viewer shows cube"
Es normal - el G-code viewer solo muestra bounding box.  
Para ver geometría real, usa el **STL/OBJ Viewer**.

---

## 💡 TIPS & TRICKS

### Para Mejor Visualización 3D:
- Exporta STL con calidad media-alta
- Balance: ~50K-200K triángulos
- Usa Wireframe para modelos complejos
- Ajusta opacidad para ver interior

### Para Imprimir:
- Usa .gcode.3mf cuando sea posible
- Verifica dimensiones antes de slice
- Test con modelos pequeños primero

### Obtener Archivos STL:
- Busca el STL original pre-slice
- Exporta desde Bambu Studio
- Descarga de MakerWorld/Thingiverse
- Extrae de .gcode.3mf (manual)

---

## 📊 COMPARACIÓN DE VERSIONES

| Característica | Versión Anterior | Versión 2.0 |
|----------------|------------------|-------------|
| G-code viewer | ✅ Bounding box | ✅ Bounding box |
| STL viewer | ❌ No | ✅ Geometría real |
| Tabs completas | ✅ Todas | ✅ Todas |
| MQTT control | ✅ Completo | ✅ Completo |
| 3D rendering | ⚠️ Solo Plotly | ✅ Plotly + rgl |
| Archivos | G-code only | G-code + STL/OBJ |

---

## ✅ REQUISITOS

### Software:
- R 4.0+
- Python 3.7+ (solo para MQTT)
- Navegador moderno

### Hardware:
- 4GB RAM mínimo
- GPU recomendada (para rgl)
- WiFi/LAN para printer

### Paquetes R:
- shiny, shinydashboard ← Base
- DT, plotly, jsonlite ← UI
- rgl, Rvcg ← Nuevo (STL viewer)

---

## 🎉 RESULTADO FINAL

Con esta versión tienes:
- ✅ **TODO** lo que tenías antes (control MQTT completo)
- ✅ **MÁS** visualizador STL con geometría real
- ✅ **Dual viewer** para STL y G-code
- ✅ **Sin perder** ninguna funcionalidad
- ✅ **Mejor** experiencia de visualización

**¡Todo en un solo dashboard integrado!**

---

## 📚 DOCUMENTACIÓN ADICIONAL

- `INSTALLATION.md` - Guía de instalación detallada
- `CONNECTION_GUIDE.md` - Setup MQTT
- `TROUBLESHOOTING.md` - Solución de problemas
- `WINDOWS_QUICKSTART.md` - Quick start Windows

---

## 🆘 SOPORTE

1. Revisa documentación incluida
2. Verifica instalación de paquetes
3. Consulta logs en tab "Logs"
4. Prueba con archivos de ejemplo

---

**Creado con ❤️ para Bambu Lab A1 Combo**  
**Versión 2.0 - Complete Edition con STL Viewer**
