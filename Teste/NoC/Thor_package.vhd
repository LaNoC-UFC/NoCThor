--------------------------------------------------------------------------
-- package com tipos basicos
--------------------------------------------------------------------------
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

package ThorPackage is

---------------------------------------------------------
-- CONSTANTS INDEPENDENTES
---------------------------------------------------------
	constant NPORT: integer := 5;

	constant EAST  : integer := 0;
	constant WEST  : integer := 1;
	constant NORTH : integer := 2;
	constant SOUTH : integer := 3;
	constant LOCAL : integer := 4;

---------------------------------------------------------
-- CONSTANTS DEPENDENTES DA LARGURA DE BANDA DA REDE
---------------------------------------------------------
	constant TAM_FLIT : integer range 1 to 64 := 16;
	constant METADEFLIT : integer range 1 to 32 := (TAM_FLIT/2);
	constant QUARTOFLIT : integer range 1 to 16 := (TAM_FLIT/4);

---------------------------------------------------------
-- CONSTANTS DEPENDENTES DA PROFUNDIDADE DA FILA
---------------------------------------------------------
	constant TAM_BUFFER: integer := 16;
	constant TAM_POINTER : integer range 1 to 32 := 5;

---------------------------------------------------------
-- CONSTANTS DEPENDENTES DO NUMERO DE ROTEADORES
---------------------------------------------------------
	constant NUM_X : integer := 11;
	constant NUM_Y : integer := 11;

	constant NROT: integer := NUM_X*NUM_Y;
	
	constant MIN_X : integer := 0;
	constant MIN_Y : integer := 0;
	
	constant MAX_X : integer := NUM_X-1;
	constant MAX_Y : integer := NUM_Y-1;

---------------------------------------------------------
-- VARIAVEIS DO NOVO HARDWARE
---------------------------------------------------------
	type RouterControl is (invalidRegion, validRegion, faultPort, portError);

---------------------------------------------------------
-- SUBTIPOS, TIPOS E FUNCOES
---------------------------------------------------------
	subtype reg3 is std_logic_vector(2 downto 0);
	subtype regNrot is std_logic_vector((NROT-1) downto 0);
	subtype regNport is std_logic_vector((NPORT-1) downto 0);
	subtype regflit is std_logic_vector((TAM_FLIT-1) downto 0);
	subtype regmetadeflit is std_logic_vector((METADEFLIT-1) downto 0);
	subtype regquartoflit is std_logic_vector((QUARTOFLIT-1) downto 0);
	subtype pointer is std_logic_vector((TAM_POINTER-1) downto 0);

	type buff is array(0 to TAM_BUFFER-1) of regflit;

	type arrayNport_reg3 is array((NPORT-1) downto 0) of reg3;
	type arrayNport_regflit is array((NPORT-1) downto 0) of regflit;
	type arrayNrot_regflit is array((NROT-1) downto 0) of regflit;

	function CONV_VECTOR( int: integer ) return std_logic_vector;

	type arrayNrot_regNport is array((NROT-1) downto 0) of regNport; -- a -- array (NROT)(NPORT)

	type matrixNrot_Nport_regflit is array((NROT-1) downto 0) of arrayNport_regflit; -- a -- array(NROT)(NPORT)(TAM_FLIT)

---------------------------------------------------------
-- FUNCOES TB
---------------------------------------------------------
	constant TAM_LINHA : integer := 200;
	function GET_ADDR(index : integer) return regflit;

end ThorPackage;

package body ThorPackage is

	--
	-- dado o index do roteador retorna o endereço correspondente
	--
	function GET_ADDR( index: integer) return regflit is
		variable addrX, addrY: regmetadeflit;
		variable addr: regflit;
	begin
		addrX := CONV_STD_LOGIC_VECTOR(index/NUM_X,METADEFLIT);
		addrY := CONV_STD_LOGIC_VECTOR(index mod NUM_Y, METADEFLIT); 
		addr := addrX & addrY;
		return addr;
	end GET_ADDR;
	--
	-- converte um inteiro em um std_logic_vector(2 downto 0)
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

end ThorPackage;