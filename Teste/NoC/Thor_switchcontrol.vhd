library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.ThorPackage.all;
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
    incoming <= CONV_VECTOR(sel);
    header <= data(TO_INTEGER(unsigned(incoming)));

    process(sel, h)
    begin
        case sel is
            when LOCAL=>
                if h(EAST)='1' then prox<=EAST;
                elsif h(WEST)='1' then prox<=WEST;
                elsif h(NORTH)='1' then prox<=NORTH;
                elsif h(SOUTH)='1' then prox<=SOUTH;
                else prox<=LOCAL; end if;
            when EAST=>
                if h(WEST)='1' then prox<=WEST;
                elsif h(NORTH)='1' then prox<=NORTH;
                elsif h(SOUTH)='1' then prox<=SOUTH;
                elsif h(LOCAL)='1' then prox<=LOCAL;
                else prox<=EAST; end if;
            when WEST=>
                if h(NORTH)='1' then prox<=NORTH;
                elsif h(SOUTH)='1' then prox<=SOUTH;
                elsif h(LOCAL)='1' then prox<=LOCAL;
                elsif h(EAST)='1' then prox<=EAST;
                else prox<=WEST; end if;
            when NORTH=>
                if h(SOUTH)='1' then prox<=SOUTH;
                elsif h(LOCAL)='1' then prox<=LOCAL;
                elsif h(EAST)='1' then prox<=EAST;
                elsif h(WEST)='1' then prox<=WEST;
                else prox<=NORTH; end if;
            when SOUTH=>
                if h(LOCAL)='1' then prox<=LOCAL;
                elsif h(EAST)='1' then prox<=EAST;
                elsif h(WEST)='1' then prox<=WEST;
                elsif h(NORTH)='1' then prox<=NORTH;
                else prox<=SOUTH; end if;
        end case;
    end process;

    RoutingMechanism : entity work.routingMechanism
    generic map(ramInit => ramInit)
    port map(
       clock => clock,
       reset => reset,
       oe => ceTable,
       dest => header,
       inputPort => sel,
       outputPort => dir,
       find => find
    );
    
    OutputArbiter : entity work.outputArbiter
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
        elsif clock'event and clock='0' then
            ES<=PES;
        end if;
    end process;

    process(ES, ask, auxfree, find, selectedOutput, isOutputSelected, header)
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
                if address = header and auxfree(LOCAL) = '1' then
                    indice_dir <= LOCAL;
                    PES <= S4;
                elsif(find = validRegion) then
                    if (isOutputSelected = '1') then
                        indice_dir <= selectedOutput;
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
        if clock'event and clock='1' then
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
                    ceTable <= '0';
                    ack_h <= (others => '0');
                when S2=>
                    sel <= prox;
                when S3 =>
                    if address /= header then
                        ceTable <= '1';
                    end if;
                when S4 =>
                    source(TO_INTEGER(unsigned(incoming))) <= CONV_VECTOR(indice_dir);
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
