----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Student: Sironi Alessandro
-- Professor: Gianluca Palermo
--
-- Project Name: Prova Finale - Progetto di Reti Logiche
--
-- Description: La specifica della Prova Finale (Progetto di Reti Logiche) 2021-2022 è ispirata alle codifiche convoluzionali.
--              Nel progetto si vuole sviluppare un codice convoluzionale 1/2 , cioè un codice in cui per ogni bit in ingresso ne vengono generati 2 in uscita.
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;


architecture Behavioral of project_reti_logiche is
    -- FSM
    type STATUS is (S00, S01, S10, S11);
    signal PS, NS                   : status; -- Present State and Next State of FSM

    signal current_bit              : std_logic := 'X'; -- Bit currently used by FSM
    signal current_word             : std_logic_vector (7 downto 0) := "XXXXXXXX"; -- Word currently used by FSM.
    signal vec_idx                  : integer := 0; -- Vector Index.

    signal step                     : integer := 0;

    signal num_of_words             : integer := -1;
    signal num_of_words_computed    : integer := 0;

    signal mem_address_read         : std_logic_vector(15 downto 0) := "0000000000000000";
    signal mem_address_write        : std_logic_vector(15 downto 0);

    signal p1k                      : std_logic_vector(7 downto 0) := "XXXXXXXX";
    signal p2k                      : std_logic_vector(7 downto 0) := "XXXXXXXX";

    signal done                     : std_logic := '0';


begin
    FSM_PROC : process (i_clk, i_rst)
    begin
        if (i_rst = '1') then
            NS <= S00;
            vec_idx <= 0;
            step <= 0;
            o_done <= '0';
            done <= '0';
        else
            if (rising_edge(i_clk)) then
                if (i_start = '1') then
                    case step is
                        when -1 =>

                        when 0 =>
                            o_en <= '1';
                            o_we <= '0';
                            NS <= S00;
                            vec_idx <= 0;
                            mem_address_read <= "0000000000000000";
                            mem_address_write <= std_logic_vector(to_unsigned(1000,16));
                            o_address <= mem_address_read;
                            num_of_words_computed <= 0;

                        when 1 =>
                            mem_address_read <= std_logic_vector(unsigned(mem_address_read)+1);

                        when 2 =>
                            num_of_words <= to_integer(unsigned(i_data));
                            o_address <= mem_address_read;

                        when 3 =>
                            mem_address_read <= std_logic_vector(unsigned(mem_address_read)+1);
                            o_address <= mem_address_read;

                        when 4 =>
                            current_word <= i_data;

                        when 5 =>
                            current_bit <= current_word(7);

                        when 14 =>
                            o_en <= '1';
                            o_we <= '1';
                            o_address <= mem_address_write;
                            o_data(7) <= p1k(7);
                            o_data(6) <= p2k(7);
                            o_data(5) <= p1k(6);
                            o_data(4) <= p2k(6);
                            o_data(3) <= p1k(5);
                            o_data(2) <= p2k(5);
                            o_data(1) <= p1k(4);
                            o_data(0) <= p2k(4);

                        when 15 =>
                            mem_address_write <= std_logic_vector(unsigned(mem_address_write) + 1);
                            o_address <= mem_address_write;

                        when 16 =>
                            o_data(7) <= p1k(3);
                            o_data(6) <= p2k(3);
                            o_data(5) <= p1k(2);
                            o_data(4) <= p2k(2);
                            o_data(3) <= p1k(1);
                            o_data(2) <= p2k(1);
                            o_data(1) <= p1k(0);
                            o_data(0) <= p2k(0);
                            num_of_words_computed <= num_of_words_computed + 1;
                            o_address <= mem_address_write;

                        when 17 =>
                            if (num_of_words_computed < num_of_words) then
                                vec_idx <= 0;
                                step <= 3;
                                p1k <= "XXXXXXXX";
                                p2k <= "XXXXXXXX";
                                o_address <= mem_address_read;
                                mem_address_write <= std_logic_vector(unsigned(mem_address_write) + 1);
                                o_we <= '0';
                            else
                                o_done <= '1';
                                done <= '1';
                                o_en <= '0';
                            end if;

                        when others =>
                            case PS is
                                when S00 =>
                                    if (current_bit = '0') then
                                        NS <= S00;
                                        p1k(7-vec_idx) <= '0';
                                        p2k(7-vec_idx) <= '0';
                                    else -- current_bit = '1'
                                        NS <= S10;
                                        p1k(7-vec_idx) <= '1';
                                        p2k(7-vec_idx) <= '1';
                                    end if;

                                when S01 =>
                                    if (current_bit = '0') then
                                        NS <= S00;
                                        p1k(7-vec_idx) <= '1';
                                        p2k(7-vec_idx) <= '1';
                                    else
                                        NS <= S10;
                                        p1k(7-vec_idx) <= '0';
                                        p2k(7-vec_idx) <= '0';
                                    end if;

                                when S10 =>
                                    if (current_bit = '0') then
                                        NS <= S01;
                                        p1k(7-vec_idx) <= '0';
                                        p2k(7-vec_idx) <= '1';
                                    else
                                        NS <= S11;
                                        p1k(7-vec_idx) <= '1';
                                        p2k(7-vec_idx) <= '0';
                                    end if;

                                when S11 =>
                                    if (current_bit = '0') then
                                        NS <= S01;
                                        p1k(7-vec_idx) <= '1';
                                        p2k(7-vec_idx) <= '0';
                                    else
                                        NS <= S11;
                                        p1k(7-vec_idx) <= '0';
                                        p2k(7-vec_idx) <= '1';
                                    end if;
                            end case;
                            if (vec_idx /= 7) then
                                current_bit <= current_word(7-vec_idx-1);
                            end if;
                            if (vec_idx < 7) then
                                vec_idx <= vec_idx+1;
                            end if;
                    end case;
                    if (step < 17) then
                        if (num_of_words = 0) then
                            step <= 17;
                        else
                            step <= step + 1;
                        end if;
                    end if;
                else  -- i_start = '0'
                    if (done = '1') then
                        o_done <= '0';
                        done <= '0';
                        step <= -1;
                        mem_address_read <= "0000000000000000";
                        mem_address_write <= std_logic_vector(to_unsigned(1000,16));
                    end if;
                end if;
            end if;
        end if;
    end process;

    next_state: process (i_clk)
    begin
        if (falling_edge(i_clk) and i_start = '1') then
            PS <= NS;
        end if;

    end process;
end Behavioral;




