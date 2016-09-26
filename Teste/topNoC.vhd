library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;
use work.ThorPackage.all;

entity topNoC is
end;


architecture topNoC of topNoC is

	component inputmodule
	port
	(
		clock : in std_logic;
		reset : in std_logic;
		incredit : in regNrot;
		outtx : out regNrot;
		outdata : out arrayNrot_regflit
	);
	end component;

	component outputmodule
	port
	(
		clock : in std_logic;
		reset : in std_logic;
		intx : in regNrot;
		indata : in arrayNrot_regflit
	);
	end component;
	
	signal clock : regNrot:=(others=>'0');
	signal reset : std_logic;
	signal clock_rx: regNrot:=(others=>'0');
	signal rx, credit_o: regNrot;
	signal clock_tx, tx, credit_i: regNrot;
	signal data_in, data_out : arrayNrot_regflit;

begin
	reset <= '1', '0' after 10 ns;
	clock <= not clock after 10 ns;
	clock_rx <= not clock_rx after 10 ns;	
	credit_i <= tx;

	NOC: Entity work.NOC
	port map(
		clock         => clock,
		reset         => reset,
		clock_rxLocal => clock_rx,
		rxLocal       => rx,
		data_inLocal  => data_in,
		credit_oLocal => credit_o,
		clock_txLocal => clock_tx,
		txLocal       => tx,
		data_outLocal => data_out,
		credit_iLocal => credit_i
		);
		

	cim00: inputmodule
		port map
		(
			clock => clock(0),
			reset => reset,

			incredit => credit_o,
			outtx => rx,
			outdata => data_in
		);
			
	cim01: outputmodule
		port map
		(
			clock => clock(0),
			reset => reset,
			
			intx => tx,
			indata => data_out
		);
	
end topNoC;
