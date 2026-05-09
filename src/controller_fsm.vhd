----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    type state_type is (clear, op1,op2,result);
    signal current_state,next_state : state_type;
begin

    next_state <= clear when current_state=result else
             op1 when current_state = clear else
             op2 when current_state = op1 else
             result when current_state = op2 else
             clear;
             
    with current_state select
	o_cycle <= "0001" when clear,
	           "0010" when op1,
	           "0100" when op2,
	           "1000" when result,
	           "0000" when others;
	-- State register ------------
	state_register : process(i_adv, i_reset)
	begin
           if i_reset = '1' then
               current_state <= clear;
           elsif rising_edge(i_adv) then
                current_state <= next_state;
            end if;
	end process state_register;        

end FSM;
