library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Control_Unit is
  port (
    Reset     : in  std_logic;
    
    -- Decode
    Halt_Req  : in  std_logic;
    
    -- Program Counter
    PC_load   : in  std_logic;
    PC_next   : in  std_logic;
    PC_in     : in  std_logic_vector (31 downto 0);
    PC_out    : out std_logic_vector (31 downto 0);
    
    -- Reset signals
    Reset_F   : out std_logic;
    Reset_D   : out std_logic;
    Reset_E   : out std_logic;
    Reset_M   : out std_logic;
    Reset_W   : out std_logic;
    Reset_RF  : out std_logic;
    
    -- Pipeline flow control
    Start     : out std_logic;
    Halt      : out std_logic
  );
end entity Control_Unit;

architecture Behavioral of Control_Unit is
  component Reset_Unit is
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
      Start_PL  : out std_logic
    );
  end component Reset_Unit;
  
  component Program_Counter is
    port (
      Reset     : in  std_logic;
      PC_load   : in  std_logic;
      PC_next   : in  std_logic;
      PC_in     : in  std_logic_vector (31 downto 0);
      PC_out    : out std_logic_vector (31 downto 0)
    );
  end component Program_Counter;
  
  component Halt_Unit is
    port (
      Reset     : in  std_logic;
      Halt_Req  : in  std_logic;
      Halt      : out std_logic
    );
  end component Halt_Unit;

--------------------------------------------------------------------------------
  
  signal  Reset_PC, 
          Reset_HU  : std_logic;

--------------------------------------------------------------------------------  
begin
  
  RU: Reset_Unit port map (Reset, PC_load, Reset_F, Reset_D, Reset_E, Reset_M,
                           Reset_W, Reset_RF, Reset_PC, Reset_HU, Start);
  
  PC: Program_Counter port map (Reset_PC, PC_load, PC_next, PC_in, PC_out);
  
  HU: Halt_Unit port map (Reset_HU, Halt_Req, Halt);
  
end architecture Behavioral;