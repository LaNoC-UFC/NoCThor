library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.HermesPackage.all;

package TablePackage is

constant NREG : integer := 3;
constant MEMORY_SIZE : integer := NREG;

type memory is array (0 to MEMORY_SIZE-1) of reg26;
type tables is array (0 to NROT-1) of memory;

constant TAB: tables :=(
 -- Router 00
(("10100000100000001000000001"),
("10001000000010001000100100"),
("00000000000000000000000000")
),
 -- Router 01
(("11000000100010001000100001"),
("10001000000000000000001000"),
("10000000100000001000001001")
),
 -- Router 10
(("10000000100010001000100100"),
("10000000000000000000000010"),
("10000000000010000000100110")
),
 -- Router 11
(("10010000100000001000001000"),
("11000000000000000000100010"),
("00000000000000000000000000")
)
);
end TablePackage;

package body TablePackage is
end TablePackage;
