----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Copyright 2017 International Business Machines
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions AND
-- limitations under the License.
--
----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- True dual port, single clocked register
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.std_ulogic_function_support.all;
USE work.std_ulogic_unsigned.all;

ENTITY mmio_register_2w2r IS
  GENERIC (
    WIDTH      : integer := 16;
    SIZE       : integer := 512;
    ADDR_WIDTH : integer := 9
  );
  PORT (
    clk        : IN  std_ulogic;
    rst        : IN  std_ulogic;

    we_a       : IN  std_ulogic;
    addr_a     : IN  std_ulogic_vector(ADDR_WIDTH - 1 DOWNTO 0);
    din_a      : IN  std_ulogic_vector(WIDTH-1 DOWNTO 0);
    dout_a     : OUT std_ulogic_vector(WIDTH-1 DOWNTO 0);

    we_b       : IN  std_ulogic;
    addr_b     : IN  std_ulogic_vector(ADDR_WIDTH - 1 DOWNTO 0);
    din_b      : IN  std_ulogic_vector(WIDTH-1 DOWNTO 0);
    dout_b     : OUT std_ulogic_vector(WIDTH-1 DOWNTO 0)
  );
END mmio_register_2w2r;

ARCHITECTURE mmio_register_2w2r OF mmio_register_2w2r IS
  TYPE mem_t IS ARRAY (SIZE-1 DOWNTO 0) OF std_ulogic_vector(WIDTH-1 DOWNTO 0);

  SIGNAL mem : mem_t;

BEGIN

  mmio_register_2w2r: PROCESS (clk)
  BEGIN  -- PROCESS mmio_register
    IF (rising_edge(clk)) THEN
      IF (rst = '1') THEN
        reset_mem: FOR i IN 0 TO SIZE-1 LOOP
          mem(i) <= (OTHERS => '0');
        END LOOP;
      ELSE
        IF (we_b = '1') THEN
          mem(to_integer(unsigned(addr_b))) <= din_b;
        END IF;
        IF (we_a = '1') THEN
          mem(to_integer(unsigned(addr_a))) <= din_a;
        END IF;
        dout_b <= mem(to_integer(unsigned(addr_b)));
        dout_a <= mem(to_integer(unsigned(addr_a)));
      END IF;
    END IF;
  END PROCESS mmio_register_2w2r;

END ARCHITECTURE;



-- Single write / dual read port, single clocked register
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.std_ulogic_function_support.all;
USE work.std_ulogic_unsigned.all;

ENTITY mmio_register_1w2r IS
  GENERIC (
    WIDTH      : integer := 16;
    SIZE       : integer := 512;
    ADDR_WIDTH : integer := 9
  );
  PORT (
    clk        : IN  std_ulogic;
    rst        : IN  std_ulogic;

    we_a       : IN  std_ulogic;
    addr_a     : IN  std_ulogic_vector(ADDR_WIDTH - 1 DOWNTO 0);
    din_a      : IN  std_ulogic_vector(WIDTH-1 DOWNTO 0);
    dout_a     : OUT std_ulogic_vector(WIDTH-1 DOWNTO 0);

    addr_b     : IN  std_ulogic_vector(ADDR_WIDTH - 1 DOWNTO 0);
    dout_b     : OUT std_ulogic_vector(WIDTH-1 DOWNTO 0)
  );
END mmio_register_1w2r;

ARCHITECTURE mmio_register_1w2r OF mmio_register_1w2r IS
  TYPE mem_t IS ARRAY (SIZE DOWNTO 0) OF std_ulogic_vector(WIDTH-1 DOWNTO 0);

  SIGNAL mem : mem_t;

BEGIN

  mmio_register_1w2r: PROCESS (clk)
  BEGIN  -- PROCESS mmio_register
    IF (rising_edge(clk)) THEN
      IF (rst = '1') THEN
        reset_mem: FOR i IN 0 TO SIZE-1 LOOP
          mem(i) <= (OTHERS => '0');
        END LOOP;
      ELSE
        IF (we_a = '1') THEN
          mem(to_integer(unsigned(addr_a))) <= din_a;
        END IF;
        dout_a <= mem(to_integer(unsigned(addr_a)));
        dout_b <= mem(to_integer(unsigned(addr_b)));
      END IF;
    END IF;
  END PROCESS mmio_register_1w2r;

END ARCHITECTURE;


-- Single port register
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.std_ulogic_function_support.all;
USE work.std_ulogic_unsigned.all;

ENTITY mmio_register_1w1r IS
  GENERIC (
    WIDTH      : integer := 16;
    SIZE       : integer := 512;
    ADDR_WIDTH : integer := 9
  );
  PORT (
    clk        : IN  std_ulogic;
    rst        : IN  std_ulogic;

    we         : IN  std_ulogic;
    addr       : IN  std_ulogic_vector(ADDR_WIDTH - 1 DOWNTO 0);
    din        : IN  std_ulogic_vector(WIDTH-1 DOWNTO 0);
    dout       : OUT std_ulogic_vector(WIDTH-1 DOWNTO 0)
  );
END mmio_register_1w1r;

ARCHITECTURE mmio_register_1w1r OF mmio_register_1w1r IS
  TYPE mem_t IS ARRAY (SIZE DOWNTO 0) OF std_ulogic_vector(WIDTH-1 DOWNTO 0);

  SIGNAL mem : mem_t;

BEGIN

  mmio_register_1w1r: PROCESS (clk)
  BEGIN  -- PROCESS mmio_register
    IF (rising_edge(clk)) THEN
      IF (rst = '1') THEN
        reset_mem: FOR i IN 0 TO SIZE-1 LOOP
          mem(i) <= (OTHERS => '0');
        END LOOP;
      ELSE
        IF (we = '1') THEN
          mem(to_integer(unsigned(addr))) <= din;
        END IF;
        dout <= mem(to_integer(unsigned(addr)));
      END IF;
    END IF;
  END PROCESS mmio_register_1w1r;

END ARCHITECTURE;
