library ieee;
use ieee.std_logic_1164.all;

entity RCAdd is 
    port (
        A, B: in std_logic_vector (7 downto 0);
        Result: out std_logic_vector (7 downto 0)
    );
end RCAdd;

architecture behavioral of RCAdd is
begin
    RippleCarryAdder:
    process (A, B)
    variable localCarry: std_logic_vector (8 downto 0);
    begin 
        localCarry(0) := '0';
        for i in 0 to 7 loop
            Result(i) <= A(i) XOR B(i) XOR localCarry(i);
            localCarry(i + 1) := (A(i) AND B(i)) OR (localCarry(i) AND (A(i) OR B(i)));
        end loop;
    end process;
end behavioral;