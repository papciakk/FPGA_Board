library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.typedefs.all;

entity keyboard_inputs is
  port(
    clk      : in  std_logic;
    rst      : in  std_logic;
    ps2_clk  : in  std_logic;
    ps2_data : in  std_logic;
    key      : out std_logic_vector(7 downto 0);
    error    : out std_logic;
    scancode : buffer unsigned(7 downto 0)
  );
end entity keyboard_inputs;

architecture arch of keyboard_inputs is
  signal break_code : std_logic := '0';
  signal code_ready : std_logic;
begin
  ps2_keyboard : entity work.ps2_keyboard
    port map(
      clk        => clk,
      rst        => rst,
      ps2_clk    => ps2_clk,
      ps2_data   => ps2_data,
      error      => error,
      code_ready => code_ready,
      code       => scancode
    );

  process(code_ready, rst) is
  begin
    if rst = '1' then
      break_code <= '0';
      key        <= (others => '0');
    elsif rising_edge(code_ready) then
      case scancode is
        when X"1D" =>
          key(KEY_W) <= not break_code;
        when X"1B" =>
          key(KEY_S) <= not break_code;
        when X"1C" =>
          key(KEY_A) <= not break_code;
        when X"23" =>
          key(KEY_D) <= not break_code;
        when X"15" =>
          key(KEY_Q) <= not break_code;
        when X"24" =>
          key(KEY_E) <= not break_code;
        when X"1A" =>
          key(KEY_Z) <= not break_code;
        when X"22" =>
          key(KEY_X) <= not break_code;
        when X"F0" =>
          break_code <= '1';
        when others =>
      end case;

      if scancode /= X"F0" then
        break_code <= '0';
      end if;
    end if;
  end process;

end architecture arch;
