----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    signal w_add : std_logic_vector (8 downto 0);
    signal w_sub : std_logic_vector (8 downto 0);
    
    signal w_result : std_logic_vector (7 downto 0);
    
    signal flag_c, flag_v : std_logic;
begin
        w_add <= std_logic_vector(unsigned("0" & i_A) + unsigned("0" & i_B));
        w_sub <= std_logic_vector(unsigned("0" & i_A) + unsigned("0" & not i_B)+1);
        --doc this section
        
        with i_op select
            w_result <= w_add(7 downto 0)    when "000", 
                 w_sub(7 downto 0)           when "001", 
                 i_A and i_B                 when "010", 
                 i_A or i_B                  when "011", 
                 "00000000"             when others; 
        flag_c <=    w_add(8) when (i_op = "000") else 
                     w_sub(8) when (i_op = "001") else
                     '0';
        flag_v <=    ((i_A(7) xnor i_B(7)) and (i_A(7) xor w_add(7))) when (i_op = "000") else 
                     ((i_A(7) xor i_B(7)) and (i_A(7) xor w_sub(7))) when (i_op = "001") else
                     '0';  
        o_result <= w_result;
        
        o_flags(3) <= w_result(7);
        o_flags(2) <= '1' when (w_result = "00000000") else '0'; 
        o_flags(1) <= flag_c; 
        o_flags(0) <= flag_v;        
    

end Behavioral;
