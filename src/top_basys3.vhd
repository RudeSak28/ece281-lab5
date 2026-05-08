--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
        signal clk_div : std_logic;
        signal w_cycle : std_logic_vector(3 downto 0);
        
        signal i_reg_A : std_logic_vector(7 downto 0);
        signal i_reg_B : std_logic_vector(7 downto 0);
        
        signal alu_result : std_logic_vector(7 downto 0);
        signal alu_o_flag : std_logic_vector(3 downto 0);
        
        signal mux_data_o : std_logic_vector(7 downto 0); 
        signal w_sign : std_logic;
        signal w_hund : std_logic_vector(3 downto 0);
        signal w_tens : std_logic_vector(3 downto 0);
        signal w_ones : std_logic_vector(3 downto 0);
        
        signal tdm_data : std_logic_vector(3 downto 0);
        signal tdm_sel : std_logic_vector(3 downto 0);
        signal seven_seg_decoder : std_logic_vector(6 downto 0);
        
        component controller_fsm is
	       port(
	           i_reset : in std_logic;
	           i_adv  : in std_logic;
	           o_cycle : out std_logic_vector(3 downto 0)
	     );
	    end component controller_fsm;
	    
	    component clock_div is
	       port(
	           i_clk : in std_logic;
	           i_reset  : in std_logic;
	           o_clk : out std_logic
	     );
	    end component clock_div;
	    
	    component ALU is
	       port(
	           i_A : in std_logic_vector(7 downto 0);
	           i_B  : in std_logic_vector(7 downto 0);
	           i_op : in std_logic_vector(2 downto 0);
	           o_result : out std_logic_vector(7 downto 0);
	           o_flags : out std_logic_vector(3 downto 0)
	     );
	    end component ALU;
	    
	    component twos_comp is
	       port(
	           i_bin : in std_logic_vector(7 downto 0);
	           o_sign  : out std_logic;
	           o_hund : out std_logic_vector(3 downto 0);
	           o_tens : out std_logic_vector(3 downto 0);
	           o_ones : out std_logic_vector(3 downto 0)
	     );
	    end component twos_comp;
	    
        component TDM4 is
		  generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
            Port ( i_clk		: in  STD_LOGIC;
                   i_reset		: in  STD_LOGIC; -- asynchronous
                   i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		           i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		           i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		           i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		           o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		           o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	       );
        end component TDM4;
        
        component sevenseg_decoder is
            port (
                i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
                o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
            );
        end component sevenseg_decoder;
begin
	-- PORT MAPS ----------------------------------------
       led(3 downto 0) <= w_cycle;
       led(15 downto 12) <= alu_o_flag;
       led(11 downto 4) <= "0";
       
       inst_controller_fsm: controller_fsm
	       port map(
	           i_reset => btnU,
	           i_adv  => btnC,
	           o_cycle => w_cycle
	     );
	   inst_clock_div : clock_div
	       port map(
	           i_clk => clk,
	           i_reset  => btnU,
	           o_clk => clk_div
	     );
	   inst_ALU : ALU
	       port map(
	           i_A => i_reg_A,
	           i_B  => i_reg_B,
	           i_op => sw(2 downto 0),
	           o_result => alu_result,
	           o_flags => alu_o_flag
	     );
	     inst_twos_comp : twos_comp
	       port map(
	           i_bin => mux_data_o,
	           o_sign  => w_sign,
	           o_hund => w_hund,
	           o_tens => w_tens,
	           o_ones => w_ones
	     );
	   tdm_inst : TDM4
	       port map(
	           i_clk => clk_div,
	           i_reset => btnU,
	           i_D3  => "0000",
	           i_D2  => w_hund,
	           i_D1  => w_tens,
	           i_D0  => w_ones,
	           o_data => tdm_data,
	           o_sel => tdm_sel
	   );
	   sevenseg_inst : sevenseg_decoder
	       port map(
	       i_Hex => tdm_data,
	       o_seg_n => seg
	   ); 
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	
	
end top_basys3_arch;
