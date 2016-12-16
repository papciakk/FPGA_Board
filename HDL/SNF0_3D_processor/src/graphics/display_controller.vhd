library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.typedefs.all;

entity display_controller is
  port(
    clk_main       : in  std_logic;
    clk_vga        : in  std_logic;
    rst            : in  std_logic;
    vga_r          : out std_logic;
    vga_g          : out std_logic;
    vga_b          : out std_logic;
    vga_x_pos      : in  vga_pos_t;
    vga_y_pos      : in  vga_pos_t;
    vga_visible    : in  std_logic;
    vram_rd_addr   : out vram_addr_t           := (others => (others => '0'));
    vram_wr_addr   : buffer vram_addr_t        := (others => (others => '0'));
    vram_wr_enable : buffer vram_bit_t;
    vram_rd_enable : buffer vram_bit_t;
    vram_wr_data   : out vram_data_t            := (others => '0');
    vram_rd_data   : in  vram_data_t;
    edge_x0        : out signed(31 downto 0) := (others => '0');
    edge_y0        : out signed(31 downto 0) := (others => '0');
    edge_x1        : out signed(31 downto 0) := (others => '0');
    edge_y1        : out signed(31 downto 0) := (others => '0');
    edge_draw      : out std_logic             := '0';
    edge_is_drawn  : in  std_logic;
    edge_put_pixel : in  std_logic;
    edge_pos_x     : in  vga_pos_t;
    edge_pos_y     : in  vga_pos_t;
    edge_reset     : out std_logic             := '1';
    start          : out std_logic;
    next_edge      : out std_logic;
    rendered       : in  std_logic;
    edge_ready     : in  std_logic;
    x0, y0, x1, y1 : in  signed(31 downto 0)
  );
end entity display_controller;

architecture arch of display_controller is
  type display_controller_state is (
    start_draw, clear, start_trasform,
    transform_wait, load, init_draw,
    draw_edge, frame_rendered
  );
  
  constant BUFFER_1 : std_logic := '0';
  constant BUFFER_2 : std_logic := '1';

  signal draw_buffer     : std_logic := BUFFER_1;
  signal swap_buffers    : std_logic := '0';
  signal wr_buff_id      : integer;
  signal rd_buff_id      : integer;
  signal addr_edge_pixel : addr19_t;
  signal color           : std_logic;

  signal state : display_controller_state := start_draw;

begin
  wr_buff_id <= 1 when draw_buffer = '0' else 0;
  rd_buff_id <= 1 when draw_buffer = '1' else 0;

  vram_wr_enable(0) <= to_std_logic(draw_buffer /= BUFFER_1);
  vram_wr_enable(1) <= to_std_logic(draw_buffer /= BUFFER_2);

  vram_rd_enable(0) <= to_std_logic(draw_buffer = BUFFER_1 and vga_visible = '1');
  vram_rd_enable(1) <= to_std_logic(draw_buffer = BUFFER_2 and vga_visible = '1');

  addr_edge_pixel <= resize(unsigned(edge_pos_y * 640 + edge_pos_x), 19);

  process(clk_vga, rst) is
  begin
    if rst = '1' then
      vga_r        <= '0';
      vga_g        <= '0';
      vga_b        <= '0';
      vram_rd_addr <= (others => (others => '0'));
      swap_buffers <= '0';
    elsif rising_edge(clk_vga) then
      color <= to_std_logic(vram_rd_data(rd_buff_id) = '1');
      --color <= vram_rd_data(rd_buff_id);
      vga_r <= color;
      vga_g <= color;
      vga_b <= color;

      if vga_visible = '1' then
        vram_rd_addr(rd_buff_id) <= vga_y_pos * 640 + vga_x_pos;
      end if;

      --swap_buffers <= '1' when (vga_x_pos = 639 and vga_y_pos = 479) else '0';
      swap_buffers <= to_std_logic((vga_x_pos = 639 and vga_y_pos = 479));

    end if;
  end process;

  process(clk_main, rst) is
  begin
    if rst = '1' then
      vram_wr_addr <= (others => (others => '0'));
      vram_wr_data <= (others => '0');
      edge_x0      <= (others => '0');
      edge_y0      <= (others => '0');
      edge_x1      <= (others => '0');
      edge_y1      <= (others => '0');
      edge_draw    <= '0';
      edge_reset   <= '1';
      draw_buffer  <= '0';
      state        <= start_draw;
    elsif falling_edge(clk_main) then
      case state is
        when start_draw =>
          start                    <= '1';
          vram_wr_addr(wr_buff_id) <= (others => '0');

          state <= clear;

        when clear =>
          start                    <= '0';
          vram_wr_addr(wr_buff_id) <= vram_wr_addr(wr_buff_id) + 1;
          vram_wr_data(wr_buff_id) <= '0';

          if vram_wr_addr(wr_buff_id) > 307200 then
            vram_wr_addr(wr_buff_id) <= (others => '0');

            state <= load;
          end if;

        when start_trasform =>
          edge_reset <= '1';

          if rendered = '0' then
            next_edge <= '1';
            state     <= transform_wait;
          else
            state <= frame_rendered;
          end if;

        when transform_wait =>
          next_edge <= '0';

          if rendered = '1' then
            state <= frame_rendered;
          elsif edge_ready = '1' then
            state <= load;
          end if;

        when load =>
          edge_reset <= '0';

          edge_x0 <= x0;
          edge_y0 <= y0;
          edge_x1 <= x1;
          edge_y1 <= y1;

          state <= init_draw;

        when init_draw =>
          edge_draw <= '1';
          state     <= draw_edge;

        when draw_edge =>
          edge_draw <= '0';

          if edge_is_drawn = '0' then
            vram_wr_addr(wr_buff_id) <= addr_edge_pixel;
            vram_wr_data(wr_buff_id) <= edge_put_pixel;
          else
            edge_draw <= '0';
            state     <= start_trasform;
          end if;

        when frame_rendered =>
          if swap_buffers = '1' then
            draw_buffer <= not draw_buffer;
            state       <= start_draw;
          end if;

      end case;
    end if;
  end process;

end architecture arch;


