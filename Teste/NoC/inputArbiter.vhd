library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_unsigned.all;
use work.ThorPackage.all;
use work.TablePackage.all;

entity inputArbiter is
port(
    lastPort :    in	integer range 0 to (NPORT-1);
    requests :    in    regNport;
    enable :    in    std_logic;
    nextPort :    out    integer range 0 to (NPORT-1);
    ready :    out    std_logic
);
end inputArbiter;

architecture RoundRobin of inputArbiter is

begin

    process(lastPort, requests, enable)
    begin
        if(enable = '1') then
            case lastPort is
                when LOCAL=>
                    if requests(EAST)='1' then nextPort<=EAST;
                    elsif requests(WEST)='1' then nextPort<=WEST;
                    elsif requests(NORTH)='1' then nextPort<=NORTH;
                    elsif requests(SOUTH)='1' then nextPort<=SOUTH;
                    else nextPort<=LOCAL; end if;
                    ready <= '1';
                when EAST=>
                    if requests(WEST)='1' then nextPort<=WEST;
                    elsif requests(NORTH)='1' then nextPort<=NORTH;
                    elsif requests(SOUTH)='1' then nextPort<=SOUTH;
                    elsif requests(LOCAL)='1' then nextPort<=LOCAL;
                    else nextPort<=EAST; end if;
                    ready <= '1';
                when WEST=>
                    if requests(NORTH)='1' then nextPort<=NORTH;
                    elsif requests(SOUTH)='1' then nextPort<=SOUTH;
                    elsif requests(LOCAL)='1' then nextPort<=LOCAL;
                    elsif requests(EAST)='1' then nextPort<=EAST;
                    else nextPort<=WEST; end if;
                    ready <= '1';
                when NORTH=>
                    if requests(SOUTH)='1' then nextPort<=SOUTH;
                    elsif requests(LOCAL)='1' then nextPort<=LOCAL;
                    elsif requests(EAST)='1' then nextPort<=EAST;
                    elsif requests(WEST)='1' then nextPort<=WEST;
                    else nextPort<=NORTH; end if;
                    ready <= '1';
                when SOUTH=>
                    if requests(LOCAL)='1' then nextPort<=LOCAL;
                    elsif requests(EAST)='1' then nextPort<=EAST;
                    elsif requests(WEST)='1' then nextPort<=WEST;
                    elsif requests(NORTH)='1' then nextPort<=NORTH;
                    else nextPort<=SOUTH; end if;
                    ready <= '1';
            end case;
        else ready <= '0';
        end if;
    end process;

end RoundRobin;
