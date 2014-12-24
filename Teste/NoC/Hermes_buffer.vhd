---------------------------------------------------------------------------------------
--                            BUFFER
--                        --------------
--                   RX ->|            |-> H
--              DATA_IN ->|            |<- ACK_H
--             CLOCK_RX ->|            |
--             CREDIT_O <-|            |-> DATA_AV
--                        |            |-> DATA
--                        |            |<- DATA_ACK
--                        |            |
--                        |            |   
--                        |            |=> SENDER
--                        |            |   all ports
--                        --------------
--
--  Quando o algoritmo de chaveamento resulta no bloqueio dos flits de um pacote, 
--  ocorre uma perda de desempenho em toda rede de interconexao, porque os flits sao 
--  bloqueados nao somente na chave atual, mas em todas as intermediarias. 
--  Para diminuir a perda de desempenho foi adicionada uma fila em cada porta de 
--  entrada da chave, reduzindo as chaves afetadas com o bloqueio dos flits de um 
--  pacote. E importante observar que quanto maior for o tamanho da fila menor sera o 
--  numero de chaves intermediarias afetadas. 
--  As filas usadas contem dimensao e largura de flit parametrizaveis, para altera-las
--  modifique as constantes TAM_BUFFER e TAM_FLIT no arquivo "Hermes_packet.vhd".
--  As filas funcionam como FIFOs circulares. Cada fila possui dois ponteiros: first e 
--  last. First aponta para a posicao da fila onde se encontra o flit a ser consumido. 
--  Last aponta para a posicao onde deve ser inserido o proximo flit.
---------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.HermesPackage.all;

-- interface da Hermes_buffer
entity Hermes_buffer is
	generic(address : regmetadeflit := (others=>'0'));
port(
	clock:      in  std_logic;
	reset:      in  std_logic;
	clock_rx:   in  std_logic;
	rx:         in  std_logic;
	data_in:    in  regflit;
	credit_o:   out std_logic;
	h:          out std_logic;
	ack_h:      in  std_logic;
	data_av:    out std_logic;
	data:       out regflit;
	data_ack:   in  std_logic;
	sender:     out std_logic);
end Hermes_buffer;

architecture Hermes_buffer of Hermes_buffer is

type fila_out is (S_INIT, S_PAYLOAD, S_SENDHEADER, S_HEADER, S_END, S_END2);
signal EA : fila_out;

signal buf: buff := (others=>(others=>'0'));
signal first,last: pointer := (others=>'0');
signal tem_espaco: std_logic := '0';
signal counter_flit: regflit := (others=>'0');

begin
	
	-------------------------------------------------------------------------------------------
	-- ENTRADA DE DADOS NA FILA
	-------------------------------------------------------------------------------------------

	-- Verifica se existe espaco na fila para armazenamento de flits.
	-- Se existe espaco na fila o sinal tem_espaco_na_fila eh igual a 1.
	process(reset, clock_rx)
	begin
		if reset = '1' then
			tem_espaco <= '1';
		elsif clock_rx'event and clock_rx = '1' then
			if not ((first = x"0" and last = TAM_BUFFER - 1) or (first = last + 1)) then
				tem_espaco <= '1';
			else
				tem_espaco <= '0';
			end if;
		end if;
	end process;

	credit_o <= tem_espaco;

	-- O ponteiro last eh inicializado com o valor zero quando o reset eh ativado.
	-- Quando o sinal rx eh ativado indicando que existe um flit na porta de entrada. Eh
	-- verificado se existe espaco na fila para armazena-lo. Se existir espaco na fila o
	-- flit recebido eh armazenado na posicao apontada pelo ponteiro last e o mesmo eh
	-- incrementado. Quando last atingir o tamanho da fila, ele recebe zero.
	process(reset, clock_rx)
	begin
		if reset = '1' then
			last <= (others=>'0');
		elsif clock_rx'event and clock_rx = '0' then
			if tem_espaco = '1' and rx = '1' then
				buf(CONV_INTEGER(last)) <= data_in;
				--incrementa o last
				if last = TAM_BUFFER - 1 then 
				  last <= (others=>'0');
				else 
				  last <= last + 1;
				end if;
			end if;
		end if;
	end process;
	-------------------------------------------------------------------------------------------
	-- SAIDA DE DADOS NA FILA
	-------------------------------------------------------------------------------------------

	-- disponibiliza o dado para transmissao.
	data <= buf(CONV_INTEGER(first));

	-- Quando sinal reset eh ativado a maquina de estados avanca para o estado S_INIT.
	-- No estado S_INIT os sinais counter_flit (contador de flits do corpo do pacote), h (que
	-- indica requisicao de chaveamento) e data_av (que indica a existencia de flit a ser
	-- transmitido) sao inicializados com zero. Se existir algum flit na fila, ou seja, os
	-- ponteiros first e last apontarem para posicoes diferentes, a maquina de estados avanca
	-- para o estado S_HEADER.
	-- No estado S_HEADER eh requisitado o chaveamento (h='1'), porque o flit na posicao
	-- apontada pelo ponteiro first, quando a maquina encontra-se nesse estado, eh sempre o
	-- header do pacote. A maquina permanece neste estado ate que receba a confirmacao do
	-- chaveamento (ack_h='1') entao o sinal h recebe o valor zero e a maquina avanca para
	-- S_SENDHEADER.
	-- Em S_SENDHEADER eh indicado que existe um flit a ser transmitido (data_av='1'). A maquina de
	-- estados permanece em S_SENDHEADER ate receber a confirmacao da transmissao (data_ack='1')
	-- entao o ponteiro first aponta para o segundo flit do pacote e avanca para o estado S_PAYLOAD.
	-- No estado S_PAYLOAD eh indicado que existe um flit a ser transmitido (data_av='1') quando
	-- eh recebida a confirmacao da transmissao (data_ack='1') eh verificado qual o valor do sinal
	-- counter_flit. Se counter_flit eh igual a um, a maquina avanca para o estado S_INIT. Caso
	-- counter_flit seja igual a zero, o sinal counter_flit eh inicializado com o valor do flit, pois
	-- este ao numero de flits do corpo do pacote. Caso counter_flit seja diferente de um e de zero
	-- o mesmo eh decrementado e a maquina de estados permanece em S_PAYLOAD enviando o proximo flit
	-- do pacote.
	process(reset, clock)
	begin
		if reset = '1' then
			counter_flit <= (others=>'0');
			h <= '0';
			data_av <= '0';
			sender <=  '0';
			first <= (others=>'0');
			EA <= S_INIT;
		elsif clock'event and clock = '1' then
			case EA is
				when S_INIT =>
					counter_flit <= (others=>'0');
					data_av <= '0';
					if first /= last then -- detectou dado na fila
						  h <= '1';         -- pede roteamento
						  EA <= S_HEADER;
					else
						h <= '0';
					end if;

				when S_HEADER =>
					if ack_h = '1' then -- confirmacao de roteamento
						EA <= S_SENDHEADER;
						h <= '0';
						data_av <= '1';
						sender <= '1';
					end if;
				when S_SENDHEADER  =>
					if data_ack = '1' then  -- confirmacao do envio do header
						-- retira o header do buffer e se tem dado no buffer pede envio do mesmo
							EA <= S_PAYLOAD;
							if first = TAM_BUFFER - 1 then
								first <= (others=>'0');
								if last /= 0 then	data_av <= '1';
								else data_av <= '0';
								end if;
							else
								first <= first + 1;
								if first + 1 /= last then data_av <= '1';
								else data_av <= '0';
								end if;
							end if;
					end if;
				when S_PAYLOAD =>
					if counter_flit /= x"1" and ( data_ack = '1') then -- confirmacao do envio de um dado que nao eh o tail
						-- se counter_flit eh zero indica recepcao do size do payload
						if counter_flit = x"0" then
							counter_flit <=  buf(CONV_INTEGER(first));
						else
							counter_flit <= counter_flit - 1;
						end if;

						-- retira um dado do buffer e se tem dado no buffer pede envio do mesmo
						if first = TAM_BUFFER - 1 then
							first <= (others=>'0');
							if last /= 0 then
								data_av <= '1';
							else
								data_av <= '0';
							end if;
						else
							first <= first + 1;
							if first + 1 /= last then
								data_av <= '1';
							else
								data_av <= '0';
							end if;
						end if;
					elsif counter_flit = x"1" and (data_ack = '1') then -- confirmacao do envio do tail
						-- retira um dado do buffer
						if first = TAM_BUFFER - 1 then
							first <= (others=>'0');
						else
							first <= first + 1;
						end if;
						data_av <= '0';
						sender <= '0';
						EA <= S_END;
					elsif first /= last then -- se tem dado a ser enviado faz a requisicao
						data_av <= '1';
					end if;

				when S_END =>
					data_av <= '0';
					EA <= S_END2;
				when S_END2 => -- estado necessario para permitir a liberacao da porta antes da solicitacao de novo envio
					data_av <= '0';
					EA <= S_INIT;
			end case;
		end if;
	end process;
	
end Hermes_buffer;