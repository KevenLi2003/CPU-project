LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- Entity declaration only. No definition here
ENTITY RCAdd_tb IS
END ENTITY RCAdd_tb;

-- Architecture of the testbench with the signal names
ARCHITECTURE RCAdd_tb_arch OF RCAdd_tb IS
    SIGNAL A_tb      : std_logic_vector(7 DOWNTO 0);
    SIGNAL B_tb      : std_logic_vector(7 DOWNTO 0);
    SIGNAL Result_tb : std_logic_vector(7 DOWNTO 0);

    -- Component instantiation of the Design Under Test (DUT)
    COMPONENT RCAdd
        PORT (
            A      : IN  std_logic_vector(7 DOWNTO 0);
            B      : IN  std_logic_vector(7 DOWNTO 0);
            Result : OUT std_logic_vector(7 DOWNTO 0)
        );
    END COMPONENT RCAdd;
BEGIN
    DUT: RCAdd
        -- Port mapping: between the DUT and the testbench signals
        PORT MAP (
            A      => A_tb,
            B      => B_tb,
            Result => Result_tb
        );

    -- Add test logic here
    sim_process: PROCESS
    BEGIN
        WAIT FOR 0 ns;
        A_tb <= b"0000_0000";
        B_tb <= b"0000_0000";
        WAIT FOR 20 ns;
        A_tb <= b"0010_1010"; -- decimal 42
        B_tb <= b"0011_1010"; -- decimal 58
        WAIT FOR 200 ns;
        A_tb <= b"01101001"; -- decimal 105
        B_tb <= b"00010101"; -- decimal 21
        WAIT;
    END PROCESS sim_process;
END ARCHITECTURE RCAdd_tb_arch;