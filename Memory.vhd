library IEEE;
use IEEE.std_logic_1164.all;

entity Memory is
  port ( 
    --Control Signals
    Reset         : in    std_logic;
    Enable        : in    std_logic;
    Valid_Data    : in    std_logic;

    --From Execute
    ResultEx      : in    std_logic_vector (31 downto 0); --The address to send to the cache 
    DataAddressEx : in    std_logic_vector (31 downto 0); --Less 5 significant bits represent the DestReg address
    MemAluEx      : in    std_logic;  --Mem operation or not
    RWEx          : in    std_logic;  --Read or Write

    --From/To Cache
    RnW_DM        : out   std_logic;
    Req_DM        : out   std_logic;
    Ack_DM        : in    std_logic;
    Addr_DM       : out   std_logic_vector (31 downto 0);
    Data_DM       : inout std_logic_vector (31 downto 0);

    --To Write Back
    DataWB        : out   std_logic_vector (31 downto 0); --The data to store in register, if any
    AddressWB     : out   std_logic_vector ( 4 downto 0)  --The reg in which store
  );
end Memory;

architecture Behavioral of Memory is
  
  constant  Delay_Memory  : time      :=  1 ns;
  
  constant  Rst_Value     : std_logic :=  '0';
  constant  Disabled      : std_logic :=  'Z';
  
  signal    ReadSent      : std_logic :=  '0'; --Signals to comunicate between the two proccess
  signal    WriteSent     : std_logic :=  '0';
  
begin
  process (Reset, Enable, Valid_Data) 
  begin
    if (Reset = '1') then
      AddressWB     <= (others => Rst_Value); --R0 address to WriteBack: Do nothing
      DataWB        <= (others => Rst_Value);

      Req_DM        <= '0';
      Data_DM       <= (others => 'Z'); --inout bus, so better to set it to HZ
      Addr_DM       <= (others => '0');
      RnW_DM        <= '0';

      ReadSent      <= '0';
      WriteSent     <= '0';

    elsif (Enable = '1' and Valid_Data = '1') then

      if (MemAluEx = '0') then -- Not a Memory operation: Do nothing in cache
        -- Directly pass data From Ex to WB
        DataWB    <= ResultEx                                after Delay_Memory;
        -- Less 5 significant bits represent the DestReg address
        AddressWB <= DataAddressEx (4 downto 0)              after Delay_Memory;

        Data_DM   <= (others => 'Z'); --inout bus, so better to set it to HZ

        ReadSent  <= '0';
        WriteSent <= '0';


      elsif (RWEx = '1') then -- Write operation
        --  R0 address to WriteBack: Do nothing
        AddressWB     <=  "00000"                            after Delay_Memory;
        -- The data on WriteBack wont be used
        DataWB        <=  (others =>'0')                     after Delay_Memory;

        Addr_DM       <=  ResultEx; --Address where to write
        Data_DM       <=  DataAddressEx;--Data to be written
        RnW_DM        <=  '0'; --write operation
        Req_DM        <=  '1'; --Send Req to Cache

        WriteSent     <=  '1'; --Notify to the other process
        ReadSent      <=  '0';

      elsif (RWEx = '0') then  -- Read operation
        -- Less 5 significant bits represent the DestReg address
        AddressWB     <=  DataAddressEx (4 downto 0)         after Delay_Memory;
        -- This data bus will be controlled by the other process
        DataWB        <=  (others => 'Z');

        Addr_DM       <=  ResultEx;           -- Address from where to read
        Data_DM       <=  (others => 'Z');    -- Controlled by the Cache
        RnW_DM        <=  '1';                -- Read operation
        Req_DM        <=  '1';                -- Send Req to cache
  
        ReadSent      <=  '1';                -- Notify to the other process
        WriteSent     <=  '0';

      end if;
    
    elsif (Enable = '1' and Valid_Data = '0') then
      -- Keep current outputs
    
    elsif (Enable = '0') then
    
      Req_DM      <=  '0'; -- Clear Req so Cache can clear Ack
      Data_DM     <=  (others => 'Z'); --inout bus, so better to set it to HZ

      DataWB      <=  (others => Disabled)                   after Delay_Memory; 
      AddressWB   <=  (others => Disabled)                   after Delay_Memory;

      ReadSent    <=  '0'                                    after Delay_Memory;
      WriteSent   <=  '0'                                    after Delay_Memory;
      
    end if;
    
  end process;

  process (Ack_DM) -- This process waits for the rising edge on ACKCache
  begin

    if (Ack_DM   = '1') then
      if (ReadSent = '1') then -- The other process sent a read Req
        -- Req_DM   <='0';
        -- This process controls this bus
        DataWB  <=  Data_DM                                  after Delay_Memory;

      elsif (WriteSent = '1') then -- The other process sent a Write Req
        -- Req_DM   <= '0';
        DataWB  <= (others => Disabled); -- The other process is controlling this bus

      else  -- Should never happen
        -- Req_DM   <= 'Z';
        DataWB  <= (others => Disabled); -- The other process is controlling this bus
      end if;

    else  -- When ack goes down do nothing
      DataWB  <= (others => Disabled); -- The other process is controlling this bus
      --Req_DM   <= 'Z';
    end if;
    
  end process;

end Behavioral;