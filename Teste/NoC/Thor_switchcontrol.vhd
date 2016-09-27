library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_unsigned.all;
use work.ThorPackage.all;
use work.TablePackage.all;

entity SwitchControl is
generic(
	address : regflit := (others=>'0');
	ramInit : memory);
port(
	clock :   in  std_logic;
	reset :   in  std_logic;
	h :       in  regNport;
	ack_h :   out regNport;
	data :    in  arrayNport_regflit;
	sender :  in  regNport;
	free :    out regNport;
	mux_in :  out arrayNport_reg3;
	mux_out : out arrayNport_reg3);
end SwitchControl;

architecture RoutingTable of SwitchControl is

	type state is (S0,S1,S2,S3,S4,S5,S6,S7);
	signal ES, PES: state;

-- sinais do arbitro
	signal ask: std_logic := '0';
	signal sel,prox: integer range 0 to (NPORT-1) := 0;
	signal incoming: reg3 := (others=> '0');
	signal header : regflit := (others=> '0');

-- sinais do controle
	signal indice_dir: integer range 0 to (NPORT-1) := 0;
	signal auxfree: regNport := (others=> '0');
	signal source:  arrayNport_reg3 := (others=> (others=> '0'));
	signal sender_ant: regNport := (others=> '0');
	signal dir: regNport:= (others=> '0');

-- sinais de controle da tabela
	signal find: RouterControl;
	signal ceTable: std_logic := '0';
	
begin
	ask <= '1' when (h(LOCAL)='1' or h(EAST)='1' or h(WEST)='1' or h(NORTH)='1' or h(SOUTH)='1') else '0';
	incoming <= CONV_VECTOR(sel);
	header <= data(CONV_INTEGER(incoming));

	process(sel, h)
	begin
		case sel is
			when LOCAL=>
				if h(EAST)='1' then prox<=EAST;
				elsif h(WEST)='1' then prox<=WEST;
				elsif h(NORTH)='1' then prox<=NORTH;
				elsif h(SOUTH)='1' then prox<=SOUTH;
				else prox<=LOCAL; end if;
			when EAST=>
				if h(WEST)='1' then prox<=WEST;
				elsif h(NORTH)='1' then prox<=NORTH;
				elsif h(SOUTH)='1' then prox<=SOUTH;
				elsif h(LOCAL)='1' then prox<=LOCAL;
				else prox<=EAST; end if;
			when WEST=>
				if h(NORTH)='1' then prox<=NORTH;
				elsif h(SOUTH)='1' then prox<=SOUTH;
				elsif h(LOCAL)='1' then prox<=LOCAL;
				elsif h(EAST)='1' then prox<=EAST;
				else prox<=WEST; end if;
			when NORTH=>
				if h(SOUTH)='1' then prox<=SOUTH;
				elsif h(LOCAL)='1' then prox<=LOCAL;
				elsif h(EAST)='1' then prox<=EAST;
				elsif h(WEST)='1' then prox<=WEST;
				else prox<=NORTH; end if;
			when SOUTH=>
				if h(LOCAL)='1' then prox<=LOCAL;
				elsif h(EAST)='1' then prox<=EAST;
				elsif h(WEST)='1' then prox<=WEST;
				elsif h(NORTH)='1' then prox<=NORTH;
				else prox<=SOUTH; end if;
		end case;
	end process;

	RoutingMechanism : entity work.routingMechanism
	generic map(
		ramInit => ramInit)
	port map(
			clock => clock,
			reset => reset,
			oe => ceTable,
			dest => header,
			inputPort => sel,
			outputPort => dir,
			find => find
		);

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
	-- SO -> O estado S0 é o estado de inicialização da máquina. Este estado somente é	
	--       atingido quando o sinal reset é ativado.
	-- S1 -> O estado S1 é o estado de espera por requisição de chaveamento. Quando o
	--       árbitro recebe uma ou mais requisições o sinal ask é ativado fazendo a
	--       máquina avançar para o estado S2.
	-- S2 -> No estado S2 a porta de entrada que solicitou chaveamento é selecionada. Se
	--       houver mais de uma, aquela com maior prioridade é a selecionada. Se o destino
	--			for o próprio roteador pula para o estado S4, caso contrário segue o fluxo
	--			normal.
	-- S3 -> Este estado é muito parecido com o do algoritmo XY, a diferença é que ele
	--		 verifica o destino do pacote através de uma tabela e não por cálculos.
	--		          4       3       2      1      0
	-- dir -> 	| Local | South | North | West | East |
	process(ES,ask,h,auxfree,dir,find)
	begin

		case ES is
			when S0 => PES <= S1;
			when S1 => if ask='1' then PES <= S2; else PES <= S1; end if;
			when S2 => PES <= S3;
			when S3 => 
					if address = header and auxfree(LOCAL)='1' then PES<=S4;
					elsif(find = validRegion)then
  				     if    (dir(EAST)='1' and  auxfree(EAST)='1') then
						 indice_dir <= EAST ; 
					    PES<=S5;
					  elsif (dir(WEST)='1' and  auxfree(WEST)='1') then
						 indice_dir <= WEST; 
					    PES<=S5;
	  				  elsif (dir(NORTH)='1' and  auxfree(NORTH)='1' ) then
						 indice_dir <= NORTH; 
					    PES<=S6;
					  elsif (dir(SOUTH)='1' and  auxfree(SOUTH)='1' ) then
						 indice_dir <= SOUTH; 
					    PES<=S6;
			  		  else PES<=S1; end if;
					elsif(find = portError)then
						PES <= S1;
					else
					  PES<=S3;
					end if;
			when S4 => PES<=S7;
			when S5 => PES<=S7;
			when S6 => PES<=S7;
			when S7 => PES<=S1;
		end case;
	end process;


	------------------------------------------------------------------------------------------------------
	-- executa as ações correspondente ao estado atual da máquina de estados
	------------------------------------------------------------------------------------------------------
	process(clock)
	begin
		if clock'event and clock='1' then
			case ES is
				-- Zera variáveis
				when S0 =>
					ceTable <= '0';
					sel <= 0;
					ack_h <= (others => '0');
					auxfree <= (others=> '1');
					sender_ant <= (others=> '0');
					mux_out <= (others=>(others=>'0'));
					source <= (others=>(others=>'0'));
				-- Chegou um header
				when S1=>
					ceTable <= '0';
					ack_h <= (others => '0');
				-- Seleciona quem tera direito a requisitar roteamento
				when S2=>
					sel <= prox;
				-- Aguarda resposta da Tabela					
				when S3 =>
					if address /= header then
						ceTable <= '1';
					end if;
				-- Estabelece a conexão com a porta LOCAL
				when S4 =>
					source(CONV_INTEGER(incoming)) <= CONV_VECTOR(LOCAL);
					mux_out(LOCAL) <= incoming;
					auxfree(LOCAL) <= '0';
					ack_h(sel)<='1';
				-- Estabelece a conexão com a porta EAST ou WEST
				when S5 =>
					source(CONV_INTEGER(incoming)) <= CONV_VECTOR(indice_dir);
					mux_out(indice_dir) <= incoming;
					auxfree(indice_dir) <= '0';
					ack_h(sel)<='1';
				-- Estabelece a conexão com a porta NORTH ou SOUTH
				when S6 =>
					source(CONV_INTEGER(incoming)) <= CONV_VECTOR(indice_dir);
					mux_out(indice_dir) <= incoming;
					auxfree(indice_dir) <= '0';
					ack_h(sel)<='1';
				when others => 
					ack_h(sel)<='0';
					ceTable <= '0';
			end case;

			sender_ant(LOCAL) <= sender(LOCAL);
			sender_ant(EAST)  <= sender(EAST);
			sender_ant(WEST)  <= sender(WEST);
			sender_ant(NORTH) <= sender(NORTH);
			sender_ant(SOUTH) <= sender(SOUTH);

			if sender(LOCAL)='0' and  sender_ant(LOCAL)='1' then auxfree(CONV_INTEGER(source(LOCAL))) <='1'; end if;
			if sender(EAST) ='0' and  sender_ant(EAST)='1'  then auxfree(CONV_INTEGER(source(EAST)))  <='1'; end if;
			if sender(WEST) ='0' and  sender_ant(WEST)='1'  then auxfree(CONV_INTEGER(source(WEST)))  <='1'; end if;
			if sender(NORTH)='0' and  sender_ant(NORTH)='1' then auxfree(CONV_INTEGER(source(NORTH))) <='1'; end if;
			if sender(SOUTH)='0' and  sender_ant(SOUTH)='1' then auxfree(CONV_INTEGER(source(SOUTH))) <='1'; end if;

		end if;
	end process;


	mux_in <= source;
	free <= auxfree;


end RoutingTable;