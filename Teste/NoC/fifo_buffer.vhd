library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.ThorPackage.all;
use ieee.numeric_std.all;

entity fifoBuffer is
port(
    reset :     in std_logic;
    clock :     in std_logic;
    head:       out regflit;
    tail :      in regflit;
    push :      in std_logic;
    pull :      in std_logic;
    counter :   out integer
);
end;

architecture circularFifoBuffer of FifoBuffer is

    type buff is array(0 to TAM_BUFFER) of regflit;
    signal buf: buff := (others=>(others=>'0'));

    signal isFull, isEmpty : boolean;
    signal first: integer := 0;
    signal last: integer := 0;
    signal auxCounter: integer;

begin

    counter <= auxCounter;
    head <= buf(first);
    auxCounter <= last - first when (last >= first) else TAM_BUFFER + 1 - (first - last);
    isFull <= auxCounter = TAM_BUFFER;
    isEmpty <= auxCounter = 0;

    process(reset, clock)
    begin
        if reset = '1' then
            last <= 0;
        elsif clock'event and clock = '1' then
            if not isFull and push = '1' then
                buf(last) <= tail;
                if last = TAM_BUFFER then
                    last <= 0;
                else last <= last + 1;
                end if;
            end if;
        end if;
    end process;

    process (reset, clock)
    begin
        if reset = '1' then
            first <= 0;
        elsif clock'event and clock = '1' then
            if not isEmpty and pull = '1' then
                if first = TAM_BUFFER then
                    first <= 0;
                else
                    first <= first + 1;
                end if;
            end if;
        end if;
    end process;

end circularFifoBuffer;
