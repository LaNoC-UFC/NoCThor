library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_unsigned.all;

entity inputArbiter is
    generic(
        size : natural
    );
    port(
        requests :              in std_logic_vector(size-1 downto 0);
        enable :                in std_logic;
        nextPort :              out integer range 0 to (size-1);
        ready :                 out std_logic
    );
end inputArbiter;

architecture RoundRobin of inputArbiter is

    signal lastPort : integer range 0 to (size-1) := 0;

begin

    process(enable)
        variable designedPort : integer range 0 to (size-1);
        variable requestCheck : integer range 0 to (size-1);
    begin        
        if rising_edge(enable) then
            requestCheck := lastPort;
            designedPort := lastPort;
            for i in requests'low to requests'high loop
                if(requestCheck = size-1) then
                    requestCheck := 0;
                else
                    requestCheck := requestCheck + 1;
                end if;

                if(requests(requestCheck) = '1') then
                    designedPort := requestCheck;
                    exit;
                end if;
            end loop;
            lastPort <= designedPort;
            nextPort <= designedPort;
        end if;
    end process;

    ready <= enable;

end RoundRobin;
