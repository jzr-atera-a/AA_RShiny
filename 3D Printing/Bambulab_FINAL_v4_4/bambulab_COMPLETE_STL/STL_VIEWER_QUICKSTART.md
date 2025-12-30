# ⚡ GUÍA RÁPIDA - NUEVO VISUALIZADOR STL

## 🎯 USO DEL STL VIEWER

### 1. Abrir la App
```r
library(shiny)
runApp("app.R")
```

### 2. Ir al Visualizador
- Click en tab **"3D Model Viewer"**
- Click en sub-tab **"STL/OBJ Viewer"** (arriba izquierda)

### 3. Upload Archivo
- Click **"Choose File"**
- Selecciona tu archivo .STL, .OBJ, o .PLY
- Ejemplo: `F-16.stl`

### 4. ¡Ver en 3D!
- El modelo aparecerá automáticamente
- **Click + Drag** = Rotar
- **Scroll** = Zoom in/out
- **Shift + Drag** = Pan

### 5. Ajustar Vista
- **Opacity slider**: Transparencia del modelo
- **Wireframe checkbox**: Ver estructura de malla

---

## 🔄 CAMBIAR ENTRE VIEWERS

### Para ver STL (geometría real):
1. Tab "3D Model Viewer"
2. Sub-tab **"STL/OBJ Viewer"**
3. Upload STL file

### Para ver G-code (bounding box):
1. Tab "3D Model Viewer"  
2. Sub-tab **"G-code Viewer"**
3. Load G-code file

---

## 📁 OBTENER ARCHIVOS STL

### Opción 1: Archivo Original
Busca el archivo .STL que exportaste de tu CAD

### Opción 2: Desde Bambu Studio
1. Abre tu .gcode.3mf en Bambu Studio
2. File → Export → Export as STL
3. Guarda el STL

### Opción 3: Descargar
- [Thingiverse](https://www.thingiverse.com/)
- [Printables](https://www.printables.com/)
- [MakerWorld](https://makerworld.com/)

---

## ✅ VERIFICACIÓN RÁPIDA

### Si el viewer no aparece:
```r
# Instala paquetes necesarios:
install.packages("rgl")
install.packages("Rvcg")

# Reinicia la app
```

### Si el modelo no se ve:
1. Verifica que sea archivo .STL válido
2. Tamaño < 100MB recomendado
3. Revisa tab "Logs" por errores

---

## 🎨 EJEMPLO VISUAL

```
TU F-16:

ANTES (G-code viewer):
┌─────────┐
│         │
│  CUBO   │
│         │
└─────────┘

AHORA (STL viewer):
    ✈️
   /│\
  / │ \
 /  │  \
/__─┴─__\

¡Geometría COMPLETA!
```

---

## 💡 TIPS

1. **Primeros pasos**: Descarga un STL simple de Thingiverse para probar
2. **Rendimiento**: Modelos con <200K triángulos funcionan mejor
3. **Detalles**: Usa Wireframe para ver estructura interna
4. **Dimensiones**: Se actualizan automáticamente desde el STL

---

**Tiempo de setup:** 2 minutos  
**Resultado:** Visualización 3D profesional integrada en tu dashboard
