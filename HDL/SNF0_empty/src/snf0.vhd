library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity snf0 is
  port(
    CLK_50         : in    std_logic;
    CLK_50_2       : in    std_logic;
    
    PS2_CLK        : inout std_logic;
    PS2_DATA       : inout std_logic;
    
    UART_RXD       : in    std_logic;
    UART_TXD       : out   std_logic;
    
    SRAM_CLK       : out   std_logic;
    SRAM_ADDR      : out   std_logic_vector(0 to 18);
    SRAM_DQ        : inout std_logic_vector(0 to 31);
    SRAM_PAR       : inout std_logic_vector(0 to 3);
    SRAM_MODE      : out   std_logic;
    SRAM_ADSC_n    : out   std_logic;
    SRAM_ADSP_n    : out   std_logic;
    SRAM_ADV_n     : out   std_logic;
    SRAM_BWE_n     : out   std_logic;
    SRAM_CE2_n     : out   std_logic;
    SRAM_CE_n      : out   std_logic;
    SRAM_OE_n      : out   std_logic;
    SRAM_ZZ        : out   std_logic;
    
    VGA1_PIXEL_CLK : in    std_logic;
    VGA1_CS_n      : out   std_logic;
    VGA1_DC_n      : out   std_logic;
    VGA1_E_n       : out   std_logic;
    VGA1_RESET_n   : out   std_logic;
    VGA1_RW_n      : out   std_logic;
    VGA1_TE        : in    std_logic;
    VGA1_R         : out   std_logic_vector(0 to 7);
    VGA1_G         : out   std_logic_vector(0 to 7);
    VGA1_B         : out   std_logic_vector(0 to 7);
    
    VGA2_R         : out   std_logic;
    VGA2_G         : out   std_logic;
    VGA2_B         : out   std_logic;
    VGA2_VSync     : out   std_logic;
    VGA2_HSync     : out   std_logic;
    
    BTN            : in    std_logic_vector(1 downto 0);
    LED            : out   std_logic_vector(2 downto 0);
    GPIO           : inout std_logic_vector(0 to 3);
    GPI            : in    std_logic_vector(0 to 7)
       
    );

end snf0;

architecture behavioral of snf0 is
begin
end architecture;