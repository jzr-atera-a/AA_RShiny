# DALL-E Image Generator - R Shiny App

A professional, modular R Shiny application for generating images using OpenAI's DALL-E API with comprehensive customization options.

## 🌟 Features

### Two Main Modules:

1. **DALL-E API Settings**
   - Configure OpenAI API key
   - Select between DALL-E 2 and DALL-E 3 models
   - Quality settings (Standard/HD for DALL-E 3)
   - Style settings (Vivid/Natural for DALL-E 3)
   - Test API connection

2. **Image Generation**
   - Text-based image description
   - Style selection: Art-like or Photograph-like
   - Aspect ratio selection: 16:9, 4:3, 1:1, 3:4, 9:16
   - Custom dimensions with unit selection (cm or inches)
   - Auto-calculated width based on aspect ratio
   - Real-time image preview
   - Download in multiple formats: JPG, PNG, TIFF, GIF, PDF, SVG
   - High-resolution output (300 DPI)
   - Custom filename and folder selection

## ⚠️ Important: Aspect Ratio Limitations

**DALL-E API has fixed output sizes. The aspect ratio selector maps to the closest available size:**

### DALL-E 3 Available Sizes:
- **1024x1024** (1:1 ratio) - Square
- **1792x1024** (1.75:1 ratio) - Landscape
- **1024x1792** (0.57:1 ratio) - Portrait

### Aspect Ratio Mapping for DALL-E 3:
- **1:1** → 1024x1024 ✅ (Perfect square)
- **4:3** → 1024x1024 (Close to square, 1.33:1 → 1:1)
- **3:4** → 1024x1024 (Close to square, 0.75:1 → 1:1)
- **16:9** → 1792x1024 ✅ (Landscape, 1.78:1 → 1.75:1)
- **9:16** → 1024x1792 ✅ (Portrait, 0.56:1 → 0.57:1)

### DALL-E 2:
- All aspect ratios → 1024x1024 (only square images supported)

**Note:** For precise aspect ratios like 4:3 or 3:4, the downloaded image will need to be cropped manually after generation, as DALL-E doesn't support these exact ratios.

## 📋 Prerequisites

### Required R Packages:

```r
# Core packages
install.packages("shiny")
install.packages("shinydashboard")
install.packages("R6")
install.packages("yaml")
install.packages("purrr")

# API and utilities
install.packages("httr")
install.packages("jsonlite")
install.packages("base64enc")

# File handling
install.packages("shinyFiles")

# Image processing
install.packages("magick")  # Requires ImageMagick system library
```

### System Dependencies:

**For `magick` package (image processing):**

- **Ubuntu/Debian:**
  ```bash
  sudo apt-get install libmagick++-dev
  ```

- **macOS:**
  ```bash
  brew install imagemagick
  ```

- **Windows:**
  Download and install ImageMagick from: https://imagemagick.org/script/download.php

### OpenAI API Key:

Get your API key from: https://platform.openai.com/api-keys

## 🚀 Installation

1. **Extract the application folder:**
   - Place the `DALLE_Image_Generator` folder in your desired location

2. **Install required packages:**
   ```r
   # Run this in R console
   install.packages(c("shiny", "shinydashboard", "R6", "yaml", "purrr", 
                      "httr", "jsonlite", "base64enc", "shinyFiles", "magick"))
   ```

3. **Verify directory structure:**
   ```
   DALLE_Image_Generator/
   ├── app.R
   ├── global.R
   ├── R/
   │   ├── module_loader.R
   │   ├── utils_api.R
   │   └── utils_common.R
   ├── modules/
   │   ├── _module_registry.yml
   │   ├── dalle_settings/
   │   │   ├── ui.R
   │   │   └── server.R
   │   └── image_generation/
   │       ├── ui.R
   │       └── server.R
   └── www/
       └── css/
           └── global.css
   ```

## 🎯 Usage

### Starting the Application:

1. **Open R or RStudio**

2. **Set working directory:**
   ```r
   setwd("path/to/DALLE_Image_Generator")
   ```

3. **Run the app:**
   ```r
   shiny::runApp()
   ```

### Configuration Steps:

1. **Navigate to "DALL-E API Settings" tab**
   - Enter your OpenAI API key
   - Select your preferred model (DALL-E 3 recommended)
   - Configure quality (Standard or HD)
   - Configure style (Vivid or Natural)
   - Click "Save Settings"
   - Click "Test Connection" to verify

2. **Navigate to "Image Generation" tab**
   - Enter your image description
   - Select style (Art-like or Photograph-like)
   - Choose aspect ratio (see limitations above)
   - Set height dimension (default: 10 cm)
   - Select unit (cm or inches)
   - Click "Generate Image"
   - Wait 10-30 seconds for generation
   - Review the generated image

3. **Download the Image:**
   - Select download format (JPG, PNG, TIFF, GIF, PDF, SVG)
   - Enter custom filename
   - Click "Choose Download Folder"
   - Select destination folder
   - Click "Download Image"

## 🎨 Model Comparison

### DALL-E 3 (Recommended)
- **Pros:**
  - Best image quality
  - Better prompt understanding
  - HD quality option
  - Supports landscape and portrait (1792x1024, 1024x1792)
- **Cons:**
  - Higher cost per image
  - Slightly slower generation
  - Limited to 3 aspect ratios

### DALL-E 2
- **Pros:**
  - Faster generation
  - Lower cost
  - Good for iterations
- **Cons:**
  - Lower quality than DALL-E 3
  - Only square images (1024x1024)
  - Less accurate prompt interpretation

## 📐 Understanding Aspect Ratios

The app shows aspect ratios for reference and calculates dimensions, but the **actual generated image** is determined by DALL-E's fixed sizes:

- **For 16:9 and 9:16**: You'll get proper landscape/portrait images ✅
- **For 1:1**: Perfect square images ✅
- **For 4:3 and 3:4**: You'll get square images that you can crop to desired ratio

**Tip:** If you need exact 4:3 or 3:4 ratios, use an external image editor to crop the downloaded image after generation.

## 💾 Download Formats

- **JPG** - Highest quality (100%), smaller file size (default)
- **PNG** - Lossless compression, larger file size
- **TIFF** - Professional quality, LZW compression
- **GIF** - Good compatibility
- **PDF** - Document format with 300 DPI
- **SVG** - Scalable vector wrapper (raster embedded)

All formats are exported at 300 DPI for high-resolution output.

## 🎯 Style Enhancement

The app automatically enhances prompts based on selected style:

### Art-like:
- Adds: "digital art, vibrant colors, creative composition, artistic interpretation"

### Photograph-like:
- Adds: "high-resolution photography, natural lighting, sharp focus, professional quality"

## 🏗️ Architecture

This app follows a modular architecture pattern:

- **R6 Classes:** APIManager for API interactions, ModuleLoader for dynamic module loading
- **Modular Design:** Each feature is a separate module with ui.R and server.R
- **YAML Configuration:** Module registry defines enabled modules and dependencies
- **Factory Pattern:** UI and Server created dynamically from module registry
- **Utility Functions:** Shared functions in R/utils_*.R files

## 🐛 Troubleshooting

### "Package 'magick' not found"
- Install ImageMagick system library first
- Then reinstall magick: `install.packages("magick")`

### "Invalid API key"
- Verify your API key at https://platform.openai.com/api-keys
- Ensure key starts with "sk-"
- Check for extra spaces when pasting

### "Rate limit exceeded"
- Wait a few minutes before trying again
- Check your OpenAI usage limits

### "Image not displaying"
- Check browser console for errors
- Ensure image was generated successfully
- Try refreshing the browser

### Download folder not showing
- Check folder permissions
- Try selecting a different folder
- On Windows, ensure drive is accessible

### "Error: 'image_density' is not an exported object"
- This has been fixed in the latest version
- Replace your R/utils_api.R file with the updated version
- The issue was using a non-existent function; now uses density parameter correctly

### Image comes out square when I selected 16:9
- Make sure you're using DALL-E 3 (not DALL-E 2)
- Check the console log to see which size was requested
- DALL-E 2 only supports square images

## 💰 Pricing Information

As of 2025, OpenAI pricing (approximate):
- **DALL-E 3 Standard:** $0.040 per image (1024x1024), $0.080 per image (1792x1024 or 1024x1792)
- **DALL-E 3 HD:** $0.080 per image (1024x1024), $0.120 per image (1792x1024 or 1024x1792)
- **DALL-E 2:** $0.020 per image (1024x1024)

Check current pricing at: https://openai.com/pricing

## 📝 License

This application is provided as-is for educational and personal use.

## 🤝 Support

For issues with:
- **The app:** Check the troubleshooting section above
- **OpenAI API:** Visit https://platform.openai.com/docs
- **R packages:** Check package documentation

## 🎨 CSS Styling

The app uses a professional gradient-based design:
- Primary gradient: Purple (#667eea → #764ba2)
- Success gradient: Green (#11998e → #38ef7d)
- Sidebar: Dark blue (#2c3e50 → #34495e)
- Background: Light gradient (#f5f7fa → #c3cfe2)

## 🔒 Security Note

- Never commit your API key to version control
- Keep your API key secure
- Monitor your API usage regularly
- Set spending limits in your OpenAI account

---

**Enjoy creating amazing AI-generated images! 🎨✨**
