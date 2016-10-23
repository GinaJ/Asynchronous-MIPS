library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Execute is

  port (
    -- Control Signals
    Enable          : in  std_logic;
    Valid_Data      : in  std_logic;
    Reset           : in  std_logic;
    
    -- Data from Decode stage
    Op1_Dec         : in  std_logic_vector (31 downto 0);
    Op2_Dec         : in  std_logic_vector (31 downto 0);
    Op3_Base_Dec    : in  std_logic_vector ( 4 downto 0); -- Less 5 significant bits represent the DestReg address
    Op3_Exte_Dec    : in  std_logic_vector (31 downto 5); -- AC
    
    -- Commands from Decode stage
    Arith_Cmd_Dec   : in  std_logic; -- ADD (and ADDI, ADDIU, ADDU), SUB (and SUBU)
    Shift_Cmd_Dec   : in  std_logic; -- SLL (and SLLV), SRL (and SLRV), SRA (and SRAV)
    Logic_Cmd_Dec   : in  std_logic; -- AND (and ANDI), NOR (and NORI), OR (and ORI), XOR (and XORI)
    Jump_Cmd_Dec    : in  std_logic; -- J
    Branch_Cmd_Dec  : in  std_logic; -- BEQ, BNE, SLT (Set on Less Than: compare operation), SLTU (Unsigned)
    Memory_Cmd_Dec  : in  std_logic; -- SW, LW
    OpCode_Dec      : in  std_logic_vector ( 1 downto 0); -- Selects the operation performed by a unit
    
    -- Commands from/to Program Counter
    PC_Input        : in  std_logic_vector (31 downto 0);
    PC_Output       : out std_logic_vector (31 downto 0);
    PC_Signal       : out std_logic;                      -- If 1, signals the PC that value on PC_Output is valid
    
    -- Data to Memory stage
    Result_Mem      : out std_logic_vector (31 downto 0);
    Op3_Base_Mem    : out std_logic_vector ( 4 downto 0); -- Less 5 significant bits represent the DestReg address
    Op3_Exte_Mem    : out std_logic_vector (31 downto 5); -- AC
    
    -- Commands to Memory stage
--  Enable_Mem      : out std_logic; -- Optional
    LdSt_Enable_Mem : out std_logic;
    Data_nAddr_Mem  : out std_logic
  );

end Execute;

architecture Behavioral of Execute is
    
    constant  Delay_Execute : time      := 1 ns;
    
    constant  Disabled      : std_logic := 'Z';
    constant  Rst_Value     : std_logic := '0';
  
begin
  
  E: process (Enable, Valid_Data, Reset,
              Op1_Dec, Op2_Dec, Op3_Base_Dec, Op3_Exte_Dec,
              Arith_Cmd_Dec, Shift_Cmd_Dec, Logic_Cmd_Dec,
              Jump_Cmd_Dec, Branch_Cmd_Dec, Memory_Cmd_Dec)
    
    variable  Op3_Internal  : std_logic_vector (31 downto 0);
    variable  PC_int_value  : integer;
    variable  Offset_value  : integer;
    
  begin
    
    if (Reset = '1') then
      PC_Output       <= (others => Rst_Value);
      Result_Mem      <= (others => Rst_Value);
      Op3_Base_Mem    <= (others => Rst_Value);
      Op3_Exte_Mem    <= (others => Rst_Value);
      Op3_Internal    := (others => Rst_Value);
      PC_Signal       <= Rst_Value;
      LdSt_Enable_Mem <= Rst_Value;
      Data_nAddr_Mem  <= Rst_Value;
      
    elsif (Enable = '1' and Valid_Data = '1') then
      LdSt_Enable_Mem <= '0'                                after Delay_Execute;
      Data_nAddr_Mem  <= '0'                                after Delay_Execute;
      PC_Signal       <= '0'                                after Delay_Execute;
      PC_Output       <= (others => '0')                    after Delay_Execute;
      Op3_Base_Mem    <= Op3_Base_Dec                       after Delay_Execute;
      Op3_Exte_Mem    <= Op3_Exte_Dec                       after Delay_Execute;
      Op3_Internal    := Op3_Exte_Dec & Op3_Base_Dec;
      
      if (Arith_Cmd_Dec = '1') then
        case OpCode_Dec  is
          when "00" => -- ADD
            Result_Mem <= std_logic_vector(signed(Op1_Dec)
                        + signed(Op2_Dec))                  after Delay_Execute;
          when "01" => -- ADDU
            Result_Mem <= std_logic_vector(unsigned(Op1_Dec)
                        + unsigned(Op2_Dec))                after Delay_Execute;
          when "10" => -- SUB
            Result_Mem <= std_logic_vector(signed(Op1_Dec)
                        - signed(Op2_Dec))                  after Delay_Execute;
          when "11" => -- SUBU
            Result_Mem <= std_logic_vector(unsigned(Op1_Dec)
                        - unsigned(Op2_Dec))                after Delay_Execute;
          when others => -- Error! Should never get here
            PC_Output       <= (others => Disabled);
            Result_Mem      <= (others => Disabled);
            Op3_Base_Mem    <= (others => Disabled);
            Op3_Exte_Mem    <= (others => Disabled);
            LdSt_Enable_Mem <= Disabled;
            Data_nAddr_Mem  <= Disabled;
        end case;
        
      elsif (Shift_Cmd_Dec = '1') then
        case OpCode_Dec  is
          when "00" => -- SLL
            Result_Mem  <= std_logic_vector(shift_left(unsigned(Op1_Dec),
                           to_integer(unsigned(Op2_Dec(4 downto 0)))))
                                                            after Delay_Execute;
          when "01" => -- SRL
            Result_Mem  <= std_logic_vector(shift_right(unsigned(Op1_Dec),
                           to_integer(unsigned(Op2_Dec(4 downto 0)))))
                                                            after Delay_Execute;
          when "10" => -- SRA
            Result_Mem  <= std_logic_vector(shift_right(signed(Op1_Dec),
                           to_integer(unsigned(Op2_Dec(4 downto 0)))))
                                                            after Delay_Execute;
          when others => -- Error! Should never get here
            PC_Output       <= (others => Disabled);
            Result_Mem      <= (others => Disabled);
            Op3_Base_Mem    <= (others => Disabled);
            Op3_Exte_Mem    <= (others => Disabled);
            LdSt_Enable_Mem <= Disabled;
            Data_nAddr_Mem  <= Disabled;
        end case;
        
      elsif (Logic_Cmd_Dec = '1') then
        case OpCode_Dec  is
          when "00" => -- AND
            Result_Mem <= Op1_Dec and Op2_Dec               after Delay_Execute;
          when "01" => -- OR
            Result_Mem <= Op1_Dec or Op2_Dec                after Delay_Execute;
          when "10" => -- NOR
            Result_Mem <= Op1_Dec nor Op2_Dec               after Delay_Execute;
          when "11" => -- XOR
            Result_Mem <= Op1_Dec xor Op2_Dec               after Delay_Execute;
          when others => -- Error! Should never get here
            PC_Output       <= (others => Disabled);
            Result_Mem      <= (others => Disabled);
            Op3_Base_Mem    <= (others => Disabled);
            Op3_Exte_Mem    <= (others => Disabled);
            LdSt_Enable_Mem <= Disabled;
            Data_nAddr_Mem  <= Disabled;
        end case;
        
      elsif (Jump_Cmd_Dec = '1') then
        PC_Signal     <= '1'                                after Delay_Execute;
        Result_Mem    <= (others => '0')                    after Delay_Execute;
        Op3_Base_Mem  <= (others => '0')                    after Delay_Execute;
        Op3_Exte_Mem  <= (others => '0')                    after Delay_Execute;
        case OpCode_Dec  is
          when "00" =>
            PC_Output <= PC_Input(31 downto 28) & Op1_Dec(27 downto 2) & "00" 
                                                            after Delay_Execute;
          when "01" =>
            PC_Output <= Op1_Dec                            after Delay_Execute;
          when others => -- Error! Should never get here
            PC_Output       <= (others => Disabled);
            Result_Mem      <= (others => Disabled);
            Op3_Base_Mem    <= (others => Disabled);
            Op3_Exte_Mem    <= (others => Disabled);
            LdSt_Enable_Mem <= Disabled;
            Data_nAddr_Mem  <= Disabled;
        end case;
          
      elsif (Branch_Cmd_Dec = '1') then
        case OpCode_Dec  is
          when "00" => -- BEQ
            if (Op1_Dec = Op2_Dec) then
              PC_int_value  := to_integer(signed('0' & PC_Input));
              Offset_value  := to_integer(signed(Op3_Internal));
              PC_Output     <= std_logic_vector(to_unsigned(PC_int_value
                             + Offset_value + 4, 32))       after Delay_Execute;
              PC_Signal     <= '1'                          after Delay_Execute;
            end if;
            Result_Mem    <= (others => '0');
            Op3_Base_Mem  <= (others => '0');
            Op3_Exte_Mem  <= (others => '0');
          when "01" => -- BNE
            if (Op1_Dec /= Op2_Dec) then
              PC_int_value  := to_integer(signed('0' & PC_Input));
              Offset_value  := to_integer(signed(Op3_Internal));
              PC_Output     <= std_logic_vector(to_unsigned(PC_int_value
                             + Offset_value + 4, 32))       after Delay_Execute;
              PC_Signal     <= '1'                          after Delay_Execute;
            end if;
            Result_Mem    <= (others => '0');
            Op3_Base_Mem  <= (others => '0');
            Op3_Exte_Mem  <= (others => '0');
          when "10" => -- SLT
            if (signed(Op1_Dec) < signed(Op2_Dec)) then
              Result_Mem <= std_logic_vector(to_unsigned(1, 32))
                                                            after Delay_Execute;
            else
              Result_Mem <= (others => '0')                 after Delay_Execute;
            end if;
          when "11" => -- SLTU
            if (unsigned(Op1_Dec) < unsigned(Op2_Dec)) then
              Result_Mem <= std_logic_vector(to_unsigned(1, 32))
                                                            after Delay_Execute;
            else
              Result_Mem <= (others => '0')                 after Delay_Execute;
            end if;
          when others => -- Error! Should never get here
            PC_Output       <= (others => Disabled);
            Result_Mem      <= (others => Disabled);
            Op3_Base_Mem    <= (others => Disabled);
            Op3_Exte_Mem    <= (others => Disabled);
            LdSt_Enable_Mem <= Disabled;
            Data_nAddr_Mem  <= Disabled;
        end case;
        
      elsif (Memory_Cmd_Dec = '1') then
        LdSt_Enable_Mem <= OpCode_Dec(1)                    after Delay_Execute;
        Data_nAddr_Mem  <= OpCode_Dec(0)                    after Delay_Execute;
        Result_Mem      <= std_logic_vector(signed(Op1_Dec)
                         + signed(Op2_Dec))                 after Delay_Execute;
      
      else
        PC_Output       <= (others => Disabled);
        Result_Mem      <= (others => Disabled);
        Op3_Base_Mem    <= (others => Disabled);
        Op3_Exte_Mem    <= (others => Disabled);
        Data_nAddr_Mem  <= Disabled;
        LdSt_Enable_Mem <= Disabled;
      
      end if;
      
    elsif (Enable = '1' and Valid_Data = '0') then
      -- Keep current outputs
      
    elsif (Enable = '0') then
      PC_Output       <= (others => Disabled)               after Delay_Execute;
      Result_Mem      <= (others => Disabled)               after Delay_Execute;
      Op3_Base_Mem    <= (others => Disabled)               after Delay_Execute;
      Op3_Exte_Mem    <= (others => Disabled)               after Delay_Execute;
      Data_nAddr_Mem  <= Disabled                           after Delay_Execute;
      LdSt_Enable_Mem <= Disabled                           after Delay_Execute;
    
    end if;
    
  end process E;
  
end Behavioral;