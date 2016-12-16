library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.typedefs.all;

entity vga is
  port(
    clk     : in  std_logic;
    rst     : in  std_logic;
    r_in    : in  std_logic;
    g_in    : in  std_logic;
    b_in    : in  std_logic;
    r_out   : out std_logic;
    g_out   : out std_logic;
    b_out   : out std_logic;
    h_sync  : out std_logic := '0';
    v_sync  : out std_logic := '0';
    visible : buffer std_logic;
    x_pos   : out unsigned(9 downto 0);
    y_pos   : out unsigned(9 downto 0)
  );
end entity vga;

architecture arch of vga is
  constant H_SYNC_CYC   : integer := 96;
  constant H_SYNC_BACK  : integer := 45 + 3;
  constant H_SYNC_ACT   : integer := 646;
  constant H_SYNC_TOTAL : integer := 800;

  constant V_SYNC_CYC   : integer := 2;
  constant V_SYNC_BACK  : integer := 30 + 2;
  constant V_SYNC_ACT   : integer := 484;
  constant V_SYNC_TOTAL : integer := 525;

  constant X_START : integer := H_SYNC_CYC + H_SYNC_BACK + 4;
  constant Y_START : integer := V_SYNC_CYC + V_SYNC_BACK;

  signal h_cnt : unsigned(9 downto 0) := (others => '0');
  signal v_cnt : unsigned(9 downto 0) := (others => '0');

begin
  h_sync_gen : process(clk, rst) is
  begin
    if rst = '1' then
      h_cnt  <= (others => '0');
      h_sync <= '0';
    elsif rising_edge(clk) then
		h_cnt <= sel(h_cnt < H_SYNC_TOTAL, h_cnt + 1, to_unsigned(0, h_cnt'length));
		h_sync <= to_std_logic(h_cnt >= H_SYNC_CYC);
    end if;
  end process;

  v_sync_gen : process(clk, rst) is
  begin
    if rst = '1' then
      v_cnt  <= (others => '0');
      v_sync <= '0';
    elsif rising_edge(clk) then
      if h_cnt = 0 then
		  v_cnt <= sel(v_cnt < V_SYNC_TOTAL, v_cnt + 1, to_unsigned(0, h_cnt'length));
		  v_sync <= to_std_logic(v_cnt >= V_SYNC_CYC);
      end if;
    end if;
  end process;

  visible <= to_std_logic(
    h_cnt >= X_START + 9 and 
    h_cnt < X_START + H_SYNC_ACT + 9 and 
    v_cnt >= Y_START and 
    v_cnt < Y_START + V_SYNC_ACT
  );

  image_gen: process(clk, rst) is
  begin
    if rst = '1' then
	   x_pos <= (others => '0');
		y_pos <= (others => '0');
		r_out <= '0';
		g_out <= '0';
		b_out <= '0';
	 elsif rising_edge(clk) then
      x_pos <= h_cnt - 139;
	   y_pos <= v_cnt - 34;

	   r_out <= sel(visible = '1', r_in, '0');
	   g_out <= sel(visible = '1', g_in, '0');
	   b_out <= sel(visible = '1', b_in, '0');
    end if;
  end process;

end architecture arch;
