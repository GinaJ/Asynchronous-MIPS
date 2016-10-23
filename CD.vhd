library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;

entity CD is
  generic (N : natural := 32);
  port(
    Dual_Rail   : in  std_logic_vector(2*N - 1 downto 0);
    Valid_Data  : out std_logic
  );
end CD;

architecture Behavioral of CD is
  
  constant  Delay_CD  : time := 50 ps;
  
  signal    xored     : std_logic_vector (N - 1 downto 0);
  
begin
  
  xor_generate:
    for i in N - 1 downto 0 generate
      xored(i) <= Dual_Rail(i) xor Dual_Rail(i + N);
    end generate xor_generate;
  
  Valid_Data <= AND_REDUCE (xored)                               after Delay_CD;
  
end Behavioral;