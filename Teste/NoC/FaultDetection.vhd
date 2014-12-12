----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:39:07 06/27/2013 
-- Design Name: 
-- Module Name:    FaultDetection - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.std_logic_unsigned.all;
use work.HermesPackage.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
--
--       IN    ____________    OUT
--            |            | 
--    data_inA|------------| dataInB     
--            |            |
--            |____________|
--                     compTest  test_link_in  test_link_out    <---sinais de controle
--            ____________\/____________\/___________\/________
--           |                                         |
--  data_out'|    
--
--


entity FaultDetection is
	Port(	
			clock :   in  std_logic;
			reset :   in  std_logic;
			c_strLinkTst: in regNport;     --sinal de teste local para exterior
			c_stpLinkTst: out regNport;
			test_link_inA	: in regNport; --sinal de teste exterior para local
			data_outA		: in arrayNport_regflit;
			data_inA		: in arrayNport_regflit;
			credit_inA		: in regNport;
			credit_outA		: in regNport;
			data_outB		: out arrayNport_regflit;
			credit_inB		: out regNport;
			c_faultTableFDM	: out regNPort;
			credit_outB		: out regNport);
end FaultDetection;

architecture Behavioral of FaultDetection is
signal stopLinkTest: std_logic;
type testLinks is (S_INIT, S_FIRSTDATA, S_SECONDDATA,S_END);
signal EA : testLinks;
signal compTest : std_logic := '0';
signal tmp : regNport := (others=>'Z');
signal fillOne : regFlit := (others=>'1');
signal fillZero : regFlit := (others=>'0');
signal strLinkTstAll : std_logic := '0';
signal faultTableReg : regNPort :=(others=>'0');
begin

	c_stpLinkTst <= (others=>'1') when stopLinkTest = '1' else (others=>'0');
	c_faultTableFDM <= faultTableReg;
	
	strLinkTstAll <= c_strLinkTst(EAST) or c_strLinkTst(WEST) or c_strLinkTst(NORTH) or c_strLinkTst(SOUTH) or c_strLinkTst(LOCAL);
	
	ALL_MUX : for i in 0 to (NPORT-1) generate
		credit_outB(i) <= credit_outA(i) when (strLinkTstAll or test_link_inA(i)) = '0' else '0';
		credit_inB(i) <= credit_inA(i) when (strLinkTstAll or test_link_inA(i)) = '0' else '0';
		
		data_outB(i) <= data_outA(i) when strLinkTstAll = '0' and test_link_inA(i) = '0' else --passagem do data_out normal
				data_inA(i)   when test_link_inA(i) = '1' and strLinkTstAll = '0' else -- retransmissao do dado de test_link
				(others=>'1') when strLinkTstAll ='1' and compTest = '1' else --envio do dado(1) de test_link
				(others=>'0') when strLinkTstAll ='1' and compTest = '0' else --envio do dado(2) de test_link
				(others=>'Z');
		
		tmp(i) <= '0'	when compTest = '1' and (data_inA(i) xor fillOne) = x"0" else
				  '1'	when compTest = '1' else
				  '0'	when compTest = '0' and (data_inA(i) xor fillZero) = x"0" else
				  '1'	when compTest = '0' else
				  'Z';
	end generate ALL_MUX;
	
	--maquina de estados para transmitir e receber os dados
	process(clock,reset)
	begin
		if reset = '1' then
			stopLinkTest <= '0';
			compTest <= '0';
			EA <= S_INIT;
		elsif (clock'event and clock='1') then
			case EA is
				when S_INIT =>
					if strLinkTstAll = '1' then
						stopLinkTest <= '0';
						compTest <= '0';
						EA <= S_FIRSTDATA;
					end if;
				when S_FIRSTDATA =>
					faultTableReg(EAST) <= tmp(EAST);
					faultTableReg(WEST) <= tmp(WEST);
					faultTableReg(NORTH) <= tmp(NORTH);
					faultTableReg(SOUTH) <= tmp(SOUTH);
					faultTableReg(LOCAL) <= tmp(LOCAL);
					compTest <= '1';
					EA <= S_SECONDDATA;
				when S_SECONDDATA =>
					faultTableReg(EAST) <= faultTableReg(EAST) or tmp(EAST);
					faultTableReg(WEST) <= faultTableReg(WEST) or tmp(WEST);
					faultTableReg(NORTH) <= faultTableReg(NORTH) or tmp(NORTH);
					faultTableReg(SOUTH) <= faultTableReg(SOUTH) or tmp(SOUTH);
					faultTableReg(LOCAL) <= faultTableReg(LOCAL) or tmp(LOCAL);
					stopLinkTest <= '1';
					EA <= S_END;
				when S_END =>
					stopLinkTest <= '0';
					EA <= S_INIT;
				when others =>
					EA <= S_INIT;
			end case;
		end if;
	end process;
end Behavioral;