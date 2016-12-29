library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NoCPackage.all;
use work.TablePackage.all;

entity routingMechanism is
    generic(
        LOCAL_ADDRESS : regflit;
        ramInit : memory := (others=>(others=>'0')));
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

    signal dst_x, dst_y : integer;
    type row is array ((NREG-1) downto 0) of integer;
    signal bottom_left_x, bottom_left_y, top_right_x, top_right_y : row;
    signal H : std_logic_vector((NREG-1) downto 0);
    type arrayIP is array ((NREG-1) downto 0) of ports;
    signal IP : arrayIP;
    signal RAM: memory := ramInit;

begin

    dst_x <= X_COORDINATE(dst_address) when oe = '1' else 0;
    dst_y <= Y_COORDINATE(dst_address) when oe = '1' else 0;

    cond: for j in 0 to (NREG - 1) generate

        IP(j) <= input_ports(RAM(j)) when oe = '1' else (others=>'0');
        bottom_left_x(j) <= lower_left_x(RAM(j)) when oe = '1' else 0;
        bottom_left_y(j) <= lower_left_y(RAM(j)) when oe = '1' else 0;
        top_right_x(j) <= upper_right_x(RAM(j)) when oe = '1' else 0;
        top_right_y(j) <= upper_right_y(RAM(j)) when oe = '1' else 0;

        H(j) <= '1' when dst_x >= bottom_left_x(j) and dst_x <= top_right_x(j) and
                          dst_y >= bottom_left_y(j) and dst_y <= top_right_y(j) and
                          IP(j)(inputPort) = '1' and oe = '1' else
              '0';

    end generate;

    process(RAM, H, oe, dst_address)
        variable data : regNPort;
    begin
        data := (others=>'0');
        find <= invalidRegion;
        if oe = '1' then
            if LOCAL_ADDRESS = dst_address then
                data := (LOCAL=>'1', others=>'0');
                find <= validRegion;
            else
                for i in 0 to (NREG-1) loop
                    if H(i) = '1' then
                        data := data or output_ports(RAM(i));
                        find <= validRegion;
                        exit;
                    end if;
                end loop;
            end if;
        end if;
        outputPort <= data;
    end process;

end behavior;

architecture DOR_XY of routingMechanism is
    signal local_x: natural;
    signal dest_x: natural;
    signal local_y: natural;
    signal dest_y: natural;
begin
    local_x <= X_COORDINATE(LOCAL_ADDRESS);
    local_y <= Y_COORDINATE(LOCAL_ADDRESS);
    dest_x <= X_COORDINATE(dst_address);
    dest_y <= Y_COORDINATE(dst_address);

    find <= validRegion;

    process(local_x, dest_x, local_y, dest_y)
    begin
        outputPort <= (others => '0');
        if dest_x > local_x then
            outputPort(EAST) <='1';
        elsif dest_x < local_x then
            outputPort(WEST) <= '1';
        elsif dest_y < local_y then
            outputPort(SOUTH) <= '1';
        elsif dest_y > local_y then
            outputPort(NORTH) <= '1';
        else
            outputPort(LOCAL) <= '1';
        end if;
    end process;

end architecture DOR_XY;
