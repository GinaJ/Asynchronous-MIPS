library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

entity Data_Memory is
  generic(
    Word_Size : natural := 32;
    Addr_Size : natural := 32;
    Word_Num  : natural := 8
  );
  port (
    Req   : in    std_logic;
    R_nW  : in    std_logic; 
    Addr  : in    std_logic_vector (Addr_Size - 1 downto 0);
    Ack   : out   std_logic;
    Data  : inout std_logic_vector (Word_Size - 1 downto 0)
  );
end entity Data_Memory;

architecture Behavioral of Data_Memory is

  constant  Delay_Cache : time    :=  150 ps;
  constant  DM_File     : string  :=  "./DM_Init_File.txt";
  
  type      Mem_t is array            (Word_Num  - 1 downto 0) 
                  of std_logic_vector (Word_Size - 1 downto 0);
  
  function  Init_Mem (FileName : in string := DM_File) return Mem_t is
  
    file      TxtFile : text;
    variable  Mem_Tmp : Mem_t;
    variable  TxtLine : line;
    variable  BitWord : bit_vector (Word_Size - 1 downto 0);
    
  begin
  
    file_open(TxtFile, FileName, READ_MODE);
    
    for i in 0 to Word_Num - 1 loop
      readline (TxtFile, TxtLine);
      read (TxtLine, BitWord);
      Mem_Tmp (i) :=  to_stdlogicvector (BitWord);
    end loop;
    
    file_close (TxtFile);
    return Mem_Tmp;
    
  end function;
  
  signal    Mem   : Mem_t := Init_Mem (DM_File);
  
begin  

  process (Req)
    variable  Index : natural := 0;
  begin
    
    if (Req = '1') then
      Index := to_integer (unsigned (Addr (31 downto 2)));
      if (R_nW = '1') then    
        -- Read mode
        Data        <= Mem (Index)                        after     Delay_Cache;
        Ack         <= '1'                                after 2 * Delay_Cache;
      elsif (R_nW = '0') then 
        -- Write mode
        Mem (Index) <=  Data                              after     Delay_Cache;
        Ack         <=  '1'                               after 2 * Delay_Cache;
      end if;
    elsif (Req = '0') then
      Data  <=  (others => 'Z')                           after Delay_Cache / 3;
      Ack   <=  '0'                                       after Delay_Cache / 3;
    end if;
    
  end process;
  
end architecture Behavioral;