library IEEE;
use IEEE.std_logic_1164.all;

entity DRE is 
  generic (N : natural := 32);
  port (
    Single_Rail : in  std_logic_vector (N - 1 downto 0);
    Dual_Rail   : out std_logic_vector (2*N - 1 downto 0)
  );
end DRE;

architecture Behavioral of DRE is
  constant  Disabled : std_logic := 'Z';
begin

  process (Single_Rail)
  begin
    for i in N - 1 downto 0 loop
      if (Single_Rail(i) = Disabled) then
        -- Set DRE's output to all zeros
        Dual_Rail <= (others => '0');
        exit;
      else
        -- and CU_Control and CD_Control;
        Dual_Rail(i)      <=      Single_Rail(i);
        Dual_Rail(i + N)  <=  not Single_Rail(i);
      end if;
    end loop;
  end process;
  
end architecture Behavioral;