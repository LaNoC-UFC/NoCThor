library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NoCPackage.all;

package TablePackage is

constant NREG : integer := 2;
constant MEMORY_SIZE : integer := NREG;
constant NBITS : integer := 1;
constant CELL_SIZE : integer := 2*NPORT+4*NBITS;

subtype cell is std_logic_vector(CELL_SIZE-1 downto 0);
subtype regAddr is std_logic_vector(2*NBITS-1 downto 0);
type memory is array (0 to MEMORY_SIZE-1) of cell;
type tables is array (0 to NROT-1) of memory;
subtype ports is std_logic_vector(NPORT-1 downto 0);

function input_ports(region : cell) return ports;
function output_ports(region : cell) return ports;
function upper_right_x(region : cell) return natural;
function upper_right_y(region : cell) return natural;
function lower_left_x(region : cell) return natural;
function lower_left_y(region : cell) return natural;

constant TAB: tables :=(
 -- Router 0.0
(("10001010100100"),
("10100101100001")
),
 -- Router 0.1
(("10001001001000"),
("11000111100001")
),
 -- Router 1.0
(("10100000100010"),
("10010111100100")
),
 -- Router 1.1
(("10000010100010"),
("10000001001000")
)
);
end TablePackage;

package body TablePackage is

function input_ports(region : cell) return ports is
    variable result : std_logic_vector(NPORT-1 downto 0);
begin
    result := region(CELL_SIZE-1 downto CELL_SIZE-5);
    return result;
end input_ports;

function output_ports(region : cell) return ports is
begin
    return region(NPORT-1 downto 0);
end output_ports;

function upper_right_x(region : cell) return natural is
begin
    return TO_INTEGER(unsigned(region(CELL_SIZE-6-2*NBITS downto CELL_SIZE-5-3*NBITS)));
end upper_right_x;

function upper_right_y(region : cell) return natural is
begin
    return TO_INTEGER(unsigned(region(CELL_SIZE-6-3*NBITS downto 5)));
end upper_right_y;

function lower_left_x(region : cell) return natural is
begin
    return TO_INTEGER(unsigned(region(CELL_SIZE-6 downto CELL_SIZE-5-NBITS)));
end lower_left_x;

function lower_left_y(region : cell) return natural is
begin
    return TO_INTEGER(unsigned(region(CELL_SIZE-6-NBITS downto CELL_SIZE-5-2*NBITS)));
end lower_left_y;

end TablePackage;
