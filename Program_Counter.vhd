library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Program_Counter is
  port (
    Reset     : in  std_logic;
    PC_load   : in  std_logic;
    PC_next   : in  std_logic;
    PC_in     : in  std_logic_vector (31 downto 0);
    PC_out    : out std_logic_vector (31 downto 0)
  );
end entity Program_Counter;

architecture Behavioral of Program_Counter is
  constant  Default_PC  : std_logic_vector (31 downto 0) := (others => '0');
  signal    PC_value    : std_logic_vector (31 downto 0);
begin
  process (Reset, PC_load, PC_next)
  begin
    if (Reset = '1') then
      PC_value <= Default_PC;
    elsif (PC_load'event and PC_load = '1') then
      PC_value <= PC_in;
    elsif (PC_next'event and PC_next = '1' and PC_load = '0') then
      PC_value <= std_logic_vector (unsigned (PC_value) + 4);
    end if;
  end process;
  
  PC_out <= PC_value;
  
end architecture Behavioral;