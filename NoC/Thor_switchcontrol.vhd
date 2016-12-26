library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.NoCPackage.all;
use work.TablePackage.all;

entity SwitchControl is
generic(
    address : regflit := (others=>'0');
    ramInit : memory);
port(
    clock :   in  std_logic;
    reset :   in  std_logic;
    h :       in  regNport;
    ack_h :   out regNport;
    data :    in  arrayNport_regflit;
    sender :  in  regNport;
    free :    out regNport;
    mux_in :  out arrayNport_reg3;
    mux_out : out arrayNport_reg3);
end SwitchControl;

architecture RoutingTable of SwitchControl is

    type state is (S0,S1,S2,S3,S4,S5);
    signal ES, PES: state;
    signal ask: std_logic := '0';
    signal sel,prox: integer range 0 to (NPORT-1) := 0;
    signal incoming: reg3 := (others=> '0');
    signal header : regflit := (others=> '0');
    signal ready, enable : std_logic;

    signal indice_dir: integer range 0 to (NPORT-1) := 0;
    signal auxfree: regNport := (others=> '0');
    signal source:  arrayNport_reg3 := (others=> (others=> '0'));
    signal sender_ant: regNport := (others=> '0');
    signal dir: regNport:= (others=> '0');
    signal requests: regNport := (others=> '0');
    signal find: RouterControl;
    signal ceTable: std_logic := '0';
    signal selectedOutput : integer := 0;
    signal isOutputSelected : std_logic;

begin
    ask <= '1' when OR_REDUCTION(h) else '0';
    incoming <= std_logic_vector(to_unsigned(sel, incoming'length));
    header <= data(TO_INTEGER(unsigned(incoming)));

    RoundRobinArbiter : entity work.arbiter(RoundRobinArbiter)
    generic map(size => requests'length)
    port map(
        requests => h,
        enable => enable,
        selectedOutput => prox,
        isOutputSelected => ready
    );

    RoutingMechanism : entity work.routingMechanism
    generic map(
        ramInit => ramInit,
        LOCAL_ADDRESS => address
    )
    port map(
       clock => clock,
       reset => reset,
       oe => ceTable,
       dst_address => header,
       inputPort => sel,
       outputPort => dir,
       find => find
    );

    FixedPriorityArbiter : entity work.arbiter(FixedPriorityArbiter)
    generic map(size => requests'length)
    port map(
        requests                => requests,
        enable                  => '1',
        isOutputSelected        => isOutputSelected,
        selectedOutput          => selectedOutput
    );

    process(reset,clock)
    begin
        if reset='1' then
            ES<=S0;
        elsif rising_edge(clock) then
            ES<=PES;
        end if;
    end process;

    process(ES, ask, find, isOutputSelected)
    begin
        case ES is
            when S0 => PES <= S1;
            when S1 =>
                if ask='1' then
                    PES <= S2;
                else
                    PES <= S1;
                end if;
            when S2 => PES <= S3;
            when S3 =>
                if(find = validRegion) then
                    if (isOutputSelected = '1') then
                        PES <= S4;
                    else
                        PES <= S1;
                    end if;
                elsif(find = portError) then
                    PES <= S1;
                else
                    PES <= S3;
                end if;
            when S4 => PES <= S5;
            when S5 => PES <= S1;
        end case;
    end process;

    process(clock)
    begin
        if rising_edge(clock) then
            case ES is
                when S0 =>
                    ceTable <= '0';
                    sel <= 0;
                    ack_h <= (others => '0');
                    auxfree <= (others=> '1');
                    sender_ant <= (others=> '0');
                    mux_out <= (others=>(others=>'0'));
                    source <= (others=>(others=>'0'));
                when S1=>
                    enable <= ask;
                    ceTable <= '0';
                    ack_h <= (others => '0');
                when S2=>
                    sel <= prox;
                    enable <= not ready;
                when S3 =>
                    if(find = validRegion and isOutputSelected = '1') then
                        indice_dir <= selectedOutput;
                    else
                        ceTable <= '1';
                    end if;
                when S4 =>
                    source(TO_INTEGER(unsigned(incoming))) <= std_logic_vector(to_unsigned(indice_dir, incoming'length));
                    mux_out(indice_dir) <= incoming;
                    auxfree(indice_dir) <= '0';
                    ack_h(sel)<='1';
                when others =>
                    ack_h(sel)<='0';
                    ceTable <= '0';
            end case;

            sender_ant <= sender;

            for i in EAST to LOCAL loop
                if sender(i)='0' and  sender_ant(i)='1' then
                    auxfree(TO_INTEGER(unsigned(source(i)))) <= '1';
                end if;
            end loop;

        end if;
    end process;

    mux_in <= source;
    free <= auxfree;
    requests <= auxfree AND dir;

end RoutingTable;
