library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.ThorPackage.all;

entity Thor_buffer is
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
end Thor_buffer;

architecture Thor_buffer of Thor_buffer is

type fila_out is (S_INIT, S_PAYLOAD, S_SENDHEADER, S_HEADER, S_END, S_END2);
signal EA : fila_out;

signal counter_flit: integer;
signal aux_data_av: std_logic;
signal pull: std_Logic;
signal bufferHead : regflit;
signal isLast : std_logic;
signal isEmpty: boolean;
signal isFull: boolean;
signal counter : integer;
begin

    circularFifoBuffer : entity work.FifoBuffer
    generic map(B_DEPTH => TAM_BUFFER ,
                B_WIDTH => regflit'length)
    port map(
        reset =>     reset,
        clock =>     clock_rx,
        tail =>      data_in,
        push =>      rx,
        pull =>      pull,
        counter =>   counter,
        head =>      bufferHead
    );

    data <= bufferHead;
    data_av <= aux_data_av;
    isEmpty <= counter = 0;
    isFull <= counter = TAM_BUFFER;
    credit_o <= '1' when (not isFull) else '0';
    isLast <= '1' when (counter = 1) else '0';

    process(reset, clock)
    begin
        if reset = '1' then
            counter_flit <= 0;
            h <= '0';
            aux_data_av <= '0';
            pull <= '0';
            sender <=  '0';
            EA <= S_INIT;
        elsif clock'event and clock = '1' then
            case EA is
                when S_INIT =>
                    counter_flit <= 0;
                    aux_data_av <= '0';
                    if not isEmpty then
                        h <= '1';
                        EA <= S_HEADER;
                    else
                        h <= '0';
                    end if;
                when S_HEADER =>
                    if ack_h = '1' then
                        EA <= S_SENDHEADER;
                        h <= '0';
                        aux_data_av <= '1';
                        sender <= '1';
                    end if;
                when S_SENDHEADER  =>
                    if data_ack = '1' and aux_data_av = '1' then
                        EA <= S_PAYLOAD;
                        aux_data_av <= not isLast;
                        pull <= '1';
                    else
                        pull <= '0';
                    end if;
                when S_PAYLOAD =>
                    if data_ack = '1' and aux_data_av = '1' then
                        if counter_flit = 0 then
                            counter_flit <=  to_integer(unsigned(bufferHead));
                            aux_data_av <= not isLast;
                            pull <= '1';
                        elsif counter_flit /= 1 then
                            counter_flit <= counter_flit - 1;
                            aux_data_av <= not isLast;
                            pull <= '1';
                        else
                            aux_data_av <= '0';
                            pull <= '1';
                            sender <= '0';
                            EA <= S_END;
                        end if;
                    elsif isEmpty then
                        aux_data_av <= '0';
                        pull <= '0';
                    else
                        aux_data_av <= '1';
                        pull <= '0';
                    end if;
                when S_END =>
                    pull <= '0';
                    aux_data_av <= '0';
                    EA <= S_END2;
                when S_END2 =>
                    pull <= '0';
                    aux_data_av <= '0';
                    EA <= S_INIT;
            end case;
        end if;
    end process;

end Thor_buffer;
