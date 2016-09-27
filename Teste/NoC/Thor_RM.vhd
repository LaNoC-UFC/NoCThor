---------------------------------------------------------
-- Routing Mechanism
---------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ThorPackage.all;
use work.TablePackage.all;

entity routingMechanism is
	generic(
			ramInit : memory := (others=>(others=>'0'))
			);
	port(
			clock :   in  std_logic;
			reset :   in  std_logic;
			oe :   in  std_logic;
			dest : in regflit;
			inputPort : in integer range 0 to (NPORT-1);
			outputPort : out regNPort;
			find : out RouterControl
		);
end routingMechanism;

architecture behavior of routingMechanism is

	-- sinais da máquina de estado
	type state is (S0,S1,S2,S3,S4);
	signal ES, PES : state;
	
	-- sinais da Tabela
	signal data : regNPort := (others=>'0');
	signal rowDst, colDst : integer;
	type row is array ((NREG-1) downto 0) of integer;
	signal rowInf, colInf, rowSup, colSup : row;
	signal H : std_logic_vector((NREG-1) downto 0);
	-------------New Hardware---------------
	signal VertInf, VertSup : regAddr;
	type arrayIP is array ((NREG-1) downto 0) of std_logic_vector(4 downto 0);
	signal IP : arrayIP;
	signal RAM: memory := ramInit;
	
begin

	rowDst <= TO_INTEGER(unsigned(dest(TAM_FLIT-1 downto METADEFLIT))) when oe = '1' else 0;
	colDst <= TO_INTEGER(unsigned(dest(METADEFLIT-1 downto 0))) when oe = '1' else 0;

	cond: for j in 0 to (NREG - 1) generate

		IP(j) 	  <= RAM(j)(CELL_SIZE-1 downto CELL_SIZE-5) when oe = '1' else (others=>'0'); -- 13 downto 9
		rowInf(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6 downto CELL_SIZE-5-NBITS))) when oe = '1' else 0; -- 8 downto 8
		colInf(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-NBITS downto CELL_SIZE-5-2*NBITS))) when oe = '1' else 0; -- 7 downto 7
		rowSup(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-2*NBITS downto CELL_SIZE-5-3*NBITS))) when oe = '1' else 0; -- 6 downto 6
		colSup(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-3*NBITS downto 5))) when oe = '1' else 0; -- 5 downto 5


		H(j) <= '1' when rowDst >= rowInf(j) and rowDst <= rowSup(j) and
			       	   colDst >= colInf(j) and colDst <= colSup(j) and 
			       	   IP(j)(inputPort) = '1' and oe = '1' else 
		      '0';

	end generate;

	process(RAM, H, oe)
	begin
		data <= (others=>'Z');
		find <= invalidRegion;
		if oe = '1' then
			for i in 0 to (NREG-1) loop
				if H(i) = '1' then
					data <= RAM(i)(NPORT-1 downto 0); -- OP
					find <= validRegion;
					exit;
				end if;
			end loop;
		end if;
	end process;

	outputPort <= data;

end behavior;

