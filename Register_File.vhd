library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Register_File is
  Port ( 
    -- From/To Decode Unit
    Rs_Addr   : in  std_logic_vector ( 4 downto 0);
    Rt_Addr   : in  std_logic_vector ( 4 downto 0);
    Rs_Data   : out std_logic_vector (31 downto 0);
    Rt_Data   : out std_logic_vector (31 downto 0);

    Req_Read  : in  std_logic;
    Ack_Read  : out std_logic;

    -- From/To WriteBack Unit
    Rd_Addr   : in  std_logic_vector ( 4 downto 0);
    Rd_Data   : in  std_logic_vector (31 downto 0);

    Req_Write : in  std_logic;
    Ack_Write : out std_logic;

    -- From control
    Reset     : in  std_logic
  );
end Register_File;

architecture Behavioral of Register_File is

  constant  Delay_RegF  : time      :=  1 ns;
  constant  Disabled    : std_logic :=  'Z';
  constant  Rst_Value   : std_logic :=  '0';

  -- The register bank
  type      Reg_t is array (0 to 31) of std_logic_vector (31 downto 0);
  signal    RegBank     : Reg_t;

  signal    DelayedR    : std_logic :=  '0';
  signal    DelayedW    : std_logic :=  '0';

  signal    Rs_AddrInt  : natural range 0 to 31;  -- To index the register bank
  signal    Rt_AddrInt  : natural range 0 to 31;  -- To index the register bank
  signal    Rd_AddrInt  : natural range 0 to 31;  -- To index the register bank

begin

  Rs_AddrInt  <=  to_integer (unsigned (Rs_Addr));
  Rt_AddrInt  <=  to_integer (unsigned (Rt_Addr));
  Rd_AddrInt  <=  to_integer (unsigned (Rd_Addr));

  WriteDelay : process (Reset, Req_Write)
  begin
    if (Reset = '0' and Req_Write = '1') then
      DelayedW  <=  '1'                                        after Delay_RegF;
    else
      DelayedW  <=  '0';
    end if;

  end process; 

  WriteOp : process  (Reset, DelayedW)
  begin
    if (Reset = '1') then
       -- Initialize all registers to Rst_Value
      RegBank   <=  (others => (others => Rst_Value));
      Ack_Write <=  Rst_Value;

    elsif (Reset = '0') then
      if (DelayedW = '1' and Req_Write = '1') then
      
        if (Rd_AddrInt /= 0) then -- Check that it is not Register R0
          RegBank (Rd_AddrInt)  <=  Rd_Data;
        end if;
        
        Ack_Write <=  '1'                                      after Delay_RegF;
        
      else  -- Req_Write = '0'
        Ack_Write <= '0';
      end if;
      
    end if;
    
  end process;

  ReadDelay : process (Reset, Req_Read)
  begin
  
    if (Reset = '0' and Req_Read = '1') then
      DelayedR  <=  '1'                                        after Delay_RegF;

    elsif (Reset = '0' and Req_Read = '0') then
      DelayedR  <=  '0';

    elsif (Reset = '1') then
      DelayedR  <=  Rst_Value;
    end if;
    
  end process;


  ReadOp : process (Reset, DelayedR)
  begin
    if (Reset = '1') then
      Rs_Data   <=  (others => Rst_Value);
      Rt_Data   <=  (others => Rst_Value);
      Ack_Read  <=  Rst_Value;
    elsif (Reset = '0') then
      if (DelayedR = '1') then 
        if  (Req_Write = '1') then
          -- Check if reading same register than writing: Rs
          if (Rs_AddrInt = Rd_AddrInt) then
            Rs_Data <=  Rd_Data;
          else
            Rs_Data <=  RegBank (Rs_AddrInt);
          end if;
          
          -- Check if reading same register than writing: Rt
          if (Rt_AddrInt = Rd_AddrInt) then
            Rt_Data <=  Rd_Data;
          else
            Rt_Data <=  RegBank (Rt_AddrInt);
          end if;

          Ack_Read <= '1'                                      after Delay_RegF; 

        else -- Req_Write = '0'
          Rs_Data   <=  RegBank (Rs_AddrInt);
          Rt_Data   <=  RegBank (Rt_AddrInt);
          Ack_Read  <=  '1'                                    after Delay_RegF; 
        end if;

      else  -- En_Read=0
        Ack_Read    <=  '0'; -- When Req_Read = '0'  then  Ack_Read = '0';
      end if; -- Read if
    
    end if;
    
  end process;

end Behavioral;