LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY APD_TestBench IS
END APD_TestBench;
 
ARCHITECTURE behavior OF APD_TestBench IS 

    COMPONENT APD
    PORT(
         Reset : IN  std_logic;
         Instr_Dec : OUT  std_logic_vector(31 downto 0);
         Op1_Exec : OUT  std_logic_vector(31 downto 0);
         Op2_Exec : OUT  std_logic_vector(31 downto 0);
         Op3_Exte_Exec : OUT  std_logic_vector(31 downto 5);
         Op3_Base_Exec : OUT  std_logic_vector(4 downto 0);
         Arith_Exec : OUT  std_logic;
         Shift_Exec : OUT  std_logic;
         Logic_Exec : OUT  std_logic;
         Jump_Exec : OUT  std_logic;
         BrCmp_Exec : OUT  std_logic;
         Mem_Exec : OUT  std_logic;
         Opcode_Exec : OUT  std_logic_vector(1 downto 0);
         Result_Mem : OUT  std_logic_vector(31 downto 0);
         Op3_Base_Mem : OUT  std_logic_vector(4 downto 0);
         Op3_Exte_Mem : OUT  std_logic_vector(31 downto 5);
         LdSt_Enable_Mem : OUT  std_logic;
         Data_nAddr_Mem : OUT  std_logic;
         PC_Output : OUT  std_logic_vector(31 downto 0);
         PC_Signal : OUT  std_logic;
         DataWB : OUT  std_logic_vector(31 downto 0);
         AddressWB : OUT  std_logic_vector(4 downto 0);
         Addr_T_Reg : OUT  std_logic_vector(4 downto 0);
         Result_Reg : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal Reset : std_logic;

 	--Outputs
   signal Instr_Dec : std_logic_vector(31 downto 0);
   signal Op1_Exec : std_logic_vector(31 downto 0);
   signal Op2_Exec : std_logic_vector(31 downto 0);
   signal Op3_Exte_Exec : std_logic_vector(31 downto 5);
   signal Op3_Base_Exec : std_logic_vector(4 downto 0);
   signal Arith_Exec : std_logic;
   signal Shift_Exec : std_logic;
   signal Logic_Exec : std_logic;
   signal Jump_Exec : std_logic;
   signal BrCmp_Exec : std_logic;
   signal Mem_Exec : std_logic;
   signal Opcode_Exec : std_logic_vector(1 downto 0);
   signal Result_Mem : std_logic_vector(31 downto 0);
   signal Op3_Base_Mem : std_logic_vector(4 downto 0);
   signal Op3_Exte_Mem : std_logic_vector(31 downto 5);
   signal LdSt_Enable_Mem : std_logic;
   signal Data_nAddr_Mem : std_logic;
   signal PC_Output : std_logic_vector(31 downto 0);
   signal PC_Signal : std_logic;
   signal DataWB : std_logic_vector(31 downto 0);
   signal AddressWB : std_logic_vector(4 downto 0);
   signal Addr_T_Reg : std_logic_vector(4 downto 0);
   signal Result_Reg : std_logic_vector(31 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: APD PORT MAP (
          Reset => Reset,
          Instr_Dec => Instr_Dec,
          Op1_Exec => Op1_Exec,
          Op2_Exec => Op2_Exec,
          Op3_Exte_Exec => Op3_Exte_Exec,
          Op3_Base_Exec => Op3_Base_Exec,
          Arith_Exec => Arith_Exec,
          Shift_Exec => Shift_Exec,
          Logic_Exec => Logic_Exec,
          Jump_Exec => Jump_Exec,
          BrCmp_Exec => BrCmp_Exec,
          Mem_Exec => Mem_Exec,
          Opcode_Exec => Opcode_Exec,
          Result_Mem => Result_Mem,
          Op3_Base_Mem => Op3_Base_Mem,
          Op3_Exte_Mem => Op3_Exte_Mem,
          LdSt_Enable_Mem => LdSt_Enable_Mem,
          Data_nAddr_Mem => Data_nAddr_Mem,
          PC_Output => PC_Output,
          PC_Signal => PC_Signal,
          DataWB => DataWB,
          AddressWB => AddressWB,
          Addr_T_Reg => Addr_T_Reg,
          Result_Reg => Result_Reg
        );
 

  -- Stimulus process
  stim_proc  : process
  begin
    
    Reset <= 'U';
    wait for 10 ps;
    Reset <= '1';
    wait for 20 ns;
    Reset <= '0';
--    wait for 500 ns;
--    Reset <= '1';
--    wait for 20 ns;
--    Reset <= '0';
    
    wait;
    
  end process;

END;
