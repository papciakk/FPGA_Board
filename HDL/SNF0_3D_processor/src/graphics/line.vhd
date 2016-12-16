library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.typedefs.all;

entity line is
  port(
    clk            : in  std_logic;
    rst            : in  std_logic;
    x0, y0, x1, y1 : in  signed(31 downto 0);
    x_out, y_out   : out unsigned(9 downto 0);
    start          : in  std_logic;
    done, plot     : out std_logic
  );
end entity line;

architecture arch of line is
  signal s_x0, s_y0, s_x1, s_y1  : signed(31 downto 0);
  signal s1_x0, s1_y0, s1_x1, s1_y1 : signed(31 downto 0);
  signal in_loop, brk            : std_logic;
  signal e2                      : signed(31 downto 0);
  signal x1_m_x0                 : signed(31 downto 0);
  signal y1_m_y0                 : signed(31 downto 0);
  signal dx, dy                  : signed(31 downto 0);
  signal right, down             : std_logic;
  signal g2_gt_dy, e2_lt_dx      : std_logic;
  signal err                     : signed(31 downto 0);
  signal err_loop, err_loop_part : signed(31 downto 0);
  signal err_next                : signed(31 downto 0);
  signal x, y                    : signed(31 downto 0);
  signal x_loop, x_loop_part     : signed(31 downto 0);
  signal y_loop, y_loop_part     : signed(31 downto 0);
  signal x_next, y_next          : signed(31 downto 0);

  type line_generator_state is (idle, running, ready);
  signal state : line_generator_state;

begin
  s1_x0 <= to_signed(639, 32) when x0 > 639 else x0;
  s1_y0 <= to_signed(479, 32) when y0 > 479 else y0;
  s1_x1 <= to_signed(639, 32) when x1 > 639 else x1;
  s1_y1 <= to_signed(479, 32) when y1 > 479 else y1;

  s_x0 <= to_signed(0, 32) when x0 < 0 else s1_x0;
  s_y0 <= to_signed(0, 32) when y0 < 0 else s1_y0;
  s_x1 <= to_signed(0, 32) when x1 < 0 else s1_x1;
  s_y1 <= to_signed(0, 32) when y1 < 0 else s1_y1;

  process(clk, rst, brk, start, state) is
  begin
    if rst = '1' then
      state <= idle;
    elsif falling_edge(clk) then
      case state is
        when idle =>
          if start = '1' then
            state <= running;
          else
            state <= idle;
          end if;
        when running =>
          if brk = '1' then
            state <= ready;
          else
            state <= running;
          end if;
        when ready =>
          if start = '1' then
            state <= running;
          else
            state <= idle;
          end if;
      end case;
    end if;
  end process;

  process(clk, rst)
  begin
    if rst = '1' then
	  x   <= (others => '0');
	  y   <= (others => '0');
	  err <= (others => '0');
    elsif falling_edge(clk) then
      x   <= x_next;
      y   <= y_next;
      err <= err_next;
    end if;
  end process;

  in_loop <= to_std_logic(state = running);

  x1_m_x0 <= s_x1 - s_x0;
  y1_m_y0 <= s_y1 - s_y0;

  right <= to_std_logic(x1_m_x0 > 0);
  down <= to_std_logic(y1_m_y0 > 0);

  dx <= x1_m_x0 when right = '1' else -x1_m_x0;
  dy <= -y1_m_y0 when down = '1' else y1_m_y0;

  e2 <= err(30 downto 0) & "0";
  g2_gt_dy <= to_std_logic(e2 > dy);
  e2_lt_dx <= to_std_logic(e2 < dx);

  err_loop_part <= err + dy when g2_gt_dy = '1' else err;
  err_loop      <= err_loop_part + dx when e2_lt_dx = '1' else err_loop_part;
  err_next      <= dx + dy when in_loop = '0' else err_loop;

  x_loop      <= x_loop_part when g2_gt_dy = '1' else x;
  x_loop_part <= x + 1 when right = '1' else x - 1;
  x_next      <= s_x0 when in_loop = '0' else x_loop;

  y_loop      <= y_loop_part when e2_lt_dx = '1' else y;
  y_loop_part <= y + 1 when down = '1' else y - 1;
  y_next      <= s_y0 when in_loop = '0' else y_loop;

  brk <= to_std_logic(x = s_x1 and y = s_y1);

  
  x_out <= unsigned(x(9 downto 0));
  y_out <= unsigned(y(9 downto 0));
  plot  <= in_loop;
  done  <= to_std_logic(state = ready);

end architecture arch;
