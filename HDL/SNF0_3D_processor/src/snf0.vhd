library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;
use work.typedefs.all;

entity snf0 is
  port(
    CLK_50     : in    std_logic;
    CLK_50_2   : in    std_logic;
    VGA2_R     : out   std_logic;
    VGA2_G     : out   std_logic;
    VGA2_B     : out   std_logic;
    VGA2_HSync : out   std_logic;
    VGA2_VSync : out   std_logic;
    PS2_CLK    : inout std_logic;
    PS2_DATA   : inout std_logic;
    UART_RXD   : in    std_logic;
    UART_TXD   : out   std_logic;
    BTN        : in    std_logic_vector(1 downto 0);
    LED        : out   std_logic_vector(2 downto 0)
  );

end snf0;

architecture behavioral of snf0 is
  -- clocks
  signal clk_vga     : std_logic;
  signal clk_main    : std_logic;
  signal vram_wr_clk : std_logic := clk_main;
  signal vram_rd_clk : std_logic := clk_vga;

  -- VGA
  signal vga_r, vga_g, vga_b  : std_logic;
  signal vga_x_pos, vga_y_pos : vga_pos_t;
  signal vga_visible          : std_logic;

  -- frame buffers
  signal vram_wr_addr   : vram_addr_t;
  signal vram_rd_addr   : vram_addr_t;
  signal vram_wr_enable : vram_bit_t;
  signal vram_rd_enable : vram_bit_t;
  signal vram_wr_data   : vram_data_t;
  signal vram_rd_data   : vram_data_t;

  -- line generator
  signal edge_x0, edge_y0         : signed(31 downto 0);
  signal edge_x1, edge_y1         : signed(31 downto 0);
  signal edge_draw, edge_is_drawn : std_logic;
  signal edge_put_pixel           : std_logic;
  signal edge_pos_x, edge_pos_y   : vga_pos_t;
  signal edge_reset               : std_logic;

  -- transformer
  signal start, rendered       : std_logic;
  signal edge_ready, next_edge : std_logic;
  signal update_rot            : std_logic;
  signal x0, y0, x1, y1        : signed(31 downto 0);

  -- inputs
  signal rot_x, rot_y, rot_z : angle_t;
  signal scale               : signed(31 downto 0);
  signal scale_in            : byte;

  signal key : std_logic_vector(7 downto 0);

  signal vdata_in_0  : std_logic_vector(0 downto 0);
  signal vdata_out_0 : std_logic_vector(0 downto 0);
  signal vdata_in_1  : std_logic_vector(0 downto 0);
  signal vdata_out_1 : std_logic_vector(0 downto 0);

begin
  vga_pll_0 : entity work.vga_pll
    port map(
      inclk0 => CLK_50,
      c0     => clk_vga
    );

  clk_main <= CLK_50;
  scale    <= signed(resize(scale_in, 32));

  vga_0 : entity work.vga
    port map(
      clk     => clk_vga,
      rst     => '0',
      r_in    => vga_r,
      g_in    => vga_g,
      b_in    => vga_b,
      r_out   => VGA2_R,
      g_out   => VGA2_G,
      b_out   => VGA2_B,
      h_sync  => VGA2_HSync,
      v_sync  => VGA2_VSync,
      visible => vga_visible,
      x_pos   => vga_x_pos,
      y_pos   => vga_y_pos
    );

  vdata_in_0(0)   <= vram_wr_data(0);
  vram_rd_data(0) <= vdata_out_0(0);
  vdata_in_1(0)   <= vram_wr_data(1);
  vram_rd_data(1) <= vdata_out_1(0);

  vram_0 : entity work.vram
    port map(
      wrclock   => vram_wr_clk,
      wren      => vram_wr_enable(0),
      wraddress => std_logic_vector(vram_wr_addr(0)),
      data      => vdata_in_0,
      rdclock   => vram_rd_clk,
      rden      => vram_rd_enable(0),
      rdaddress => std_logic_vector(vram_rd_addr(0)),
      q         => vdata_out_0
    );

  vram_1 : entity work.vram
    port map(
      wrclock   => vram_wr_clk,
      wren      => vram_wr_enable(1),
      wraddress => std_logic_vector(vram_wr_addr(1)),
      data      => vdata_in_1,
      rdclock   => vram_rd_clk,
      rden      => vram_rd_enable(1),
      rdaddress => std_logic_vector(vram_rd_addr(1)),
      q         => vdata_out_1
    );

  line_0 : entity work.line
    port map(
      clk   => clk_main,
      rst   => edge_reset,
      x0    => edge_x0,
      y0    => edge_y0,
      x1    => edge_x1,
      y1    => edge_y1,
      x_out => edge_pos_x,
      y_out => edge_pos_y,
      start => edge_draw,
      done  => edge_is_drawn,
      plot  => edge_put_pixel
    );

  transformer_0 : transformer
    port map(
      clk        => clk_main,
      rst        => '0',
      update_rot => update_rot,
      start      => start,
      next_edge  => next_edge,
      edge_ready => edge_ready,
      rendered   => rendered,
      rot_x      => rot_x,
      rot_y      => rot_y,
      rot_z      => rot_z,
      scale      => scale,
      x0         => x0,
      y0         => y0,
      x1         => x1,
      y1         => y1,
		LED => LED
    );

  display_controler_0 : entity work.display_controller
    port map(
      clk_main       => clk_main,
      clk_vga        => clk_vga,
      rst            => '0',
      vga_r          => vga_r,
      vga_g          => vga_g,
      vga_b          => vga_b,
      vga_x_pos      => vga_x_pos,
      vga_y_pos      => vga_y_pos,
      vga_visible    => vga_visible,
      vram_rd_addr   => vram_rd_addr,
      vram_wr_addr   => vram_wr_addr,
      vram_wr_enable => vram_wr_enable,
      vram_rd_enable => vram_rd_enable,
      vram_wr_data   => vram_wr_data,
      vram_rd_data   => vram_rd_data,
      edge_x0        => edge_x0,
      edge_y0        => edge_y0,
      edge_x1        => edge_x1,
      edge_y1        => edge_y1,
      edge_draw      => edge_draw,
      edge_is_drawn  => edge_is_drawn,
      edge_put_pixel => edge_put_pixel,
      edge_pos_x     => edge_pos_x,
      edge_pos_y     => edge_pos_y,
      edge_reset     => edge_reset,
      start          => start,
      next_edge      => next_edge,
      rendered       => rendered,
      edge_ready     => edge_ready,
      x0             => x0,
      y0             => y0,
      x1             => x1,
      y1             => y1
    );

  keyboard_inputs_0 : entity work.keyboard_inputs
    port map(
      clk      => clk_main,
      rst      => '0',
      ps2_clk  => PS2_CLK,
      ps2_data => PS2_DATA,
      key      => key
    );

  input_handler_0 : entity work.input_handler
    generic map(
      rot_x_init  => 0,
      rot_y_init  => 90,
      rot_z_init  => 90,
      scale_init  => 10,
      input_delay => 1200
    )
    port map(
      rst         => '0',
      key         => key,
      vga_visible => vga_visible,
      rot_x       => rot_x,
      rot_y       => rot_y,
      rot_z       => rot_z,
      scale       => scale_in,
      update_rot  => update_rot
    );


end architecture;