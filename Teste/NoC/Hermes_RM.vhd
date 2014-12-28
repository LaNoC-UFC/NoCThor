---------------------------------------------------------
-- Routing Mechanism
---------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.HermesPackage.all;
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
	signal ce: std_logic := '0';
	signal data : regNPort := (others=>'0');
	signal ctrl : std_logic := '0';
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

	ctrl <= '0';
	rowDst <= TO_INTEGER(unsigned(dest(TAM_FLIT-1 downto METADEFLIT))) when ctrl = '0' else 0;
	colDst <= TO_INTEGER(unsigned(dest(METADEFLIT-1 downto 0))) when ctrl = '0' else 0;

	cond: for j in 0 to (NREG - 1) generate

		IP(j) 	  <= RAM(j)(CELL_SIZE-1 downto CELL_SIZE-5) when ctrl = '0' else (others=>'0'); -- 13 downto 9
		rowInf(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6 downto CELL_SIZE-5-NBITS))) when ctrl = '0' else 0; -- 8 downto 8
		colInf(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-NBITS downto CELL_SIZE-5-2*NBITS))) when ctrl = '0' else 0; -- 7 downto 7
		rowSup(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-2*NBITS downto CELL_SIZE-5-3*NBITS))) when ctrl = '0' else 0; -- 6 downto 6
		colSup(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-3*NBITS downto 5))) when ctrl = '0' else 0; -- 5 downto 5


		H(j) <= '1' when rowDst >= rowInf(j) and rowDst <= rowSup(j) and
			       	   colDst >= colInf(j) and colDst <= colSup(j) and 
			       	   IP(j)(inputPort) = '1' and ctrl = '0' else 
		      '0';

	end generate;

	process(RAM, H, ce, ctrl)
	begin
		data <= (others=>'Z');
		if ce = '1' and ctrl = '0' then
			for i in 0 to (NREG-1) loop
				if H(i) = '1' then
					data <= RAM(i)(4 downto 0); -- OP
				end if;
			end loop;
		end if;
	end process;

	process(reset,clock)
	begin
		if reset='1' then
			ES<=S0;
		elsif clock'event and clock='0' then
			ES<=PES;
		end if; 
	end process;
	
	------------------------------------------------------------------------------------------------------
	-- PARTE COMBINACIONAL PARA DEFINIR O PRÓXIMO ESTADO DA MÁQUINA.
	--
	-- S0 -> Este estado espera oe = '1' (operation enabled), indicando que há um pacote que que deve
	--       ser roteado.
	-- S1 -> Este estado ocorre a leitura na memória - tabela, a fim de obter as 
	--       definições de uma região.
	-- S2 -> Este estado verifica se o roteador destino (destRouter) pertence aquela
	--       região. Caso ele pertença o sinal de RM é ativado e a máquina de estados
	--       avança para o próximo estado, caso contrário retorna para o estado S1 e
	--       busca por uma nova região.
	-- S3 -> Neste estado o switch control é avisado (find="01") que foi descoberto por 
	--       qual porta este pacote deve sair. Este estado também zera count, valor que 
	--			aponta qual o próximo endereço deve ser lido na memória.
	-- S4 -> Aguarda oe = '0' e retorna para o estado S0.
	
	process(ES, oe)
	begin
		case ES is
			when S0 => if oe = '1' then PES <= S1; else PES <= S0; end if;
			when S1 => PES <= S2;
			when S2 => PES <= S3;
			when S3 => if oe = '0' then PES <= S0; else PES <= S3; end if;
			when others => PES <= S0;
		end case;
	end process;
	
	------------------------------------------------------------------------------------------------------
	-- executa as ações correspondente ao estado atual da máquina de estados
	------------------------------------------------------------------------------------------------------
	process(clock)
	begin
		if(clock'event and clock = '1') then
			case ES is
				-- Aguarda oe='1'
				when S0 =>
					find <= invalidRegion;
					
				-- Leitura da tabela
				when S1 =>
					ce <= '1';
					
				-- Informa que achou a porta de saída para o pacote
				when S2 =>
					find <= validRegion;
				-- Aguarda oe='0'
				when S3 =>
					ce <= '0';
					find <= invalidRegion;
				when others =>
					find <= portError;
			end case;
		end if;
	end process;
	outputPort <= data;
end behavior;	