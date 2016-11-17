library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_unsigned.all;
use work.NoCPackage.all;
use work.TablePackage.all;

entity inputArbiter is
port(
    requests : in regNport;
    enable : in std_logic;
    nextPort : out integer range 0 to (NPORT-1);
    ready : out std_logic
);
end inputArbiter;

architecture RoundRobin of inputArbiter is

    signal lastPort : integer range 0 to (NPORT-1) := EAST;

begin

    process(enable)
        variable designedPort : integer range 0 to (NPORT-1);
        variable requestCheck : integer range 0 to (NPORT-1);
    begin        
        if rising_edge(enable) then
            requestCheck := lastPort;
            designedPort := lastPort;
            for i in 0 to NPORT-1 loop
                if(requestCheck = NPORT-1) then
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
