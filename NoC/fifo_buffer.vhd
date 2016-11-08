library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity fifoBuffer is
    generic(
        B_DEPTH : positive;
        B_WIDTH : positive
    );
    port(
        reset :     in std_logic;
        clock :     in std_logic;
        head:       out std_logic_vector(B_WIDTH-1 downto 0);
        tail :      in std_logic_vector(B_WIDTH-1 downto 0);
        push :      in std_logic;
        pull :      in std_logic;
        counter :   out natural
    );
end;

architecture circularFifoBuffer of FifoBuffer is

    type buff is array(0 to B_DEPTH - 1) of std_logic_vector(B_WIDTH-1 downto 0);
    subtype pointer is natural range 0 to B_DEPTH - 1;

    signal buf: buff := (others=>(others=>'0'));
    signal isFull : boolean;
    signal first: pointer;
    signal last: pointer;

    procedure increment_pointer(p: inout pointer) is
    begin
        if p = B_DEPTH - 1 then
            p := 0;
        else
            p := p + 1;
        end if;
    end increment_pointer;

begin

    head <= buf(first);
    counter <=   B_DEPTH when isFull else
                    last - first when (last >= first) else
                    B_DEPTH - (first - last);

    process(reset, clock)
        variable aux_first, aux_last: pointer;
        variable aux_is_full, is_empty : boolean;
    begin
        if reset = '1' then
            last <= 0;
            first <= 0;
            isFull <= false;
            is_empty := true;
            aux_is_full := false;
            aux_last := 0;
            aux_first := 0;
        elsif rising_edge(clock) then
            -- remove data
            if not is_empty and pull = '1' then
                increment_pointer(aux_first);
                aux_is_full := false;
                is_empty := (aux_first = aux_last);
            end if;
            -- append data
            if not aux_is_full and push = '1' then
                buf(aux_last) <= tail;
                increment_pointer(aux_last);
                is_empty := false;
                aux_is_full := (aux_last = aux_first);
            end if;
            isFull <= aux_is_full;
            last <= aux_last;
            first <= aux_first;
        end if;
    end process;

end circularFifoBuffer;
