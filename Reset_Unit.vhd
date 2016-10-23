library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Reset_Unit is
  port (
    Reset     : in  std_logic;
    Flush     : in  std_logic;
    Reset_F   : out std_logic;
    Reset_D   : out std_logic;
    Reset_E   : out std_logic;
    Reset_M   : out std_logic;
    Reset_W   : out std_logic;
    Reset_RF  : out std_logic;
    Reset_PC  : out std_logic;
    Reset_HU  : out std_logic;
    Start_PL  : out std_logic -- pipeline
  );
end entity Reset_Unit;

architecture Behavioral of Reset_Unit is
  constant  Delay_Reset : time      := 5 ns;
  signal    Reset_Hold  : std_logic := '0';
begin
  process (Reset)
  begin
    if (Reset = '1') then
      Start_PL    <= '0';
      Reset_Hold  <= '1';
    elsif (Reset = '0') then
      Start_PL    <= '1';
      Reset_Hold  <= '0'                                  after     Delay_Reset;
      Start_PL    <= '0'                                  after 2 * Delay_Reset;
    end if;
  end process;
  
  Reset_F   <=  Reset_Hold; -- or Flush;
  Reset_D   <=  Reset_Hold; -- or Flush;
  Reset_E   <=  Reset_Hold;
  Reset_M   <=  Reset_Hold;
  Reset_W   <=  Reset_Hold;
  Reset_PC  <=  Reset_Hold;
  Reset_RF  <=  Reset_Hold;
  Reset_HU  <=  Reset_Hold;
  
end architecture Behavioral;