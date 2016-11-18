library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_buffer_test is
end;

architecture fifo_buffer_test of fifo_buffer_test is

    constant CLOCK_PERIOD : time := 20 ns;
    constant BUFFER_DEPTH : positive := 10;
    constant BUFFER_WIDTH : positive := 13;

    signal clock:          std_logic := '0';
    signal reset:          std_logic;
    signal head, tail : std_logic_vector(BUFFER_WIDTH-1 downto 0);
    signal push, pull : std_logic;
    signal counter : natural;

    procedure wait_clock_tick is
    begin
        wait until rising_edge(clock);
        wait until counter'stable;
        wait until head'stable;
    end wait_clock_tick;

begin
    reset <= '1', '0' after CLOCK_PERIOD/4;
    clock <= not clock after CLOCK_PERIOD/2;

    UUT : entity work.fifo_buffer
    generic map(
        BUFFER_DEPTH => BUFFER_DEPTH,
        BUFFER_WIDTH => BUFFER_WIDTH)
    port map(
        reset => reset,
        clock => clock,
        head => head,
        tail => tail,
        push => push,
        pull => pull,
        counter => counter
    );

    process
    begin
        push <= '0';
        pull <= '0';
        tail <= (others=>'0');
        wait until reset = '0';
        assert counter = 0 report "Buffer should be empty after reset" severity failure;
        wait_clock_tick;
        -- fill it completely
        push <= '1';
        for i in 1 to BUFFER_DEPTH loop
            tail <= std_logic_vector(to_unsigned(i, tail'length));
            wait_clock_tick;
            assert counter = i report "Buffer should have " & integer'image(i) & " element(s)" severity failure;
        end loop;
        -- try to force one more
        wait_clock_tick;
        assert counter = BUFFER_DEPTH report "Buffer shouldnt pass its size" severity failure;
        -- push and pull at the same time
        pull <= '1';
        for i in 1 to BUFFER_DEPTH loop
            assert head = std_logic_vector(to_unsigned(i, head'length)) report "Values not equal when pushing/pulling" severity failure;
            tail <= std_logic_vector(to_unsigned(i, tail'length));
            wait_clock_tick;
            assert counter = BUFFER_DEPTH report "Buffer counter should remain constant when pushing/pulling" severity failure;
        end loop;
        -- empty it completely
        push <= '0';
        for i in 1 to BUFFER_DEPTH loop
            assert head = std_logic_vector(to_unsigned(i, head'length)) report "Values not equal when emptying" severity failure;
            wait_clock_tick;
            assert counter = (BUFFER_DEPTH  - i) report "Buffer should have " & integer'image(BUFFER_DEPTH  - i) & " element(s)" severity failure;
        end loop;

        wait;
    end process;

end fifo_buffer_test;
