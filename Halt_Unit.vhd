library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Halt_Unit is
  port (
    Reset     : in  std_logic;
    Halt_Req  : in  std_logic;
    Halt      : out std_logic
  );
end entity Halt_Unit;

architecture Behavioral of Halt_Unit is

  constant  Rst_Value  :  std_logic :=  '0';
  signal    Halt_State :  std_logic;
  
begin

  process (Reset, Halt_Req)
  begin
  
    if (Reset = '1') then
      Halt_State  <=  Rst_Value;
    elsif (Halt_Req = '1') then
      Halt_State  <=  Halt_Req;
    end if;
    
  end process;
  
  Halt <= Halt_State;
  
end architecture Behavioral;