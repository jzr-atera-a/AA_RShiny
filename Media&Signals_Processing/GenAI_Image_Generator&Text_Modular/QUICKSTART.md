# Quick Start Guide - DALL-E Image Generator

## ⚡ 5-Minute Setup

### Step 1: Install Required Packages (2 minutes)

Open R or RStudio and run:

```r
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr",
  "httr", "jsonlite", "base64enc", "shinyFiles", "magick"
))
```

**Note:** If `magick` fails, install ImageMagick first:
- **Ubuntu/Debian:** `sudo apt-get install libmagick++-dev`
- **macOS:** `brew install imagemagick`
- **Windows:** Download from https://imagemagick.org/script/download.php

### Step 2: Get OpenAI API Key (1 minute)

1. Go to: https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Copy your key (starts with `sk-`)

### Step 3: Run the App (30 seconds)

```r
setwd("path/to/DALLE_Image_Generator")
shiny::runApp()
```

### Step 4: Configure API (1 minute)

1. Click "DALL-E API Settings" tab
2. Paste your API key
3. Select "DALL-E 3" model
4. Click "Save Settings"
5. Click "Test Connection" (should show ✓ success)

### Step 5: Generate Your First Image (1 minute)

1. Click "Image Generation" tab
2. Enter description: `"A majestic dragon flying over a mountain at sunset"`
3. Select style: "Art-like"
4. Select aspect ratio: "16:9"
5. Click "Generate Image"
6. Wait 15-30 seconds
7. View your generated image!

### Step 6: Download (30 seconds)

1. Select format: "JPG"
2. Enter filename: `my_first_dragon`
3. Click "Choose Download Folder"
4. Select destination
5. Click "Download Image"

## 🎉 You're Done!

Now you can:
- Try different descriptions
- Experiment with styles (Art vs Photo)
- Change aspect ratios
- Adjust dimensions
- Download in different formats

## 💡 Pro Tips

1. **Better Prompts:**
   - Be specific: "a red sports car" vs "a car"
   - Add details: "at sunset", "in watercolor style"
   - Mention perspective: "close-up", "aerial view"

2. **Save Money:**
   - Start with DALL-E 2 for testing
   - Use Standard quality instead of HD
   - Perfect your prompt before generating

3. **Best Quality:**
   - Use DALL-E 3 + HD quality
   - Choose appropriate aspect ratio
   - Download as PNG or TIFF for lossless quality

## 🚨 Common Issues

**"Package magick not found"**
→ Install ImageMagick system library first

**"Invalid API key"**
→ Check for spaces, ensure it starts with "sk-"

**"Rate limit exceeded"**
→ Wait a few minutes, check your OpenAI limits

**Image not showing**
→ Check console, ensure generation was successful

## 📊 Example Prompts

### Art-like Style:
- `"A mystical forest with glowing mushrooms and fireflies"`
- `"Abstract geometric patterns in purple and gold"`
- `"Cyberpunk cityscape with neon lights"`

### Photograph-like Style:
- `"A golden retriever puppy playing in autumn leaves"`
- `"Mountain landscape with a crystal clear lake"`
- `"Close-up of a coffee cup on a wooden table"`

## 🎯 Next Steps

1. Read the full README.md for detailed information
2. Experiment with different models and settings
3. Try various aspect ratios for different uses
4. Explore different download formats

**Happy Creating! 🎨**
