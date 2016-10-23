library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;

entity WriteBack is
  port(
    Reset       : in  std_logic;
    Start       : in  std_logic;
    Enable      : in  std_logic;
    Valid_Data  : in  std_logic;
    
    -- From Memory
    Addr_T_Mem  : in  std_logic_vector ( 4 downto 0);
    Result_Mem  : in  std_logic_vector (31 downto 0);
    
    -- To Register File
    Addr_T_Reg  : out std_logic_vector ( 4 downto 0);
    Result_Reg  : out std_logic_vector (31 downto 0);
    
    -- Register File handshake
    Req_RegFile : out std_logic;
    Ack_RegFile : in  std_logic
  );
end WriteBack;

architecture Behavioral of WriteBack is
  
  constant  Delay_WBack : time                          :=  1 ns;
  
  constant  Register_R0 : std_logic_vector(4 downto 0)  :=  "00000";
  constant  Rst_Value   : std_logic                     :=  '0';
  constant  Disabled    : std_logic                     :=  'Z';
  
begin
  
  process (Reset, Start, Enable, Valid_Data, Ack_RegFile)
  begin
  
    if (Reset = '1') then
      Req_RegFile <= Rst_Value;
      Addr_T_Reg  <= (others => Rst_Value);
      Result_Reg  <= (others => Rst_Value);
      
    elsif (Start = '1') then
      Req_RegFile <= '1'                                      after Delay_WBack;
      
    elsif (Enable = '1' and Valid_Data = '1') then
      Addr_T_Reg  <= Addr_T_Mem;
      Result_Reg  <= Result_Mem;
      Req_RegFile <= '1'                                      after Delay_WBack;
    
    elsif (Enable = '1' and Valid_Data = '0') then
      -- Keep current outputs
    
    elsif (Enable = '0') then
      Req_RegFile <= '0'                                      after Delay_WBack;
      Addr_T_Reg  <= (others => Disabled)                     after Delay_WBack;
      Result_Reg  <= (others => Disabled)                     after Delay_WBack;
      
    end if;
  
  end process;
  
end Behavioral;