----------------------------------------------------------------
--                              CROSSBAR
--                          --------------
--               DATA_AV ->|              |
--               DATA_IN ->|              |
--              DATA_ACK <-|              |-> TX
--                SENDER ->|              |-> DATA_OUT
--                  FREE ->|              |<- CREDIT_I
--                TAB_IN ->|              |
--               TAB_OUT ->|              |
--                          --------------
----------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.ThorPackage.all;

entity Thor_crossbar is
port(
	data_av:     in  regNport;
	data_in:     in  arrayNport_regflit;
	data_ack:    out regNport;
	sender:      in  regNport;
	free:        in  regNport;
	tab_in:      in  arrayNport_reg3;
	tab_out:     in  arrayNport_reg3;
	tx:          out regNport;
	data_out:    out arrayNport_regflit;
	credit_i:    in  regNport);
end Thor_crossbar;

architecture Thor_crossbar of Thor_crossbar is

begin

	MUXS : for i in EAST to LOCAL generate
		tx(i) <= data_av( CONV_INTEGER( tab_out(i) ) ) when free(i) = '0' else '0';
		data_out(i) <= data_in( CONV_INTEGER( tab_out(i) ) ) when free(i) = '0' else (others=>'0');
		data_ack(i) <= credit_i( CONV_INTEGER( tab_in(i) ) ) when data_av(i) = '1' else '0';
	end generate MUXS;		

end Thor_crossbar;