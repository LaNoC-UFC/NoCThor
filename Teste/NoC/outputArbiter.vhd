library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity outputArbiter is   
    generic(    
        size : natural 
    );
    port(
        requests :              in std_logic_vector(size-1 downto 0);
        enable :                in std_logic;
        isOutputSelected :      out std_logic;
        selectedOutput :        out integer
    );
end;

architecture outputArbiter of outputArbiter is
begin
    
    process(requests, enable)
        variable auxDone : std_logic;
        variable auxSelected : integer;
    begin
        auxDone := '0';
        auxSelected := 0;
        if(enable = '1') then
            for i in requests'low to requests'high loop
                if requests(i) = '1' then
                    auxSelected := i;
                    auxDone := '1';
                    exit;
                end if;
            end loop;
        end if; 
        isOutputSelected <= auxDone;
        selectedOutput <= auxSelected;              
    end process;

end outputArbiter;
