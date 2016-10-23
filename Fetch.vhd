library IEEE;
use IEEE.std_logic_1164.all;

entity Fetch is
  port (
    Reset     : in  std_logic;
    Enable    : in  std_logic;
    PC_Value  : in  std_logic_vector (31 downto 0);
    Instr_Dec : out std_logic_vector (31 downto 0);
    
    -- RAM Handshake signals
    Ack_IM    : in  std_logic;
    Req_IM    : out std_logic;
    
    -- RAM Data and Address
    Data_IM   : in  std_logic_vector (31 downto 0);
    Addr_IM   : out std_logic_vector (31 downto 0)
  );
end entity;

architecture Behavioral of Fetch is
  
  constant  Delay_Fetch : time      :=  1 ns;
  
  constant  Rst_Value   : std_logic :=  '0';
  constant  Disabled    : std_logic :=  'Z';
  constant  Write_Mode  : std_logic :=  '0';
  constant  Read_Mode   : std_logic :=  '1';
  
begin
  
  process (Reset, Enable, PC_Value, Ack_IM)
  begin
  
    if (Reset = '1') then
      Instr_Dec <=  (others => Rst_Value);
      Req_IM    <=  Rst_Value;
      Addr_IM   <=  (others => 'Z');
    
    elsif (Enable = '1') then
      Req_IM    <=  '1';
      if (Ack_IM =  '1') then
        Instr_Dec <= Data_IM                                  after Delay_Fetch;
      end if;
      
    elsif (Enable = '0') then
      Req_IM    <= '0';
      Instr_Dec <= (others => Disabled)                       after Delay_Fetch;
    end if;
    
  end process;
  
  Addr_IM   <=  PC_Value;
  
end architecture Behavioral;