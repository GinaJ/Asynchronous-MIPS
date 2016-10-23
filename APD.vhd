library IEEE;
use IEEE.std_logic_1164.all;

entity APD is
  port (
    
    -- INPUT
    Reset           : in  std_logic;
    
    -- DEBUG OUTPUT
    -- Fetch
    Instr_Dec       : out std_logic_vector (31 downto 0);
    -- Decode
    Op1_Exec        : out std_logic_vector (31 downto 0);
    Op2_Exec        : out std_logic_vector (31 downto 0);
    Op3_Exte_Exec   : out std_logic_vector (31 downto 5);
    Op3_Base_Exec   : out std_logic_vector ( 4 downto 0);
    Arith_Exec      : out std_logic;
    Shift_Exec      : out std_logic;
    Logic_Exec      : out std_logic;
    Jump_Exec       : out std_logic;
    BrCmp_Exec      : out std_logic;
    Mem_Exec        : out std_logic;
    Opcode_Exec     : out std_logic_vector ( 1 downto 0);
    -- Execute
    Result_Mem      : out std_logic_vector (31 downto 0);
    Op3_Base_Mem    : out std_logic_vector ( 4 downto 0);
    Op3_Exte_Mem    : out std_logic_vector (31 downto 5);
    LdSt_Enable_Mem : out std_logic;
    Data_nAddr_Mem  : out std_logic;
    PC_Output       : out std_logic_vector (31 downto 0);
    PC_Signal       : out std_logic;
    -- Memory
    DataWB          : out std_logic_vector (31 downto 0);
    AddressWB       : out std_logic_vector ( 4 downto 0); 
    -- WriteBack
    Addr_T_Reg      : out std_logic_vector ( 4 downto 0);
    Result_Reg      : out std_logic_vector (31 downto 0)
    
  );
end entity APD;

architecture Structural of APD is
  
  ----------------------------------------------------------------------------
  -- USEFUL CONSTANTS                                                       --
  ----------------------------------------------------------------------------
  
  constant  Size_DM : natural :=  64;
  constant  Size_IM : natural :=  64;
  
  ----------------------------------------------------------------------------
  -- COMPONENTS                                                             --
  ----------------------------------------------------------------------------
  
  component Control_Unit is
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
  end component Control_Unit;
  
  component Fetch is
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
  end component Fetch;
  
  component Decode is
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
  end component Decode;
  
  component Execute is
    port (
      -- Control Signals
      Enable          : in  std_logic;
      Valid_Data      : in  std_logic;
      Reset           : in  std_logic;
      
      -- Data from Decode stage
      Op1_Dec         : in  std_logic_vector (31 downto 0);
      Op2_Dec         : in  std_logic_vector (31 downto 0);
      Op3_Base_Dec    : in  std_logic_vector (4 downto 0);  -- Less 5 significant bits represent the DestReg address
      Op3_Exte_Dec    : in  std_logic_vector (31 downto 5); -- AC
      
      -- Commands from Decode stage
      Arith_Cmd_Dec   : in  std_logic; -- ADD (and ADDI, ADDIU, ADDU), SUB (and SUBU)
      Shift_Cmd_Dec   : in  std_logic; -- SLL (and SLLV), SRL (and SLRV), SRA (and SRAV)
      Logic_Cmd_Dec   : in  std_logic; -- AND (and ANDI), NOR (and NORI), OR (and ORI), XOR (and XORI)
      Jump_Cmd_Dec    : in  std_logic; -- J
      Branch_Cmd_Dec  : in  std_logic; -- BEQ, BNE, SLT (Set on Less Than: compare operation), SLTU (Unsigned)
      Memory_Cmd_Dec  : in  std_logic; -- SW, LW
      OpCode_Dec      : in  std_logic_vector ( 1 downto 0); -- Selects the operation performed by the unit
      
      -- Commands from/to Program Counter
      PC_Input        : in  std_logic_vector (31 downto 0);
      PC_Output       : out std_logic_vector (31 downto 0);
      PC_Signal       : out std_logic;                      -- If 1, signals the PC that value on PC_Output is valid
      
      -- Data to Memory stage
      Result_Mem      : out std_logic_vector (31 downto 0);
      Op3_Base_Mem    : out std_logic_vector ( 4 downto 0); -- Less 5 significant bits represent the DestReg address
      Op3_Exte_Mem    : out std_logic_vector (31 downto 5); -- AC
      
      -- Commands to Memory stage
      LdSt_Enable_Mem : out std_logic;
      Data_nAddr_Mem  : out std_logic
    );
  end component Execute;
  
  component Memory is
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
  end component Memory;
  
  component WriteBack is
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
  end component WriteBack;
  
  component Register_File is
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
  end component Register_File;
  
  component Instr_Memory is
    generic(
      Word_Size : natural := 32;
      Addr_Size : natural := 32;
      Word_Num  : natural := 2
    );
    port(
      Req  : in  std_logic;
      Addr : in  std_logic_vector (Addr_Size - 1 downto 0);
      Ack  : out std_logic;
      Data : out std_logic_vector (Word_Size - 1 downto 0)
    );
  end component Instr_Memory;
  
  component Data_Memory is
    generic(
      Word_Size : natural := 32;
      Addr_Size : natural := 32;
      Word_Num  : natural := 2
    );
    port (
      Req   : in    std_logic;
      R_nW  : in    std_logic; 
      Addr  : in    std_logic_vector (Addr_Size - 1 downto 0);
      Ack   : out   std_logic;
      Data  : inout std_logic_vector (Word_Size - 1 downto 0)
    );
  end component Data_Memory;
  
  component DRE is 
    generic (N : natural := 32);
    port (
      Single_Rail : in  std_logic_vector (N - 1 downto 0);
      Dual_Rail   : out std_logic_vector (2*N - 1 downto 0)
    );
  end component DRE;
  
  component CD is
    generic (N : natural := 32);
    port(
      Dual_Rail   : in  std_logic_vector(2*N - 1 downto 0);
      Valid_Data  : out std_logic
    );
  end component CD;
  
  
  ----------------------------------------------------------------------------
  -- SIGNALS                                                                --
  ----------------------------------------------------------------------------
  
  -- CONTROL UNIT
  -- Reset signals to all components
  signal  Reset_F,
          Reset_D,
          Reset_E,
          Reset_M,
          Reset_W,
          Reset_RF            : std_logic;
  -- Start/Halt signals   
  signal  Start,          
          Halt_Req,       
          Halt                : std_logic;
  -- Program Counter signals
  signal  PC_Next,
          PC_Load             : std_logic;
  signal  PC_Value_CU_In, 
          PC_Value_CU_Out     : std_logic_vector ( 31 downto 0);
  
  -- COMPLETION DETECTORS' SIGNALS
  signal  CD_Fetch_s,
          CD_Decode_s,
          CD_Execute_s,
          CD_Memory_s,
          CD_WriteBack_s      : std_logic;
  
  -- FETCH STAGE
  signal  Enable_F            : std_logic;
  -- Signals to/from Instruction Memory
  signal  Req_RAM_IM,
          Ack_RAM_IM          : std_logic;
  signal  Addr_RAM_IM,
          Data_RAM_IM         : std_logic_vector ( 31 downto 0);
  -- Signals to DECODE Stage (not Dual-Rail Encoded)
  signal  Instr_Dec_F_D       : std_logic_vector ( 31 downto 0);
  signal  Single_Rail_F       : std_logic_vector ( 31 downto 0);
  
  -- DECODE STAGE
  signal  Enable_D            : std_logic;
  -- Signals from FETCH Stage (Dual-Rail Encoded)
  signal  DR_Fetch_Data       : std_logic_vector ( 63 downto 0);
  -- Signals to/from Register File
  signal  Req_RegFile_D,
          Ack_RegFile_D       : std_logic;
  signal  Rs_Address_D,
          Rt_Address_D        : std_logic_vector (  4 downto 0);
  signal  Rs_RegFile_D,
          Rt_RegFile_D        : std_logic_vector ( 31 downto 0);
  --Signals to EXECUTE Stage (not Dual-Rail Encoded)
  signal  Op1_Exec_D_E,
          Op2_Exec_D_E        : std_logic_vector ( 31 downto 0);
  signal  Op3_Exte_Exec_D_E   : std_logic_vector ( 31 downto 5);
  signal  Op3_Base_Exec_D_E   : std_logic_vector (  4 downto 0);
  signal  Arith_Exec_D_E,   
          Shift_Exec_D_E,   
          Logic_Exec_D_E,   
          Jump_Exec_D_E,    
          BrCmp_Exec_D_E,   
          Mem_Exec_D_E        : std_logic;
  signal  Opcode_Exec_D_E     : std_logic_vector (  1 downto 0);
  signal  Single_Rail_D       : std_logic_vector (103 downto 0);
  
  -- EXECUTE STAGE
  signal  Enable_E            : std_logic;
  -- Signals from DECODE Stage (Dual-Rail Encoded)
  signal  DR_Decode_Data      : std_logic_vector (207 downto 0);
  -- Signals to MEMORY Stage (not Dual-Rail Encoded)
  signal  Result_Mem_E_M      : std_logic_vector ( 31 downto 0);
  signal  Op3_Exte_Mem_E_M    : std_logic_vector ( 31 downto 5);
  signal  Op3_Base_Mem_E_M    : std_logic_vector (  4 downto 0);
  signal  LdSt_Enable_Mem_E_M,
          Data_nAddr_Mem_E_M  : std_logic;
  signal  Single_Rail_E       : std_logic_vector ( 65 downto 0);
  
  -- MEMORY Stage
  signal  Enable_M            : std_logic;
  -- Signals from EXECUTE Stage (Dual-Rail Encoded)
  signal  DR_Execute_Data     : std_logic_vector (131 downto 0);
  -- Signals to/from Data Memory
  signal  Ack_RAM_DM,
          Req_RAM_DM,
          Rd_Wr_RAM_DM        : std_logic;
  signal  Addr_RAM_DM,
          Data_RAM_DM         : std_logic_vector ( 31 downto 0);
  -- Signals to WRITEBACK Stage (not Dual-Rail Encoded)
  signal  DataWB_M_W          : std_logic_vector ( 31 downto 0);
  signal  AddressWB_M_W       : std_logic_vector (  4 downto 0);
  signal  Single_Rail_M       : std_logic_vector ( 36 downto 0);
  
  -- WRITEBACK Stage
  signal  Enable_W            : std_logic;
  -- Signals from MEMORY Stage (Dual-Rail Encoded)
  signal  DR_Memory_Data      : std_logic_vector ( 73 downto 0);
  -- Signals to Register File (not Dual-Rail Encoded)
  signal  Addr_T_Reg_W_RF     : std_logic_vector (  4 downto 0);
  signal  Result_Reg_W_RF     : std_logic_vector ( 31 downto 0);
  signal  Req_RegFile_W_RF,
          Ack_RegFile_W_RF    : std_logic;
  signal  Single_Rail_W       : std_logic_vector ( 36 downto 0);
  -- Signals to Register File (Dual-Rail Encoded: Dummy, used to detect end of
  --                           computation of WriteBack unit)
  signal  DR_WriteBack_Data   : std_logic_vector ( 73 downto 0);
  
begin
  
  -- CONTROL UNIT
  Control_Unit_B:     Control_Unit
    port map (
      Reset           =>  Reset,
      Halt_Req        =>  Halt_Req,
      PC_load         =>  PC_Load,
      PC_next         =>  CD_Execute_s,
      PC_in           =>  PC_Value_CU_In,
      PC_out          =>  PC_Value_CU_Out,
      Reset_F         =>  Reset_F,
      Reset_D         =>  Reset_D,
      Reset_E         =>  Reset_E,
      Reset_M         =>  Reset_M,
      Reset_W         =>  Reset_W,
      Reset_RF        =>  Reset_RF,
      Start           =>  Start,
      Halt            =>  Halt
    );
  
  -- FETCH UNIT
  Enable_F            <=  not (CD_Decode_s or Halt);
  
  Fetch_Unit:         Fetch
    port map (
      Reset           =>  Reset_F,
      Enable          =>  Enable_F,
      PC_Value        =>  PC_Value_CU_Out,
      Instr_Dec       =>  Instr_Dec_F_D,
      Ack_IM          =>  Ack_RAM_IM,
      Req_IM          =>  Req_RAM_IM,
      Data_IM         =>  Data_RAM_IM,
      Addr_IM         =>  Addr_RAM_IM
    );
  
  Single_Rail_F       <=  Instr_Dec_F_D;
  
  DRE_Fetch:          DRE
    generic map (N    =>  32)
    port map(
      Single_Rail     =>  Single_Rail_F,
      Dual_Rail       =>  DR_Fetch_Data
    );
  
  CD_Fetch:           CD
    generic map (N    =>  32)
    port map (
      Dual_Rail       =>  DR_Fetch_Data,
      Valid_Data      =>  CD_Fetch_s
    );
  
  
  -- DECODE UNIT
  Enable_D            <=  not (CD_Execute_s or Halt);
  
  Decode_Unit:        Decode
    port map (
      Reset           =>  Reset_D,
      Enable          =>  Enable_D,
      Valid_Data      =>  CD_Fetch_s,
      Instr_Fetch     =>  DR_Fetch_Data (31 downto 0),
      Ack_RegFile     =>  Ack_RegFile_D,
      Req_RegFile     =>  Req_RegFile_D,
      Rs_Address      =>  Rs_Address_D,
      Rt_Address      =>  Rt_Address_D,
      Rs_RegFile      =>  Rs_RegFile_D,
      Rt_RegFile      =>  Rt_RegFile_D,
      Op1_Exec        =>  Op1_Exec_D_E,
      Op2_Exec        =>  Op2_Exec_D_E,
      Op3_Exte_Exec   =>  Op3_Exte_Exec_D_E,
      Op3_Base_Exec   =>  Op3_Base_Exec_D_E,
      Arith_Exec      =>  Arith_Exec_D_E,
      Shift_Exec      =>  Shift_Exec_D_E,
      Logic_Exec      =>  Logic_Exec_D_E,
      Jump_Exec       =>  Jump_Exec_D_E,
      BrCmp_Exec      =>  BrCmp_Exec_D_E,
      Mem_Exec        =>  Mem_Exec_D_E,
      Opcode_Exec     =>  Opcode_Exec_D_E,
      Halt_Req_CU     =>  Halt_Req
    );
  
  Single_Rail_D       <=  Op1_Exec_D_E      &
                          Op2_Exec_D_E      &
                          Op3_Base_Exec_D_E &
                          Op3_Exte_Exec_D_E &
                          Arith_Exec_D_E    &
                          Shift_Exec_D_E    &
                          Logic_Exec_D_E    &
                          Jump_Exec_D_E     &
                          BrCmp_Exec_D_E    &
                          Mem_Exec_D_E      &
                          Opcode_Exec_D_E;
  
  DRE_Decode:         DRE
    generic map (N    =>  104)
    port map (
      Single_Rail     =>  Single_Rail_D,
      Dual_Rail       =>  DR_Decode_Data
    );
  
  CD_Decode:          CD
    generic map (N    =>  104)
    port map (
      Dual_Rail       =>  DR_Decode_Data,
      Valid_Data      =>  CD_Decode_s
    );
  
  
  -- EXECUTE UNIT
  Enable_E            <=  not (CD_Memory_s or Halt);
  
  Execute_Unit:       Execute
    port map (
      Reset           =>  Reset_E,
      Enable          =>  Enable_E,
      Valid_Data      =>  CD_Decode_s,
      Op1_Dec         =>  DR_Decode_Data (103 downto  72),
      Op2_Dec         =>  DR_Decode_Data ( 71 downto  40),
      Op3_Base_Dec    =>  DR_Decode_Data ( 39 downto  35),
      Op3_Exte_Dec    =>  DR_Decode_Data ( 34 downto   8),
      Arith_Cmd_Dec   =>  DR_Decode_Data (  7),
      Shift_Cmd_Dec   =>  DR_Decode_Data (  6),
      Logic_Cmd_Dec   =>  DR_Decode_Data (  5),
      Jump_Cmd_Dec    =>  DR_Decode_Data (  4),
      Branch_Cmd_Dec  =>  DR_Decode_Data (  3),
      Memory_Cmd_Dec  =>  DR_Decode_Data (  2),
      OpCode_Dec      =>  DR_Decode_Data (  1 downto   0),
      PC_Input        =>  PC_Value_CU_Out,
      PC_Output       =>  PC_Value_CU_In,
      PC_Signal       =>  PC_Load,
      Result_Mem      =>  Result_Mem_E_M,
      Op3_Base_Mem    =>  Op3_Base_Mem_E_M,
      Op3_Exte_Mem    =>  Op3_Exte_Mem_E_M,
      LdSt_Enable_Mem =>  LdSt_Enable_Mem_E_M,
      Data_nAddr_Mem  =>  Data_nAddr_Mem_E_M
    );
  
  Single_Rail_E       <=  Result_Mem_E_M      &
                          Op3_Exte_Mem_E_M    &
                          Op3_Base_Mem_E_M    &
                          LdSt_Enable_Mem_E_M &
                          Data_nAddr_Mem_E_M;
  
  DRE_Execute:        DRE
    generic map (N    =>  66)
    port map(
      Single_Rail     =>  Single_Rail_E,
      Dual_Rail       =>  DR_Execute_Data
    );
  
  CD_Execute:         CD
    generic map (N    =>  66)
    port map(
      Dual_Rail       =>  DR_Execute_Data,
      Valid_Data      =>  CD_Execute_s
    );
  
  
  -- MEMORY UNIT
  Enable_M            <=  not (CD_WriteBack_s or Halt);
  
  Memory_Unit:        Memory
    port map (
      Reset           =>  Reset_M,
      Enable          =>  Enable_M,
      Valid_Data      =>  CD_Execute_s,
      ResultEx        =>  DR_Execute_Data (65 downto 34),
      DataAddressEx   =>  DR_Execute_Data (33 downto  2),
      MemAluEx        =>  DR_Execute_Data ( 1),
      RWEx            =>  DR_Execute_Data ( 0),
      RnW_DM          =>  Rd_Wr_RAM_DM,
      Req_DM          =>  Req_RAM_DM,
      Ack_DM          =>  Ack_RAM_DM,
      Addr_DM         =>  Addr_RAM_DM,
      Data_DM         =>  Data_RAM_DM,
      DataWB          =>  DataWB_M_W,
      AddressWB       =>  AddressWB_M_W
    );
  
  Single_Rail_M       <=  DataWB_M_W      &
                          AddressWB_M_W;
  
  DRE_Memory:         DRE
    generic map (N    =>  37)
    port map(
      Single_Rail     =>  Single_Rail_M,
      Dual_Rail       =>  DR_Memory_Data
    );
  
  CD_Memory:          CD
    generic map (N    =>  37)
    port map (
      Dual_Rail       =>  DR_Memory_Data,
      Valid_Data      =>  CD_Memory_s
    );
  
  
  -- WRITEBACK UNIT
  Enable_W            <=  not (Ack_RegFile_W_RF or Halt);
  
  WriteBack_Unit:     WriteBack
    port map (
      Reset           =>  Reset_W,
      Start           =>  Start,
      Enable          =>  Enable_W,
      Valid_Data      =>  CD_Memory_s,
      Result_Mem      =>  DR_Memory_Data (36 downto  5),
      Addr_T_Mem      =>  DR_Memory_Data ( 4 downto  0),
      Addr_T_Reg      =>  Addr_T_Reg_W_RF,
      Result_Reg      =>  Result_Reg_W_RF,
      Req_RegFile     =>  Req_RegFile_W_RF,
      Ack_RegFile     =>  Ack_RegFile_W_RF
    );
  
  Single_Rail_W       <=  Addr_T_Reg_W_RF   &
                          Result_Reg_W_RF;
  
  DRE_WriteBack:      DRE
    generic map (N    =>  37)
    port map (
      Single_Rail     =>  Single_Rail_W,
      Dual_Rail       =>  DR_WriteBack_Data
    );
  
  CD_WriteBack:       CD
    generic map (N    =>  37)
    port map (
      Dual_Rail       =>  DR_WriteBack_Data,
      Valid_Data      =>  CD_WriteBack_s
    );
  
  
  -- REGISTER FILE
  Reg_File:           Register_File
    port map (
      Rs_Addr         =>  Rs_Address_D,
      Rt_Addr         =>  Rt_Address_D,
      Rs_Data         =>  Rs_RegFile_D,
      Rt_Data         =>  Rt_RegFile_D,
      Req_Read        =>  Req_RegFile_D,
      Ack_Read        =>  Ack_RegFile_D,
      Rd_Addr         =>  Addr_T_Reg_W_RF,
      Rd_Data         =>  Result_Reg_W_RF,
      Req_Write       =>  Req_RegFile_W_RF,
      Ack_Write       =>  Ack_RegFile_W_RF,
      Reset           =>  Reset_RF
    );
  
  -- MEMORIES
  Instr_Mem:      Instr_Memory
    generic map(
      Word_Size       =>  32,
      Addr_Size       =>  32,
      Word_Num        =>  Size_IM
    )
    port map (
      Req             =>  Req_RAM_IM,
      Ack             =>  Ack_RAM_IM,
      Addr            =>  Addr_RAM_IM,
      Data            =>  Data_RAM_IM
    );
  
  Data_Mem:       Data_Memory
    generic map(
      Word_Size       =>  32,
      Addr_Size       =>  32,
      Word_Num        =>  Size_DM
    )
    port map (
      Req             =>  Req_RAM_DM,
      Ack             =>  Ack_RAM_DM,
      R_nW            =>  Rd_Wr_RAM_DM,
      Addr            =>  Addr_RAM_DM,
      Data            =>  Data_RAM_DM
    );
  
  
  ----------------------------------------------------------------------------
  -- DEBUG SIGNALS                                                          --
  ----------------------------------------------------------------------------
  
  -- Fetch
  Instr_Dec       <=  Instr_Dec_F_D;
  -- Decode
  Op1_Exec        <=  Op1_Exec_D_E;
  Op2_Exec        <=  Op2_Exec_D_E;
  Op3_Exte_Exec   <=  Op3_Exte_Exec_D_E;
  Op3_Base_Exec   <=  Op3_Base_Exec_D_E;
  Arith_Exec      <=  Arith_Exec_D_E;
  Shift_Exec      <=  Shift_Exec_D_E;
  Logic_Exec      <=  Logic_Exec_D_E;
  Jump_Exec       <=  Jump_Exec_D_E;
  BrCmp_Exec      <=  BrCmp_Exec_D_E;
  Mem_Exec        <=  Mem_Exec_D_E;
  Opcode_Exec     <=  Opcode_Exec_D_E;
  -- Execute
  Result_Mem      <=  Result_Mem_E_M;
  Op3_Base_Mem    <=  Op3_Base_Mem_E_M;
  Op3_Exte_Mem    <=  Op3_Exte_Mem_E_M;
  LdSt_Enable_Mem <=  LdSt_Enable_Mem_E_M;
  Data_nAddr_Mem  <=  Data_nAddr_Mem_E_M;
  PC_Output       <=  PC_Value_CU_In;
  PC_Signal       <=  PC_Load;
  -- Memory
  DataWB          <=  DataWB_M_W;
  AddressWB       <=  AddressWB_M_W;
  -- WriteBack
  Addr_T_Reg      <=  Addr_T_Reg_W_RF;
  Result_Reg      <=  Result_Reg_W_RF;
  
end architecture Structural;