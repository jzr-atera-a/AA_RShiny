# Receipt Processor - Modular Shiny Application

A comprehensive R Shiny application for processing, categorizing, and managing receipts using OpenAI's Vision API.

## Features

- **Settings Configuration**: Configure OpenAI API key and application settings
- **PDF to JPG Converter**: Convert PDF files to high-quality JPG images
- **Image to PDF Converter**: Convert image files (JPG, PNG, etc.) to PDF format
- **Receipt Upload & Processing**: Upload receipts and extract information using AI
- **Data Viewing**: View and export all processed receipts
- **Receipt Categorization**: Categorize receipts into predefined categories with automatic file organization

## Architecture

This application follows a modular architecture with:

```
.
├── app.R                          # Main application file
├── modules/                       # Shiny modules
│   ├── settings_module.R          # Settings configuration
│   ├── pdf_converter_module.R     # PDF to JPG conversion
│   ├── to_pdf_converter_module.R  # Image to PDF conversion
│   ├── upload_module.R            # Receipt upload and processing
│   ├── data_view_module.R         # Data viewing and export
│   └── categorize_module.R        # Receipt categorization
├── utils/                         # Utility functions
│   ├── api_utils.R                # OpenAI API functions
│   └── file_utils.R               # File handling functions
└── ui/                            # UI components
    └── styles.R                   # CSS styling
```

## Installation

### Required R Packages

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "httr",
  "jsonlite",
  "base64enc",
  "DT",
  "dplyr",
  "openxlsx",
  "shinyFiles",
  "pdftools",
  "magick",
  "fs"
))
```

### System Requirements

- **For PDF Processing**: Install `pdftools` and `magick` packages
  - On Ubuntu/Debian: `sudo apt-get install libpoppler-cpp-dev libmagick++-dev`
  - On macOS: `brew install poppler imagemagick`
  - On Windows: Packages will download required binaries automatically

## Getting Started

### 1. Clone or Download the Repository

```bash
git clone <repository-url>
cd receipt-processor
```

### 2. Set Up Your OpenAI API Key

1. Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Run the application
3. Navigate to the **Settings** tab
4. Enter your API key and click "Save Settings"
5. Test the connection using the "Test API Connection" button

### 3. Run the Application

```r
# In R or RStudio
shiny::runApp()
```

Or from command line:

```bash
Rscript -e "shiny::runApp()"
```

## Usage Guide

### Settings Tab
- Configure your OpenAI API key
- Set receipts storage folder path
- Specify Excel output filename
- Test API connection

### PDF to JPG Converter
- Upload PDF files (multiple files supported)
- Set image quality (DPI)
- Specify output folder
- Convert all pages to separate JPG files

### Convert to PDF
- Choose individual image files or entire folder
- Select PDF page size (A4 or Letter)
- Browse for output folder
- Convert images to high-quality PDFs (300 DPI)

### Upload Receipts
- Upload up to 5 receipt images at a time (JPG/JPEG only)
- AI automatically extracts:
  - Provider/Seller name
  - Amount paid
  - Date of transaction
  - Description of purchase
- Files are saved with descriptive names

### View Processed Data
- View all processed receipts in a sortable table
- Filter data by any column
- Download Excel file with all data
- Refresh to load latest data

### Categorize Receipts
- Edit category assignments (Labour, Overheads, Materials, Capital Usage, T&S, Contractor)
- Radio button behavior: only one category per receipt
- View real-time category totals
- Save categories to Excel
- Copy files to category folders automatically

## Module Details

### Settings Module (`settings_module.R`)
Handles API configuration, folder settings, and connection testing.

**Key Functions:**
- `settingsUI()`: Creates settings interface
- `settingsServer()`: Manages settings logic and API testing

### PDF Converter Module (`pdf_converter_module.R`)
Converts PDF files to JPG images with customizable quality.

**Key Functions:**
- `pdfConverterUI()`: Creates converter interface
- `pdfConverterServer()`: Handles PDF to JPG conversion

### To PDF Converter Module (`to_pdf_converter_module.R`)
Converts image files to PDF format with folder browsing.

**Key Functions:**
- `toPdfConverterUI()`: Creates converter interface
- `toPdfConverterServer()`: Handles image to PDF conversion

### Upload Module (`upload_module.R`)
Processes receipt images using OpenAI Vision API.

**Key Functions:**
- `uploadUI()`: Creates upload interface
- `uploadServer()`: Handles receipt processing and file naming

### Data View Module (`data_view_module.R`)
Displays and exports processed receipt data.

**Key Functions:**
- `dataViewUI()`: Creates data viewing interface
- `dataViewServer()`: Manages data display and export

### Categorize Module (`categorize_module.R`)
Manages receipt categorization and file organization.

**Key Functions:**
- `categorizeUI()`: Creates categorization interface
- `categorizeServer()`: Handles category editing and file copying

## Utility Functions

### API Utils (`utils/api_utils.R`)
- `encode_file()`: Encodes files to base64
- `get_media_type()`: Determines file media type
- `call_openai_api()`: Calls OpenAI Vision API
- `test_api_connection()`: Tests API connectivity

### File Utils (`utils/file_utils.R`)
- `create_safe_filename()`: Creates filesystem-safe filenames
- `create_renamed_filename()`: Generates descriptive filenames
- `get_smart_description()`: Extracts smart descriptions for specific receipt types
- `get_folder_volumes()`: Initializes folder browser volumes

## File Naming Convention

Processed receipts are saved with descriptive names:

**Format:** `ProviderName_Description_YYYYMMDD_Amount.jpg`

**Examples:**
- `Trainline_London_to_Manchester_20251115_14.92.jpg`
- `Booking_com_Paris_Hotel_20251110_85.50.jpg`
- `Tesco_Groceries_20251120_42.15.jpg`

## Data Storage

### Excel File Structure
The application stores data in an Excel file with the following columns:
- `receipt_id`: Unique identifier
- `filename`: Saved filename
- `provider`: Provider/seller name
- `amount`: Numeric amount (no currency symbols)
- `date`: Transaction date (YYYY-MM-DD)
- `description`: Description of purchase
- `processed_timestamp`: When receipt was processed
- `Labour`, `Overheads`, `Materials`, `Capital_Usage`, `TS`, `Contractor`: Category flags (0 or 1)

## Troubleshooting

### PDF Conversion Issues
- Ensure `pdftools` and `magick` packages are installed
- Check system dependencies are installed
- Verify PDF files are not corrupted

### API Connection Issues
- Verify API key is correct and active
- Check internet connection
- Ensure you have API credits available
- API key should start with `sk-`

### File Path Issues
- Use absolute paths for folder locations
- Windows: Use forward slashes `/` or double backslashes `\\`
- Ensure folders have write permissions

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch
3. Follow the modular architecture
4. Test thoroughly
5. Submit a pull request

## License

[Specify your license here]

## Support

For issues or questions:
- Check the Troubleshooting section
- Review OpenAI API documentation
- Create an issue in the repository

## Credits

Built with:
- R Shiny
- OpenAI GPT-4 Vision API
- shinydashboard
- Various R packages (see Installation section)
