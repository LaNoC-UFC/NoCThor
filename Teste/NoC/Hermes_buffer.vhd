library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.HermesPackage.all;

entity Hermes_buffer is
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
signal aux_data_av: std_logic;

begin
	
	-------------------------------------------------------------------------------------------
	-- ENTRADA DE DADOS NA FILA
	-------------------------------------------------------------------------------------------

	-- Verifica se existe espaco na fila para armazenamento de flits.
	-- Se existe espaco na fila o sinal tem_espaco_na_fila eh igual a 1.
	process(reset, clock_rx, first, last)
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

	process(reset, clock_rx, tem_espaco, rx, data_in)
	begin
		if reset = '1' then
			last <= (others=>'0');
		elsif clock_rx'event and clock_rx = '0' and tem_espaco = '1' and rx = '1' then
			buf(CONV_INTEGER(last)) <= data_in;
			--incrementa o last
			if last = TAM_BUFFER - 1 then last <= (others=>'0');
			else last <= last + 1;
			end if;
		end if;
	end process;
	-------------------------------------------------------------------------------------------
	-- SAIDA DE DADOS NA FILA
	-------------------------------------------------------------------------------------------

	-- disponibiliza o dado para transmissao.
	data <= buf(CONV_INTEGER(first));
	data_av <= aux_data_av;

	process(reset, clock)
	begin
		if reset = '1' then
			counter_flit <= (others=>'0');
			h <= '0';
			aux_data_av <= '0';
			sender <=  '0';
			first <= (others=>'0');
			EA <= S_INIT;
		elsif clock'event and clock = '1' then
			case EA is
				when S_INIT =>
					counter_flit <= (others=>'0');
					aux_data_av <= '0';
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
						aux_data_av <= '1';
						sender <= '1';
					end if;
				when S_SENDHEADER  =>
					if data_ack = '1' and aux_data_av = '1' then  -- confirmacao do envio do header
						-- retira o header do buffer e se tem dado no buffer pede envio do mesmo
							EA <= S_PAYLOAD;
							if first = TAM_BUFFER - 1 then
								if last /= 0 then aux_data_av <= '1';
								else aux_data_av <= '0';
								end if;
								first <= (others=>'0');
							else
								if first + 1 /= last then aux_data_av <= '1';
								else aux_data_av <= '0';
								end if;
								first <= first + 1;
							end if;
					end if;
				when S_PAYLOAD =>
					if data_ack = '1' and aux_data_av = '1' then
						-- dependendo do tipo de dado
						if counter_flit = x"0" then
						-- indica recepcao do size do payload
							counter_flit <=  buf(CONV_INTEGER(first));
							-- retira um dado do buffer e se tem dado no buffer pede envio do mesmo
							if first = TAM_BUFFER - 1 then
								if last /= 0 then aux_data_av <= '1';
								else aux_data_av <= '0';
								end if;
								first <= (others=>'0');
							else
								if first + 1 /= last then aux_data_av <= '1';
								else aux_data_av <= '0';
								end if;
								first <= first + 1;
							end if;
						elsif counter_flit /= x"1" then
						-- confirmacao do envio de um dado que nao eh o tail
							counter_flit <= counter_flit - 1;
							-- retira um dado do buffer e se tem dado no buffer pede envio do mesmo
							if first = TAM_BUFFER - 1 then
								if last /= 0 then aux_data_av <= '1';
								else aux_data_av <= '0';
								end if;
								first <= (others=>'0');
							else
								if first + 1 /= last then aux_data_av <= '1';
								else aux_data_av <= '0';
								end if;
								first <= first + 1;
							end if;
						else -- counter_flit = x"1"
						-- confirmacao do envio do tail
							-- retira um dado do buffer
							if first = TAM_BUFFER - 1 then
								first <= (others=>'0');
							else
								first <= first + 1;
							end if;
							aux_data_av <= '0';
							sender <= '0';
							EA <= S_END;
						end if;
					elsif first = last then
						aux_data_av <= '0';
					else -- first /= last
						aux_data_av <= '1';
					end if;
					
				when S_END =>
					aux_data_av <= '0';
					EA <= S_END2;
				when S_END2 => -- estado necessario para permitir a liberacao da porta antes da solicitacao de novo envio
					aux_data_av <= '0';
					EA <= S_INIT;
			end case;
		end if;
	end process;
	
end Hermes_buffer;
