# Bambulab A1 Combo 3D Printer Control Dashboard

A comprehensive R Shiny dashboard application for controlling the Bambulab A1 Combo 3D printer via USB connection on Windows.

## Features

### 1. Connection Management
- Auto-scan for available COM ports
- USB serial connection with configurable baud rate
- Real-time connection status monitoring
- Printer information display

### 2. File Management
- Upload G-code files (.gcode, .gco, .3mf)
- File preview with line count and size
- Send files to printer via USB
- View printer file list

### 3. Print Control
- Start, stop, pause, and resume print jobs
- Real-time print progress monitoring
- Speed and flow rate adjustment
- Fan speed control
- Temperature management (hotend, bed)

### 4. Monitoring
- Real-time temperature graphs
- Print statistics (elapsed time, remaining time, filament usage)
- Layer progress tracking
- Z-height monitoring
- Auto-refresh capability

### 5. Settings & Manual Control
- Manual axis movement (X, Y, Z)
- Homing controls
- Extrusion and retraction
- Custom G-code command execution
- Printer settings configuration

### 6. Communication Logs
- Complete communication logging
- Log export functionality
- Timestamped entries

## Installation

### Prerequisites

1. **R** (version 4.0 or higher)
   - Download from: https://cran.r-project.org/

2. **RStudio** (recommended)
   - Download from: https://www.rstudio.com/products/rstudio/download/

### Required R Packages

Install the following packages in R:

```r
# Install required packages
install.packages(c(
  "shiny",
  "shinydashboard",
  "DT",
  "plotly"
))

# For serial communication, you may need:
# Windows: Install Rtools from https://cran.r-project.org/bin/windows/Rtools/
# Then install serial package
install.packages("serial")
```

### Windows USB Drivers

Ensure you have the appropriate USB drivers for the Bambulab A1 printer installed. These are typically installed automatically when you connect the printer, but you can download them from:
- Bambulab official website: https://wiki.bambulab.com/

## Setup

1. **Clone or Download** this repository to your local machine

2. **Connect your Bambulab A1 Combo printer** to your Windows PC via USB cable

3. **Verify COM Port**:
   - Open Device Manager (Win + X, then select Device Manager)
   - Expand "Ports (COM & LPT)"
   - Note the COM port number for your printer (e.g., COM3, COM5)

4. **Open the R Project**:
   ```r
   # In R or RStudio, navigate to the project directory
   setwd("path/to/bambulab-controller")
   
   # Run the app
   shiny::runApp("app.R")
   ```

## Usage Guide

### Initial Connection

1. **Launch the Application**
   - Run `shiny::runApp("app.R")` in R/RStudio
   - The dashboard will open in your default web browser

2. **Connect to Printer**
   - Navigate to the "Connection" tab
   - Click "Scan Ports" to detect available COM ports
   - Select your printer's COM port from the dropdown
   - Choose the appropriate baud rate (default: 115200)
   - Click "Connect to Printer"

3. **Verify Connection**
   - Check the connection status indicator (should show green)
   - Review printer information in the info panel

### Uploading and Printing Files

1. **Upload G-code File**
   - Navigate to "File Management" tab
   - Click "Choose G-code File" and select your .gcode file
   - Review the file preview
   - Click "Send to Printer" to transfer the file

2. **Start a Print**
   - Navigate to "Print Control" tab
   - Select file from the dropdown
   - Set desired temperatures (hotend and bed)
   - Click "Start Print"

3. **Monitor Progress**
   - Navigate to "Monitor" tab
   - View real-time temperature graphs
   - Check print statistics and progress
   - Enable auto-refresh for continuous updates

### Manual Control

1. **Navigate to Settings Tab**
2. **Use Movement Controls**:
   - Select movement distance (0.1mm to 100mm)
   - Click directional buttons for XY movement
   - Use Z+ and Z- for vertical movement
   - Click "Home" to return to origin

3. **Extrusion/Retraction**:
   - Heat hotend to appropriate temperature first
   - Click "Extrude 10mm" or "Retract 10mm"

### Custom G-code Commands

1. Navigate to "Settings" → "Advanced Commands"
2. Enter G-code command (e.g., `M503` to get settings)
3. Click "Send Command"
4. View response in the text area below

## Supported G-code Commands

Common commands you can use:

- `M503` - Get current settings
- `M105` - Get current temperatures
- `M114` - Get current position
- `G28` - Home all axes
- `G28 X` - Home X axis
- `G28 Y` - Home Y axis
- `G28 Z` - Home Z axis
- `M104 S200` - Set hotend temperature to 200°C
- `M140 S60` - Set bed temperature to 60°C
- `M106 S255` - Set fan to maximum
- `M107` - Turn fan off

## Troubleshooting

### Cannot Find COM Port
- Ensure printer is connected via USB
- Check Device Manager for COM port assignment
- Try a different USB cable or port
- Restart the printer and computer

### Connection Fails
- Verify correct COM port is selected
- Try different baud rates (115200, 250000, 9600)
- Close any other software that might be using the COM port
- Check Windows permissions for serial port access

### File Upload Fails
- Ensure file is valid G-code format
- Check file size (very large files may take time)
- Verify printer has sufficient storage space
- Check USB connection stability

### Temperature Not Updating
- Enable "Auto-refresh" in Monitor tab
- Manually click "Refresh" button
- Verify printer is responding to commands
- Check USB connection

## Safety Warnings

⚠️ **IMPORTANT SAFETY NOTES:**

1. **Never leave printer unattended** during operation
2. **Monitor temperatures** - verify they are within safe ranges
3. **Use proper ventilation** when printing
4. **Keep flammable materials away** from the printer
5. **Emergency stop**: Use the "Stop Print" button in case of emergency
6. **Cool down properly**: Always use "Cool Down" button after printing

## Technical Details

### Communication Protocol
- Interface: USB Serial (CDC)
- Default Baud Rate: 115200
- Data Bits: 8
- Parity: None
- Stop Bits: 1

### Supported File Formats
- .gcode (G-code files)
- .gco (G-code files)
- .3mf (3D Manufacturing Format) - requires conversion

### Temperature Limits
- Hotend: 0-300°C
- Bed: 0-120°C

### Build Volume
- X: 256mm
- Y: 256mm
- Z: 256mm

## Known Limitations

1. **Serial Package**: The `serial` package for R may have limited functionality on some Windows systems. Alternative: use Python scripts for serial communication.

2. **Real-time Updates**: High-frequency updates may impact performance. Recommended refresh interval: 2-5 seconds.

3. **Large Files**: Very large G-code files (>50MB) may take significant time to transfer.

4. **Webcam Support**: Current version does not include webcam monitoring (planned for future release).

## Future Enhancements

- [ ] Webcam integration for print monitoring
- [ ] Advanced slicer integration
- [ ] Print history and statistics
- [ ] Multi-printer support
- [ ] Network (WiFi) connectivity option
- [ ] Bed leveling assistant
- [ ] Filament management tracking

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

This project is for educational and personal use. Please respect Bambulab's terms of service and warranties.

## Disclaimer

This is an independent project and is not officially affiliated with or endorsed by Bambulab. Use at your own risk. The authors are not responsible for any damage to your printer or property.

## Support

For issues and questions:
1. Check the Troubleshooting section above
2. Review Bambulab's official documentation
3. Open an issue on the project repository

## Acknowledgments

- Bambulab for creating the A1 Combo printer
- R Shiny community for excellent dashboard framework
- Contributors and testers

## Version History

### v1.0.0 (Current)
- Initial release
- Basic USB connectivity
- File upload and management
- Print control features
- Temperature monitoring
- Manual movement controls
- Communication logging

---

**Last Updated**: December 2024
**Tested With**: Bambulab A1 Combo, Windows 10/11
