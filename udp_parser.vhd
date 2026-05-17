library ieee;
use ieee.std_logic_1164.all;

entity udp_parser is
port(
    clk            : in  std_logic;
    reset          : in  std_logic;
    s_axis_tdata   : in  std_logic_vector(7 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tlast   : in  std_logic;
    s_axis_tready  : out std_logic;
    dst_mac        : out std_logic_vector(47 downto 0);
    src_mac        : out std_logic_vector(47 downto 0);
    dst_ip         : out std_logic_vector(31 downto 0);
    src_ip         : out std_logic_vector(31 downto 0);
    dst_port       : out std_logic_vector(15 downto 0);
    src_port       : out std_logic_vector(15 downto 0);
    payload_length : out std_logic_vector(15 downto 0);
    parsing_done   : out std_logic
);
end udp_parser;

architecture BHVudp_parser of udp_parser is

    -- 42 bytes: 14 Ethernet + 20 IP + 8 UDP headers
    type shreg_t is array(0 to 41) of std_logic_vector(7 downto 0);
    signal shreg : shreg_t := (others => (others => '0'));

    -- valid_pipe propagates a '1' on every valid byte received
    -- when bit 41 goes high, 42 valid bytes have passed through the pipeline
    signal valid_pipe : std_logic_vector(41 downto 0) := (others => '0');

    -- early abort flag: goes low if EtherType is not IPv4 or Protocol is not UDP
    -- resets to '1' on tlast so the next frame starts clean
    signal frame_ok : std_logic := '1';

begin

    s_axis_tready <= '1';
    parsing_done  <= valid_pipe(41) and frame_ok;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                shreg      <= (others => (others => '0'));
                valid_pipe <= (others => '0');
                frame_ok   <= '1';
            elsif s_axis_tvalid = '1' then

                if valid_pipe(41) = '0'  then
                    shreg(0) <= s_axis_tdata;
                    for i in 1 to 41 loop
                        shreg(i) <= shreg(i - 1);
                    end loop;
                    valid_pipe <= valid_pipe(40 downto 0) & '1';

                    -- EtherType check: triggered when byte 13 arrives
                    -- shreg(0) is still byte 12 (old value), s_axis_tdata is byte 13
                    -- EtherType = byte12 & byte13 must equal 0x0800 for IPv4
                    if valid_pipe(12) = '1' and valid_pipe(13) = '0' then
                        if shreg(0) & s_axis_tdata /= x"0800" then
                            frame_ok <= '0';
                        end if;
                    end if;

                    -- Protocol check: triggered when byte 23 arrives
                    -- s_axis_tdata is byte 23, must equal 0x11 for UDP
                    if valid_pipe(22) = '1' and valid_pipe(23) = '0' then
                        if s_axis_tdata /= x"11" then
                            frame_ok <= '0';
                        end if;
                    end if;
                end if;

                -- payload bytes consumed silently until tlast
                -- tlast also resets frame_ok so the next frame starts clean
                if s_axis_tlast = '1' then
                    valid_pipe <= (others => '0');
                    frame_ok   <= '1';
                end if;

            end if;
        end if;
    end process;


    dst_mac        <= shreg(41) & shreg(40) & shreg(39) & shreg(38) & shreg(37) & shreg(36);
    src_mac        <= shreg(35) & shreg(34) & shreg(33) & shreg(32) & shreg(31) & shreg(30);
    src_ip         <= shreg(15) & shreg(14) & shreg(13) & shreg(12);
    dst_ip         <= shreg(11) & shreg(10) & shreg(9)  & shreg(8);
    src_port       <= shreg(7)  & shreg(6);
    dst_port       <= shreg(5)  & shreg(4);
    payload_length <= shreg(3)  & shreg(2);

end BHVudp_parser;
