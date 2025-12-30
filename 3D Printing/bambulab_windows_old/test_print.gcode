; Bambulab A1 Combo - Simple Test Print
; Test cube: 20x20x20mm
; Generated for testing purposes

; Start G-code
M107 ; Turn off fan
G28 ; Home all axes
G1 Z15.0 F6000 ; Move platform down 15mm
G92 E0 ; Reset extruder
G1 F200 E3 ; Extrude 3mm of filament
G92 E0 ; Reset extruder

; Layer 0 - Base
G0 F6000 X50 Y50 Z0.2 ; Move to start position
G1 F1500 E0 ; Reset extruder
M106 S255 ; Turn on fan

; Draw square perimeter
G1 F1500 X70 Y50 E0.5
G1 X70 Y70 E1.0
G1 X50 Y70 E1.5
G1 X50 Y50 E2.0

; Fill square
G1 X51 Y51 E2.1
G1 X69 Y51 E2.6
G1 X69 Y52 E2.65
G1 X51 Y52 E3.15
G1 X51 Y53 E3.2
G1 X69 Y53 E3.7
G1 X69 Y54 E3.75
G1 X51 Y54 E4.25

; Layer 1
G0 Z0.4
G1 F1500 X50 Y50 E4.3
G1 X70 Y50 E4.8
G1 X70 Y70 E5.3
G1 X50 Y70 E5.8
G1 X50 Y50 E6.3

; Layer 2
G0 Z0.6
G1 F1500 X50 Y50 E6.35
G1 X70 Y50 E6.85
G1 X70 Y70 E7.35
G1 X50 Y70 E7.85
G1 X50 Y50 E8.35

; Layer 3
G0 Z0.8
G1 F1500 X50 Y50 E8.4
G1 X70 Y50 E8.9
G1 X70 Y70 E9.4
G1 X50 Y70 E9.9
G1 X50 Y50 E10.4

; Layer 4
G0 Z1.0
G1 F1500 X50 Y50 E10.45
G1 X70 Y50 E10.95
G1 X70 Y70 E11.45
G1 X50 Y70 E11.95
G1 X50 Y50 E12.45

; End G-code
M107 ; Turn off fan
G91 ; Relative positioning
G1 E-1 F300 ; Retract filament
G1 Z10 F3000 ; Raise Z 10mm
G90 ; Absolute positioning
G1 X0 Y200 F3000 ; Present print
M84 ; Disable motors
M104 S0 ; Turn off hotend
M140 S0 ; Turn off bed

; Print statistics
; Estimated print time: 2 minutes
; Filament used: ~0.1g
; Layer count: 5
