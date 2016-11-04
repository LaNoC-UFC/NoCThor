library IEEE;
use IEEE.std_logic_1164.all;
use work.NoCPackage.all;
use work.TablePackage.all;

entity NOC is
port(
    clock         : in  regNrot;
    reset         : in  std_logic;
    clock_rxLocal : in  regNrot;
    rxLocal       : in  regNrot;
    data_inLocal  : in  arrayNrot_regflit;
    credit_oLocal : out regNrot;
    clock_txLocal : out regNrot;
    txLocal       : out regNrot;
    data_outLocal : out arrayNrot_regflit;
    credit_iLocal : in  regNrot);
end NOC;

architecture NOC of NOC is

    signal rx, clock_rx, credit_i, tx, clock_tx, credit_o, testLink_i, testLink_o : arrayNrot_regNport;
    signal data_in, data_out : matrixNrot_Nport_regflit;

begin

    Router: FOR i IN 0 TO (NROT-1) GENERATE
        n : Entity work.RouterCC
        generic map
        (
            address => ADDRESS_FROM_INDEX(i),
            ramInit => TAB(i)
        )
        port map
        (
            clock         => clock(i),
            reset         => reset,

            clock_rx    => clock_rx(i),
            rx             => rx(i),
            data_in     => data_in(i),
            credit_o     => credit_o(i),
            clock_tx     => clock_tx(i),

            tx             => tx(i),
            data_out     => data_out(i),
            credit_i     => credit_i(i)
        );
    END GENERATE Router;

    internal_ports: FOR i IN 0 TO (NROT-1) GENERATE

        east: if i < NUM_Y*MAX_X GENERATE
        clock_rx(i)(0)         <= clock_tx(i+NUM_Y)(1);
        rx(i)(0)             <= tx(i+NUM_Y)(1);
        data_in(i)(0)         <= data_out(i+NUM_Y)(1);
        credit_i(i)(0)         <= credit_o(i+NUM_Y)(1);
        end GENERATE;

        west: if i >= NUM_Y GENERATE
        clock_rx(i)(1)        <= clock_tx(i-NUM_Y)(0);
        rx(i)(1)            <= tx(i-NUM_Y)(0);
        data_in(i)(1)        <= data_out(i-NUM_Y)(0);
        credit_i(i)(1)        <= credit_o(i-NUM_Y)(0);
        end GENERATE;

        north: if (i-(i/NUM_Y)*NUM_Y) < MAX_Y GENERATE
        clock_rx(i)(2)         <= clock_tx(i+1)(3);
        rx(i)(2)            <= tx(i+1)(3);
        data_in(i)(2)        <= data_out(i+1)(3);
        credit_i(i)(2)        <= credit_o(i+1)(3);
        end GENERATE;

        south: if (i-(i/NUM_Y)*NUM_Y) > MIN_Y GENERATE
        clock_rx(i)(3) <= clock_tx(i-1)(2);
        rx(i)(3)<=tx(i-1)(2);
        data_in(i)(3)<=data_out(i-1)(2);
        credit_i(i)(3)<=credit_o(i-1)(2);
        end GENERATE;
    END GENERATE;


    local_port : FOR i IN 0 TO (NROT-1) GENERATE

        clock_rx(i)(LOCAL)<= clock_rxLocal(i);
        data_in(i)(LOCAL)<=data_inLocal(i);
        credit_i(i)(LOCAL)<=credit_iLocal(i);
        rx(i)(LOCAL)<=rxLocal(i);

        clock_txLocal(i)<= clock_tx(i)(LOCAL);
        data_outLocal(i)<=data_out(i)(LOCAL);
        credit_oLocal(i)<=credit_o(i)(LOCAL);
        txLocal(i)<=tx(i)(LOCAL);
    END GENERATE;

end NOC;
