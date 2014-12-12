---------------------------------------------------------------------------------------	
--                                    ROUTER
--
--
--                                    NORTH         LOCAL
--                      -----------------------------------
--                      |             ******       ****** |
--                      |             *FILA*       *FILA* |
--                      |             ******       ****** |
--                      |          *************          |
--                      |          *  ARBITRO  *          |
--                      | ******   *************   ****** |
--                 WEST | *FILA*   *************   *FILA* | EAST
--                      | ******   *  CONTROLE *   ****** |
--                      |          *************          |
--                      |             ******              |
--                      |             *FILA*              |
--                      |             ******              |
--                      -----------------------------------
--                                    SOUTH
--
--  As chaves realizam a transferência de mensagens entre ncleos. 
--  A chave possui uma lógica de controle de chaveamento e 5 portas bidirecionais:
--  East, West, North, South e Local. Cada porta possui uma fila para o armazenamento 
--  temporário de flits. A porta Local estabelece a comunicação entre a chave e seu 
--  ncleo. As demais portas ligam a chave à chaves vizinhas.
--  Os endereços das chaves são compostos pelas coordenadas XY da rede de interconexão, 
--  onde X sãa posição horizontal e Y a posição vertical. A atribuição de endereços é 
--  chaves é necessária para a execução do algoritmo de chaveamento.
--  Os módulos principais que compõem a chave são: fila, árbitro e lógica de 
--  chaveamento implementada pelo controle_mux. Cada uma das filas da chave (E, W, N, 
--  S e L), ao receber um novo pacote requisita chaveamento ao árbitro. O árbitro 
--  seleciona a requisição de maior prioridade, quando existem requisições simultâneas, 
--  e encaminha o pedido de chaveamento é lógica de chaveamento. A lógica de 
--  chaveamento verifica se é possível atender é solicitação. Sendo possível, a conexão
--  é estabelecida e o árbitro é informado. Por sua vez, o árbitro informa a fila que 
--  começa a enviar os flits armazenados. Quando todos os flits do pacote foram 
--  enviados, a conexão é concluída pela sinalização, por parte da fila, através do 
--  sinal sender.
---------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.HermesPackage.all;
use work.TablePackage.all;

entity RouterCC is
generic( 
	address: regmetadeflit;
	ramInit: memory);
port(
	clock:     in  std_logic;
	reset:     in  std_logic;
	testLink_i:  in  regNport;
	clock_rx:  in  regNport;
	rx:        in  regNport;
	data_in:   in  arrayNport_regflit;
	testLink_o: out regNport;
	credit_o:  out regNport;
	clock_tx:  out regNport;
	tx:        out regNport;
	data_out:  out arrayNport_regflit;
	credit_i:  in  regNport);
end RouterCC;

architecture RouterCC of RouterCC is

signal h, ack_h, data_av, sender, data_ack: regNport := (others=>'0');
signal data: arrayNport_regflit := (others=>(others=>'0'));
signal mux_in, mux_out: arrayNport_reg3 := (others=>(others=>'0'));
signal free: regNport := (others=>'0');

------------New Hardware------------
signal c_ctrl : std_logic;
signal c_CodControle : regflit;
signal c_BuffCtrl : buffControl;
signal c_ceTR : std_logic; --[c_ce][T]abela[R]oteamento
signal c_ceTF : regNport := (others=>'0'); --[c_ce][T]abela[F]alhas
signal c_BuffTabelaFalhas : ArrayRegNport := (others=>(others=>'0'));
signal c_erro_ArrayFind : ArrayRouterControl;
signal c_erro_dir : regNport;
signal c_tabela_falhas: regNport;
signal c_test_link_out: regNport;
signal c_data_test: regFlit;
signal credit_i_A : regNport;
signal credit_o_A : regNport;
signal data_out_A : arrayNport_regflit;
signal c_stpLinkTst : regNport;
signal c_strLinkTst : regNport;
signal c_faultTableFDM : regNport;
signal c_strLinkTstOthers : regNport := (others=>'0');


begin

	testLink_o <= (others=>'1') when c_strLinkTst /= x"0" 
			else (others=>'0');
			
	c_strLinkTstOthers <= (others=>'1') when testLink_i /= x"0"
			else (others=>'0');

	FEast : Entity work.Hermes_buffer
	generic map(address => address)
	port map(
		clock => clock,
		reset => reset,
		data_in => data_in(0),
		rx => rx(0),
		h => h(0),
		c_buffCtrlFalha => c_BuffTabelaFalhas(0),
		c_ceTF_out => c_ceTF(0),
		c_error_Find => c_erro_ArrayFind(0),
		c_error_dir => c_erro_dir,
		c_tabelaFalhas => c_tabela_falhas,
		c_strLinkTst => c_strLinkTst(0),
		c_stpLinkTst => c_stpLinkTst(0),
		c_strLinkTstOthers => c_strLinkTstOthers(0),
		ack_h => ack_h(0),
		data_av => data_av(0),
		data => data(0),
		sender => sender(0),
		clock_rx => clock_rx(0),
		data_ack => data_ack(0),
		credit_o => credit_o_A(0));

	
	FWest : Entity work.Hermes_buffer
	generic map(address => address)
	port map(
		clock => clock,
		reset => reset,
		data_in => data_in(1),
		rx => rx(1),
		h => h(1),
		c_buffCtrlFalha => c_BuffTabelaFalhas(1),
		c_ceTF_out => c_ceTF(1),
		c_error_Find => c_erro_ArrayFind(1),
		c_error_dir => c_erro_dir,
		c_tabelaFalhas => c_tabela_falhas,
		c_strLinkTst => c_strLinkTst(1),
		c_stpLinkTst => c_stpLinkTst(1),
		c_strLinkTstOthers => c_strLinkTstOthers(1),
		ack_h => ack_h(1),
		data_av => data_av(1),
		data => data(1),
		sender => sender(1),
		clock_rx => clock_rx(1),
		data_ack => data_ack(1),
		credit_o => credit_o_A(1));

	FNorth : Entity work.Hermes_buffer
	generic map(address => address)
	port map(
		clock => clock,
		reset => reset,
		data_in => data_in(2),
		rx => rx(2),
		h => h(2),
		c_buffCtrlFalha => c_BuffTabelaFalhas(2),
		c_ceTF_out => c_ceTF(2),
		c_error_Find => c_erro_ArrayFind(2),
		c_error_dir => c_erro_dir,
		c_tabelaFalhas => c_tabela_falhas,
		c_strLinkTst => c_strLinkTst(2),
		c_stpLinkTst => c_stpLinkTst(2),
		c_strLinkTstOthers => c_strLinkTstOthers(2),
		ack_h => ack_h(2),
		data_av => data_av(2),
		data => data(2),
		sender => sender(2),
		clock_rx => clock_rx(2),
		data_ack => data_ack(2),
		credit_o => credit_o_A(2));

	FSouth : Entity work.Hermes_buffer
	generic map(address => address)
	port map(
		clock => clock,
		reset => reset,
		data_in => data_in(3),
		rx => rx(3),
		h => h(3),
		c_buffCtrlFalha => c_BuffTabelaFalhas(3),
		c_ceTF_out => c_ceTF(3),
		c_error_Find => c_erro_ArrayFind(3),
		c_error_dir => c_erro_dir,
		c_tabelaFalhas => c_tabela_falhas,
		c_strLinkTst => c_strLinkTst(3),
		c_stpLinkTst => c_stpLinkTst(3),
		c_strLinkTstOthers => c_strLinkTstOthers(3),
		ack_h => ack_h(3),
		data_av => data_av(3),
		data => data(3),
		sender => sender(3),
		clock_rx => clock_rx(3),
		data_ack => data_ack(3),
		credit_o => credit_o_A(3));

	FLocal : Entity work.Hermes_buffer
	generic map(address => address)
	port map(
		clock => clock,
		reset => reset,
		data_in => data_in(4),
		rx => rx(4),
		h => h(4),
		c_ctrl=> c_ctrl,
		c_buffCtrlOut=> c_BuffCtrl,
		c_codigoCtrl=> c_CodControle,
		c_chipETable => c_ceTR,
		c_buffCtrlFalha => c_BuffTabelaFalhas(4),
		c_ceTF_out => c_ceTF(4),
		c_error_Find => c_erro_ArrayFind(4),
		c_error_dir => c_erro_dir,
		c_tabelaFalhas => c_tabela_falhas,
		c_strLinkTst => c_strLinkTst(4),
		c_stpLinkTst => c_stpLinkTst(4),
		c_strLinkTstOthers => c_strLinkTstOthers(4),
		ack_h => ack_h(4),
		data_av => data_av(4),
		data => data(4),
		sender => sender(4),
		clock_rx => clock_rx(4),
		data_ack => data_ack(4),
		credit_o => credit_o_A(4));

	FaultDetection: Entity work.FaultDetection
	port map(
		clock => clock,
		reset => reset,
		c_strLinkTst => c_strLinkTst,
		c_stpLinkTst => c_stpLinkTst,
		test_link_inA => testLink_i,
		data_outA => data_out_A,
		data_inA => data_in,
		credit_inA => credit_i,
		credit_outA => credit_o_A,
		data_outB => data_out,
		credit_inB => credit_i_A,
		c_faultTableFDM => c_faultTableFDM,
		credit_outB =>credit_o);
		
		
	SwitchControl : Entity work.SwitchControl
	generic map(
		address => address,
		ramInit => ramInit)
	port map(
		clock => clock,
		reset => reset,
		h => h,
		ack_h => ack_h,
		data => data,
		c_Ctrl => c_ctrl,
		c_buffTabelaFalhas_in=> c_BuffTabelaFalhas,
		c_CodControle => c_CodControle,
		c_BuffCtrl => c_BuffCtrl,
		c_ce => c_ceTR,
		c_ceTF_in => c_ceTF,
		c_error_ArrayFind => c_erro_ArrayFind,
		c_error_dir => c_erro_dir,
		c_tabelaFalhas => c_tabela_falhas,
		c_strLinkTst => c_strLinkTst,
		c_faultTableFDM => c_faultTableFDM,
		sender => sender,
		free => free,
		mux_in => mux_in,
		mux_out => mux_out);

	CrossBar : Entity work.Hermes_crossbar
	port map(
		data_av => data_av,
		data_in => data,
		data_ack => data_ack,
		sender => sender,
		free => free,
		tab_in => mux_in,
		tab_out => mux_out,
		tx => tx,
		data_out => data_out_A,
		credit_i => credit_i_A);

	CLK_TX : for i in 0 to(NPORT-1) generate
		clock_tx(i) <= clock;
	end generate CLK_TX;  

end RouterCC;