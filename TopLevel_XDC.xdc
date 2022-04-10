# Inputs - CLK and RESET
set_property PACKAGE_PIN W5 [get_ports CLK]
        set_property IOSTANDARD LVCMOS33 [get_ports CLK]
set_property PACKAGE_PIN U18 [get_ports RESET]
        set_property IOSTANDARD LVCMOS33 [get_ports RESET]
       
# InOuts - PS/2 Interface
set_property PACKAGE_PIN C17 [get_ports CLK_MOUSE]
        set_property IOSTANDARD LVCMOS33 [get_ports CLK_MOUSE]
        set_property PULLUP true [get_ports CLK_MOUSE]
set_property PACKAGE_PIN B17 [get_ports DATA_MOUSE]
        set_property IOSTANDARD LVCMOS33 [get_ports DATA_MOUSE]
        set_property PULLUP true [get_ports DATA_MOUSE]

# LEDs for Status Byte Data
set_property PACKAGE_PIN U16 [get_ports STATUS_LEDS[0]]
        set_property IOSTANDARD LVCMOS33 [get_ports STATUS_LEDS[0]]
set_property PACKAGE_PIN E19 [get_ports STATUS_LEDS[1]]
        set_property IOSTANDARD LVCMOS33 [get_ports STATUS_LEDS[1]]
set_property PACKAGE_PIN U19 [get_ports STATUS_LEDS[2]]
        set_property IOSTANDARD LVCMOS33 [get_ports STATUS_LEDS[2]]
set_property PACKAGE_PIN V19 [get_ports STATUS_LEDS[3]]
        set_property IOSTANDARD LVCMOS33 [get_ports STATUS_LEDS[3]]  
        
# LEDs for Scroll Wheel Position
set_property PACKAGE_PIN L1 [get_ports SCROLL_LEDS[7]]
        set_property IOSTANDARD LVCMOS33 [get_ports SCROLL_LEDS[7]]
set_property PACKAGE_PIN P1 [get_ports SCROLL_LEDS[6]]
        set_property IOSTANDARD LVCMOS33 [get_ports SCROLL_LEDS[6]]
set_property PACKAGE_PIN N3 [get_ports SCROLL_LEDS[5]]
        set_property IOSTANDARD LVCMOS33 [get_ports SCROLL_LEDS[5]]
set_property PACKAGE_PIN P3 [get_ports SCROLL_LEDS[4]]
        set_property IOSTANDARD LVCMOS33 [get_ports SCROLL_LEDS[4]]
set_property PACKAGE_PIN U3 [get_ports SCROLL_LEDS[3]]
        set_property IOSTANDARD LVCMOS33 [get_ports SCROLL_LEDS[3]]
set_property PACKAGE_PIN W3 [get_ports SCROLL_LEDS[2]]
        set_property IOSTANDARD LVCMOS33 [get_ports SCROLL_LEDS[2]]
set_property PACKAGE_PIN V3 [get_ports SCROLL_LEDS[1]]
        set_property IOSTANDARD LVCMOS33 [get_ports SCROLL_LEDS[1]]
set_property PACKAGE_PIN V13 [get_ports SCROLL_LEDS[0]]
        set_property IOSTANDARD LVCMOS33 [get_ports SCROLL_LEDS[0]]
        

# LEDs for Command Byte Data
set_property PACKAGE_PIN W18 [get_ports COMMAND_LEDS[0]]
        set_property IOSTANDARD LVCMOS33 [get_ports COMMAND_LEDS[0]]
set_property PACKAGE_PIN U15 [get_ports COMMAND_LEDS[1]]
        set_property IOSTANDARD LVCMOS33 [get_ports COMMAND_LEDS[1]]
set_property PACKAGE_PIN U14 [get_ports COMMAND_LEDS[2]]
        set_property IOSTANDARD LVCMOS33 [get_ports COMMAND_LEDS[2]]
set_property PACKAGE_PIN V14 [get_ports COMMAND_LEDS[3]]
        set_property IOSTANDARD LVCMOS33 [get_ports COMMAND_LEDS[3]] 

# 7 Segment What Number to Display
set_property PACKAGE_PIN U2 [get_ports SEG_SELECT[3]]
        set_property IOSTANDARD LVCMOS33 [get_ports SEG_SELECT[3]]
set_property PACKAGE_PIN U4 [get_ports SEG_SELECT[2]]
        set_property IOSTANDARD LVCMOS33 [get_ports SEG_SELECT[2]]
set_property PACKAGE_PIN V4 [get_ports SEG_SELECT[1]]
        set_property IOSTANDARD LVCMOS33 [get_ports SEG_SELECT[1]]
set_property PACKAGE_PIN W4 [get_ports SEG_SELECT[0]]
        set_property IOSTANDARD LVCMOS33 [get_ports SEG_SELECT[0]]
       
# 7 Segment What to Display
set_property PACKAGE_PIN W7 [get_ports HEX_OUT[0]]
        set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[0]]
set_property PACKAGE_PIN W6 [get_ports HEX_OUT[1]]
        set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[1]]
set_property PACKAGE_PIN U8 [get_ports HEX_OUT[2]]
        set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[2]]
set_property PACKAGE_PIN V8 [get_ports HEX_OUT[3]]
        set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[3]]
set_property PACKAGE_PIN U5 [get_ports HEX_OUT[4]]
        set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[4]]
set_property PACKAGE_PIN V5 [get_ports HEX_OUT[5]]
        set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[5]]
set_property PACKAGE_PIN U7 [get_ports HEX_OUT[6]]
        set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[6]]
set_property PACKAGE_PIN V7 [get_ports HEX_OUT[7]]
        set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[7]]
           
 
# HS and VS
set_property PACKAGE_PIN P19 [get_ports HS]
        set_property IOSTANDARD LVCMOS33 [get_ports HS] 
set_property PACKAGE_PIN R19 [get_ports VS]
        set_property IOSTANDARD LVCMOS33 [get_ports VS]

# COLOUR_OUT for the VGA
set_property PACKAGE_PIN G19 [get_ports {COLOUR_OUT[0]}]
        set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[0]}]
set_property PACKAGE_PIN H19 [get_ports {COLOUR_OUT[1]}]
        set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[1]}]
set_property PACKAGE_PIN J19 [get_ports {COLOUR_OUT[2]}]
        set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[2]}]
set_property PACKAGE_PIN J17 [get_ports {COLOUR_OUT[3]}]
        set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[3]}]
set_property PACKAGE_PIN H17 [get_ports {COLOUR_OUT[4]}]
        set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[4]}]
set_property PACKAGE_PIN G17 [get_ports {COLOUR_OUT[5]}]
        set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[5]}]
set_property PACKAGE_PIN N18 [get_ports {COLOUR_OUT[6]}]
        set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[6]}]
set_property PACKAGE_PIN L18 [get_ports {COLOUR_OUT[7]}]
        set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[7]}]
    
# IR Pins    
set_property PACKAGE_PIN G2 [get_ports {IR_LED}]
        set_property IOSTANDARD LVCMOS33 [get_ports {IR_LED}]

            