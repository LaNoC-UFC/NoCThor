library IEEE;
use IEEE.std_logic_1164.all;
use work.NoCPackage.all;
use work.TablePackage.all;

entity RouterCC is
generic(
    address: regflit;
    ramInit: memory);
port(
    clock:     in  std_logic;
    reset:     in  std_logic;
    clock_rx:  in  regNport;
    rx:        in  regNport;
    data_in:   in  arrayNport_regflit;
    credit_o:  out regNport;
    clock_tx:  out regNport;
    tx:        out regNport;
    data_out:  out arrayNport_regflit;
    credit_i:  in  regNport);
end RouterCC;

architecture RouterCC of RouterCC is

signal h, ack_h, data_av, sender, data_ack: regNport := (others=>'0');
signal data: arrayNport_regflit := (others=>(others=>'0'));
signal mux_in, mux_out: arrayNport_reg3 := (others=>(others=>'0'));
signal free: regNport := (others=>'0');

begin

    buff : for i in EAST to LOCAL generate
        B : entity work.Thor_buffer
        port map(
            clock => clock,
            reset => reset,
            data_in => data_in(i),
            rx => rx(i),
            h => h(i),
            ack_h => ack_h(i),
            data_av => data_av(i),
            data => data(i),
            sender => sender(i),
            clock_rx => clock_rx(i),
            data_ack => data_ack(i),
            credit_o => credit_o(i));

        clock_tx(i) <= clock;
    end generate buff;

    SwitchControl : Entity work.SwitchControl
    generic map(
        address => address,
        ramInit => ramInit)
    port map(
        clock => clock,
        reset => reset,
        h => h,
        ack_h => ack_h,
        data => data,
        sender => sender,
        free => free,
        mux_in => mux_in,
        mux_out => mux_out);

    CrossBar : Entity work.Thor_crossbar
    port map(
        data_av => data_av,
        data_in => data,
        data_ack => data_ack,
        sender => sender,
        free => free,
        tab_in => mux_in,
        tab_out => mux_out,
        tx => tx,
        data_out => data_out,
        credit_i => credit_i);

end RouterCC;