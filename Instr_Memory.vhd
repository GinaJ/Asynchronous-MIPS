library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

entity Instr_Memory is
  generic(
    Word_Size : natural := 32;
    Addr_Size : natural := 32;
    Word_Num  : natural := 32
  );
  port(
    Req  : in  std_logic;
    Addr : in  std_logic_vector (Addr_Size - 1 downto 0);
    Ack  : out std_logic;
    Data : out std_logic_vector (Word_Size - 1 downto 0)
  );
end entity Instr_Memory;

architecture Behavioral of Instr_Memory is
  constant  Delay_Cache : time    := 150 ps;
  constant  IM_File     : string  := "./IM_Init_File.txt";
  
  type      Mem_t is array            (Word_Num  - 1 downto 0) 
                  of std_logic_vector (Word_Size - 1 downto 0);
  
  function  Init_Mem (FileName : in string := IM_File) return Mem_t is
  
    file      TxtFile : text;
    variable  Mem_Tmp : Mem_t;
    variable  TxtLine : line;
    variable  BitWord : bit_vector (Word_Size - 1 downto 0);
    
  begin
  
    file_open (TxtFile, FileName, READ_MODE);
    
    for i in 0 to Word_Num - 1 loop
      readline (TxtFile, TxtLine);
      read (TxtLine, BitWord);
      Mem_Tmp (i) :=  to_stdlogicvector (BitWord);
    end loop;
    
    file_close (TxtFile);
    return Mem_Tmp;
    
  end function;
  
  signal    Mem     : Mem_t   := Init_Mem(IM_File);

begin

  process (Req)
    variable  Index : natural := 0;
  begin
    if (Req = '1') then
      Index := to_integer (unsigned (Addr (31 downto 2)));
      Data  <= Mem (Index)                                after     Delay_Cache;
      Ack   <= '1'                                        after 2 * Delay_Cache;
    elsif (Req = '0') then
      Ack <= '0'                                          after Delay_Cache / 3;
    end if;
  end process;

end Behavioral;

