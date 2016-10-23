library IEEE;
use IEEE.std_logic_1164.all;

entity Decode is
  port (
    Enable        : in  std_logic;  -- From next CD
    Valid_Data    : in  std_logic;  -- From previous CD
    Reset         : in  std_logic;
    Instr_Fetch   : in  std_logic_vector (31 downto 0);
    
    -- Data from Register File
    Rs_RegFile    : in  std_logic_vector (31 downto 0);
    Rt_RegFile    : in  std_logic_vector (31 downto 0);
    
    -- Signals from / to Register File
    Ack_RegFile   : in  std_logic;
    Req_RegFile   : out std_logic;
    
    -- Address to Register File
    Rs_Address    : out std_logic_vector ( 4 downto 0);
    Rt_Address    : out std_logic_vector ( 4 downto 0);
    
    -- Data to Execute stage
    Op1_Exec      : out std_logic_vector (31 downto 0);
    Op2_Exec      : out std_logic_vector (31 downto 0);
    Op3_Exte_Exec : out std_logic_vector (31 downto 5);
    Op3_Base_Exec : out std_logic_vector ( 4 downto 0);
    
    -- Commands to Execute stage
    Arith_Exec    : out std_logic;  -- Enable Arithmetic in Execute
    Shift_Exec    : out std_logic;  -- Enable Shift in Execute
    Logic_Exec    : out std_logic;  -- Enable Logic in Execute
    Jump_Exec     : out std_logic;  -- Enable Jump in Execute
    BrCmp_Exec    : out std_logic;  -- Enable Branch & Compare in Execute
    Mem_Exec      : out std_logic;  -- Memory operation
    Opcode_Exec   : out std_logic_vector (1 downto 0);
    
    -- Requests to Control Unit
    Halt_Req_CU   : out std_logic
  );
end Decode;

architecture Behavioral of Decode is

  constant  Delay_Decode  : time                          :=  1 ns;
  
  constant  Register_R0   : std_logic_vector (4 downto 0) :=  "00000";
  constant  Rst_Value     : std_logic                     :=  '0';
  constant  Disabled      : std_logic                     :=  'Z';
  
begin
  
  process (Enable, Valid_Data, Reset, Instr_Fetch, Rs_RegFile, Rt_RegFile, 
           Ack_RegFile)
  begin  
    if (Reset = '1') then
      -- Commands to Register File
      Req_RegFile   <= Rst_Value;
      Rs_Address    <= (others => Rst_Value);
      Rt_Address    <= (others => Rst_Value);
      -- Data to Execute stage
      Op1_Exec      <= (others => Rst_Value);
      Op2_Exec      <= (others => Rst_Value);
      Op3_Exte_Exec <= (others => Rst_Value);
      Op3_Base_Exec <= Register_R0;
      -- Commands to Execute stage
      Arith_Exec    <= '0';
      Shift_Exec    <= '1';   -- Simulate SLL R0, R0, R0
      Logic_Exec    <= '0';
      Jump_Exec     <= '0';
      BrCmp_Exec    <= '0';
      Mem_Exec      <= '0';
      Opcode_Exec   <= "00";
      -- Requests to Control Unit
      Halt_Req_CU   <= Rst_Value;
    
    elsif (Enable = '1' and Valid_Data = '1') then
    
      Op3_Exte_Exec <=  (others => Rst_Value)                after Delay_Decode;
      Arith_Exec    <=  Rst_Value                            after Delay_Decode;
      Shift_Exec    <=  Rst_Value                            after Delay_Decode;
      Logic_Exec    <=  Rst_Value                            after Delay_Decode;
      Jump_Exec     <=  Rst_Value                            after Delay_Decode;
      BrCmp_Exec    <=  Rst_Value                            after Delay_Decode;
      Mem_Exec      <=  Rst_Value                            after Delay_Decode;
      Opcode_Exec   <=  (others => Rst_Value)                after Delay_Decode;
    
      case Instr_Fetch (31 downto 26) is
        when "000000"     => -- R-type instruction
          
          case Instr_Fetch (5 downto 0) is
            when "100000" =>  -- ADD
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Arith_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "00"                       after Delay_Decode;
              end if;
            when "100001" =>  -- ADDU
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Arith_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "01"                       after Delay_Decode;
              end if;
            when "100100" =>  -- AND
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Logic_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "00"                       after Delay_Decode;
              end if;
--------------------------------------------------------------------------------
--          when "001001" =>  -- JALR
--            Rs_Address      <=  Instr_Fetch (25 downto 21);
--            Req_RegFile     <=  '1';
--            if (Ack_RegFile = '1') then
--              Op1_Exec      <=  Rs_RegFile;
--              Op3_Exec      <=  Instr_Fetch (15 downto 11);
--            end if;
--------------------------------------------------------------------------------
            when "001000" =>  -- JR                                           
              Rs_Address      <=  Instr_Fetch (25 downto 21);           
              Req_RegFile     <=  '1';                                  
              if (Ack_RegFile = '1') then     
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  (others => '0')            after Delay_Decode;
                Op3_Base_Exec <=  (others => '0')            after Delay_Decode;
                Op3_Exte_Exec <=  (others => '0')            after Delay_Decode;

                -- Commands
                Jump_Exec     <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "01"                       after Delay_Decode;
              end if;
            when "100111" =>  -- NOR
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Logic_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "10"                       after Delay_Decode;
              end if;
            when "100101" =>  -- OR
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Logic_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "01"                       after Delay_Decode;
              end if;            
            when "000000" =>  -- SLL
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec              <=  Rt_RegFile         after Delay_Decode;
                Op2_Exec(31 downto 5) <=  (others => '0')    after Delay_Decode;
                Op2_Exec( 4 downto 0) <=  Instr_Fetch (10 downto 6)
                                                             after Delay_Decode;
                Op3_Base_Exec         <=  Instr_Fetch (15 downto 11)
                                                             after Delay_Decode;
                -- Commands
                Shift_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "00"                       after Delay_Decode;
              end if;
            when "000100" =>  -- SLLV
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Shift_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "00"                       after Delay_Decode;
              end if;  
            when "101010" =>  -- SLT
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                BrCmp_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "10"                       after Delay_Decode;
              end if;  
            when "101011" =>  -- SLTU
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                BrCmp_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "11"                       after Delay_Decode;
              end if;  
            when "000011" =>  -- SRA
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec              <=  Rt_RegFile         after Delay_Decode;
                Op2_Exec(31 downto 5) <=  (others => '0')    after Delay_Decode;
                Op2_Exec( 4 downto 0) <=  Instr_Fetch (10 downto 6)
                                                             after Delay_Decode;
                Op3_Base_Exec         <=  Instr_Fetch (15 downto 11)
                                                             after Delay_Decode;
                -- Commands
                Shift_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "10"                       after Delay_Decode;
              end if;
            when "000111" =>  -- SRAV
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Shift_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "10"                       after Delay_Decode;
              end if;  
            when "000010" =>  -- SRL
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec              <=  Rt_RegFile         after Delay_Decode;
                Op2_Exec(31 downto 5) <=  (others => '0')    after Delay_Decode;
                Op2_Exec( 4 downto 0) <=  Instr_Fetch (10 downto 6)
                                                             after Delay_Decode;
                Op3_Base_Exec         <=  Instr_Fetch (15 downto 11)
                                                             after Delay_Decode;
                -- Commands
                Shift_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "01"                       after Delay_Decode;
              end if;
            when "000110" =>  -- SRLV
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Shift_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "01"                       after Delay_Decode;
              end if;  
            when "100010" =>  -- SUB
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Arith_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "10"                       after Delay_Decode;
              end if;  
            when "100011" =>  -- SUBU
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Arith_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "11"                       after Delay_Decode;
              end if;  
            when "100110" =>  -- XOR
              Rs_Address      <=  Instr_Fetch (25 downto 21);
              Rt_Address      <=  Instr_Fetch (20 downto 16);
              Req_RegFile     <=  '1';
              if (Ack_RegFile = '1') then
                Op1_Exec      <=  Rs_RegFile                 after Delay_Decode;
                Op2_Exec      <=  Rt_RegFile                 after Delay_Decode;
                Op3_Base_Exec <=  Instr_Fetch (15 downto 11) after Delay_Decode;
                -- Commands
                Logic_Exec    <=  '1'                        after Delay_Decode;
                Opcode_Exec   <=  "11"                       after Delay_Decode;
              end if;
            when others   =>  -- Error: Request HALT to CU!
              Halt_Req_CU     <=  '1'                        after Delay_Decode;
          end case;
          
        when "000010" => -- J
          Op1_Exec        <=  "0000" & Instr_Fetch(25 downto 0) & "00"
                                                             after Delay_Decode;
          Op2_Exec        <=  (others => '0')                after Delay_Decode;
          Op3_Base_Exec   <=  (others => '0')                after Delay_Decode;
          Op3_Exte_Exec   <=  (others => '0')                after Delay_Decode;
          -- Commands
          Jump_Exec       <=  '1'                            after Delay_Decode;
          Opcode_Exec     <=  "00"                           after Delay_Decode;
--------------------------------------------------------------------------------          
--      when "000011" => -- JAL
--        Op1_Exec      <=  "0000" & Instr_Fetch(25 downto 0) & "00";
--------------------------------------------------------------------------------
        when "001000" => -- ADDI
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            
            if (Instr_Fetch (15) = '0') then  -- Positive    
              Op2_Exec      <=  "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            else                              -- Negative
              Op2_Exec      <=  "1111111111111111" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            end if;
            
            Op3_Base_Exec <=  Instr_Fetch (20 downto 16)     after Delay_Decode;
            -- Commands
            Arith_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "00"                           after Delay_Decode;
          end if;
        when "001001" => -- ADDIU
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            Op2_Exec      <= "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            Op3_Base_Exec <=  Instr_Fetch (20 downto 16)     after Delay_Decode;
            -- Commands
            Arith_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "01"                           after Delay_Decode;
          end if;
        when "001100" => -- ANDI
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            
            if (Instr_Fetch (15) = '0') then  -- Positive    
              Op2_Exec      <=  "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            else                              -- Negative
              Op2_Exec      <=  "1111111111111111" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            end if;
            
            Op3_Base_Exec <=  Instr_Fetch (20 downto 16)     after Delay_Decode;
            -- Commands
            Logic_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "00"                           after Delay_Decode;
          end if;
        when "000100" => -- BEQ
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Rt_Address      <=  Instr_Fetch (20 downto 16);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            Op2_Exec      <=  Rt_RegFile                     after Delay_Decode;
            if (Instr_Fetch(15) = '0') then 
              -- Positive offset: extend with 0
              Op3_Exte_Exec <=  "00000000000000" & Instr_Fetch (15 downto 3)
                                                             after Delay_Decode;
            else 
              -- Negative offset: extend with 1
              Op3_Exte_Exec <=  "11111111111111" & Instr_Fetch (15 downto 3)
                                                             after Delay_Decode;
            end if;
            Op3_Base_Exec <=  Instr_Fetch(2 downto 0) & "00" after Delay_Decode;
            -- Commands
            BrCmp_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "00"                           after Delay_Decode;
          end if;
        when "000101" => -- BNE
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Rt_Address      <=  Instr_Fetch (20 downto 16);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            Op2_Exec      <=  Rt_RegFile                     after Delay_Decode;
            if (Instr_Fetch(15) = '0') then 
              -- Positive offset: extend with 0
              Op3_Exte_Exec <=  "00000000000000" & Instr_Fetch (15 downto 3)
                                                             after Delay_Decode;
            else 
              -- Negative offset: extend with 1
              Op3_Exte_Exec <=  "11111111111111" & Instr_Fetch (15 downto 3)
                                                             after Delay_Decode;
            end if;
            Op3_Base_Exec <=  Instr_Fetch(2 downto 0) & "00" after Delay_Decode;
            -- Commands
            BrCmp_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "01"                           after Delay_Decode;
          end if;
        when "100011" => -- LW
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            Op2_Exec      <= "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            Op3_Base_Exec <=  Instr_Fetch (20 downto 16)     after Delay_Decode;
            -- Commands
            Mem_Exec      <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "10"                           after Delay_Decode;
          end if;
        when "001101" => -- ORI
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            
            if (Instr_Fetch (15) = '0') then  -- Positive    
              Op2_Exec      <=  "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            else                              -- Negative
              Op2_Exec      <=  "1111111111111111" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            end if;
            
            Op3_Base_Exec <=  Instr_Fetch (20 downto 16)     after Delay_Decode;
            -- Commands
            Logic_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "01"                           after Delay_Decode;
          end if;
        when "001010" => -- SLTI
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            
            if (Instr_Fetch (15) = '0') then  -- Positive    
              Op2_Exec      <=  "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            else                              -- Negative
              Op2_Exec      <=  "1111111111111111" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            end if;
            
            Op3_Base_Exec <=  Instr_Fetch (20 downto 16)     after Delay_Decode;
            -- Commands
            BrCmp_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "10"                           after Delay_Decode;
          end if;
        when "001011" => -- SLTIU
          Rs_Address      <=  Instr_Fetch (25 downto 21);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            Op2_Exec      <= "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            Op3_Base_Exec <=  Instr_Fetch (20 downto 16)     after Delay_Decode;
            -- Commands
            BrCmp_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "11"                           after Delay_Decode;
          end if;
        when "101011" => -- SW
          Rs_Address      <=  Instr_Fetch (25 downto 21); -- Base Address
          Rt_Address      <=  Instr_Fetch (20 downto 16);
          Req_RegFile     <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            Op2_Exec      <=  "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            Op3_Exte_Exec <=  Rt_RegFile (31 downto 5)       after Delay_Decode;
            Op3_Base_Exec <=  Rt_RegFile ( 4 downto 0)       after Delay_Decode;
            -- Commands
            Mem_Exec      <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "11"                           after Delay_Decode;
          end if;
        when "001110" => -- XORI
          Rs_Address            <=  Instr_Fetch (25 downto 21);
          Req_RegFile           <=  '1';
          if (Ack_RegFile = '1') then
            Op1_Exec      <=  Rs_RegFile                     after Delay_Decode;
            
            if (Instr_Fetch (15) = '0') then  -- Positive    
              Op2_Exec      <=  "0000000000000000" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            else                              -- Negative
              Op2_Exec      <=  "1111111111111111" & Instr_Fetch (15 downto 0)
                                                             after Delay_Decode;
            end if;
            
            Op3_Base_Exec <=  Instr_Fetch (20 downto 16)     after Delay_Decode;
            -- Commands
            Logic_Exec    <=  '1'                            after Delay_Decode;
            Opcode_Exec   <=  "11"                           after Delay_Decode;
          end if;         
        when others   =>  -- Error: Request HALT to CU!
          Halt_Req_CU     <=  '1';
      end case;
    
    elsif (Enable = '1' and Valid_Data = '0') then
      -- Keep current output
    
    elsif (Enable = '0') then
      -- Commands to Register File
      Req_RegFile   <=  Rst_Value;
      Rs_Address    <=  (others => Rst_Value)                after Delay_Decode;
      Rt_Address    <=  (others => Rst_Value)                after Delay_Decode;
      -- Data to Execute stage
      Op1_Exec      <=  (others => Disabled)                 after Delay_Decode;
      Op2_Exec      <=  (others => Disabled)                 after Delay_Decode;
      Op3_Base_Exec <=  (others => Disabled)                 after Delay_Decode;
      Op3_Exte_Exec <=  (others => Disabled)                 after Delay_Decode;
      -- Commands to Execute stage
      Arith_Exec    <=  Disabled                             after Delay_Decode;
      Shift_Exec    <=  Disabled                             after Delay_Decode;
      Logic_Exec    <=  Disabled                             after Delay_Decode;
      Jump_Exec     <=  Disabled                             after Delay_Decode;
      BrCmp_Exec    <=  Disabled                             after Delay_Decode;
      Mem_Exec      <=  Disabled                             after Delay_Decode;
      Opcode_Exec   <=  (others => Disabled)                 after Delay_Decode;
      -- Requests to Control Unit
--    Halt_Req_CU   <=  Rst_Value;
    end if;
    
  end process;
end Behavioral;