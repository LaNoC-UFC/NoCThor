library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.numeric_std.all;

package ThorPackage is

---------------------------------------------------------
-- INDEPENDENT CONSTANTS
---------------------------------------------------------
    constant NPORT: integer := 5;

    constant EAST  : integer := 0;
    constant WEST  : integer := 1;
    constant NORTH : integer := 2;
    constant SOUTH : integer := 3;
    constant LOCAL : integer := 4;

---------------------------------------------------------
-- CONSTANTS RELATED TO THE NETWORK BANDWIDTH
---------------------------------------------------------
    constant TAM_FLIT : integer range 1 to 64 := 16;
    constant METADEFLIT : integer range 1 to 32 := (TAM_FLIT/2);
    constant QUARTOFLIT : integer range 1 to 16 := (TAM_FLIT/4);

---------------------------------------------------------
-- CONSTANTS RELATED TO THE DEPTH OF THE QUEUE
---------------------------------------------------------
    constant TAM_BUFFER: integer := 16;
    constant TAM_POINTER : integer range 1 to 32 := 5;

---------------------------------------------------------
-- CONSTANTS RELATED TO THE NUMBER OF ROUTERS
---------------------------------------------------------
    constant NUM_X : integer := 2;
    constant NUM_Y : integer := 2;

    constant NROT: integer := NUM_X*NUM_Y;

    constant MIN_X : integer := 0;
    constant MIN_Y : integer := 0;

    constant MAX_X : integer := NUM_X-1;
    constant MAX_Y : integer := NUM_Y-1;

---------------------------------------------------------
-- NEW HARDWARE VARIABLES
---------------------------------------------------------
    type RouterControl is (invalidRegion, validRegion, faultPort, portError);

---------------------------------------------------------
-- SUBTYPES, TYPES AND FUNCTIONS
---------------------------------------------------------
    subtype reg3 is std_logic_vector(2 downto 0);
    subtype regNrot is std_logic_vector((NROT-1) downto 0);
    subtype regNport is std_logic_vector((NPORT-1) downto 0);
    subtype regflit is std_logic_vector((TAM_FLIT-1) downto 0);
    subtype regmetadeflit is std_logic_vector((METADEFLIT-1) downto 0);
    subtype regquartoflit is std_logic_vector((QUARTOFLIT-1) downto 0);

    type arrayNport_reg3 is array((NPORT-1) downto 0) of reg3;
    type arrayNport_regflit is array((NPORT-1) downto 0) of regflit;
    type arrayNrot_regflit is array((NROT-1) downto 0) of regflit;

    type arrayNrot_regNport is array((NROT-1) downto 0) of regNport;

    type matrixNrot_Nport_regflit is array((NROT-1) downto 0) of arrayNport_regflit;

---------------------------------------------------------
-- TB FUNCTIONS
---------------------------------------------------------
    function ADDRESS_FROM_INDEX(index : integer) return regflit;
    function X_COORDINATE(address: regflit) return natural;
    function Y_COORDINATE(address: regflit) return natural;
    function OR_REDUCTION(arrayN : std_logic_vector ) return boolean;

end ThorPackage;

package body ThorPackage is

    function ADDRESS_FROM_INDEX(index: integer) return regflit is
        variable addrX, addrY: regmetadeflit;
        variable addr: regflit;
    begin
        addrX := std_logic_vector(to_unsigned(index/NUM_X, METADEFLIT));
        addrY := std_logic_vector(to_unsigned(index mod NUM_Y, METADEFLIT));
        addr := addrX & addrY;
        return addr;
    end ADDRESS_FROM_INDEX;

    function X_COORDINATE(address: regflit) return natural is
    begin
        return TO_INTEGER(unsigned(address(TAM_FLIT-1 downto METADEFLIT)));
    end X_COORDINATE;

    function Y_COORDINATE(address: regflit) return natural is
    begin
        return TO_INTEGER(unsigned(address(METADEFLIT-1 downto 0)));
    end Y_COORDINATE;
    --
    -- Do a OR operation between all elements in an array
    --
    function OR_REDUCTION( arrayN: in std_logic_vector ) return boolean is
    begin
        return unsigned(arrayN) /= 0;
    end OR_REDUCTION;

end ThorPackage;
