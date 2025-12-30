; Generated from STL
; Model: 0.stl
; Dimensions: 69.50 x 48.28 x 16.95 mm
; Layer height: 0.2mm
; Infill: 20%
; Material: PLA
; Generated: 2025-12-30 02:54:50

G28 ; Home all axes
G1 Z15.0 F6000 ; Move up
M109 S200 ; Set and wait for nozzle temp
M190 S60 ; Set and wait for bed temp

; Start G-code
G92 E0 ; Reset extruder
G1 F200 E3 ; Purge
G92 E0 ; Reset extruder again

; Model printing would happen here
; Toolpath data from slicer would be inserted here
; [Simplified for demo - in production use real slicer]

; End G-code
G28 X0 Y0 ; Home X Y
M104 S0 ; Turn off hotend
M140 S0 ; Turn off bed
M107 ; Turn off fan
M84 ; Disable motors

; Print complete

