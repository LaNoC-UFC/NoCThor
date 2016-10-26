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
    constant NUM_X : integer := 11;
    constant NUM_Y : integer := 11;

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

    function CONV_VECTOR( int: integer ) return std_logic_vector;

    type arrayNrot_regNport is array((NROT-1) downto 0) of regNport;

    type matrixNrot_Nport_regflit is array((NROT-1) downto 0) of arrayNport_regflit;
	
---------------------------------------------------------
-- TB FUNCTIONS
---------------------------------------------------------
    constant TAM_LINHA : integer := 200;
    function GET_ADDR(index : integer) return regflit;
    function OR_REDUCTION(arrayN : std_logic_vector ) return boolean;
    
end ThorPackage;

package body ThorPackage is

    --
    -- Get address from index
    --
    function GET_ADDR( index: integer) return regflit is
        variable addrX, addrY: regmetadeflit;
        variable addr: regflit;
    begin
        addrX := std_logic_vector(to_unsigned(index/NUM_X,METADEFLIT));
        addrY := std_logic_vector(to_unsigned(index mod NUM_Y, METADEFLIT)); 
        addr := addrX & addrY;
        return addr;
    end GET_ADDR;
    --
    -- Converts an integer in a std_logic_vector(2 downto 0)
    --
    function CONV_VECTOR( int: integer ) return std_logic_vector is
        variable bin: reg3;
    begin
        case(int) is
            when 0 => bin := "000";
            when 1 => bin := "001";
            when 2 => bin := "010";
            when 3 => bin := "011";
            when 4 => bin := "100";
            when 5 => bin := "101";
            when 6 => bin := "110";
            when 7 => bin := "111";
            when others => bin := "000";
        end case;
        return bin;
    end CONV_VECTOR;
    --
    -- Do a OR operation between all elements in an array
    --
    function OR_REDUCTION( arrayN: in std_logic_vector ) return boolean is
    begin
        return unsigned(arrayN) /= 0;
    end OR_REDUCTION;

end ThorPackage;
