library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ThorPackage.all;
use work.TablePackage.all;

entity routingMechanism is
    generic(ramInit : memory := (others=>(others=>'0')));
    port(
        clock :   in  std_logic;
        reset :   in  std_logic;
        oe :   in  std_logic;
        dst_address : in regflit;
        inputPort : in integer range 0 to (NPORT-1);
        outputPort : out regNPort;
        find : out RouterControl
    );
end routingMechanism;

architecture behavior of routingMechanism is

    signal data : regNPort := (others=>'0');
    signal dst_x, dst_y : integer;
    type row is array ((NREG-1) downto 0) of integer;
    signal bottom_left_x, bottom_left_y, top_right_x, top_right_y : row;
    signal H : std_logic_vector((NREG-1) downto 0);
    type arrayIP is array ((NREG-1) downto 0) of std_logic_vector(4 downto 0);
    signal IP : arrayIP;
    signal RAM: memory := ramInit;

begin

    dst_x <= X_COORDINATE(dst_address) when oe = '1' else 0;
    dst_y <= Y_COORDINATE(dst_address) when oe = '1' else 0;

    cond: for j in 0 to (NREG - 1) generate

        IP(j) <= RAM(j)(CELL_SIZE-1 downto CELL_SIZE-5) when oe = '1' else (others=>'0');
        bottom_left_x(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6 downto CELL_SIZE-5-NBITS))) when oe = '1' else 0;
        bottom_left_y(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-NBITS downto CELL_SIZE-5-2*NBITS))) when oe = '1' else 0;
        top_right_x(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-2*NBITS downto CELL_SIZE-5-3*NBITS))) when oe = '1' else 0;
        top_right_y(j) <= TO_INTEGER(unsigned(RAM(j)(CELL_SIZE-6-3*NBITS downto 5))) when oe = '1' else 0;

        H(j) <= '1' when dst_x >= bottom_left_x(j) and dst_x <= top_right_x(j) and
                          dst_y >= bottom_left_y(j) and dst_y <= top_right_y(j) and
                          IP(j)(inputPort) = '1' and oe = '1' else
              '0';

    end generate;

    process(RAM, H, oe)
    begin
        data <= (others=>'Z');
        find <= invalidRegion;
        if oe = '1' then
            for i in 0 to (NREG-1) loop
                if H(i) = '1' then
                    data <= RAM(i)(NPORT-1 downto 0);
                    find <= validRegion;
                    exit;
                end if;
            end loop;
        end if;
    end process;

    outputPort <= data;

end behavior;

