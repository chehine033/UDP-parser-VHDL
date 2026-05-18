library ieee;
use ieee.std_logic_1164.all;

entity udp_parser_tb is
end entity;

architecture sim of udp_parser_tb is

    signal clk            : std_logic := '0';
    signal reset          : std_logic := '1';
    signal s_axis_tdata   : std_logic_vector(7 downto 0) := (others => '0');
    signal s_axis_tvalid  : std_logic := '0';
    signal s_axis_tlast   : std_logic := '0';
    signal s_axis_tready  : std_logic;
    signal dst_mac        : std_logic_vector(47 downto 0);
    signal src_mac        : std_logic_vector(47 downto 0);
    signal dst_ip         : std_logic_vector(31 downto 0);
    signal src_ip         : std_logic_vector(31 downto 0);
    signal dst_port       : std_logic_vector(15 downto 0);
    signal src_port       : std_logic_vector(15 downto 0);
    signal payload_length : std_logic_vector(15 downto 0);
    signal parsing_done   : std_logic;

    constant CLK_PERIOD : time := 10 ns;

    type byte_array_t is array(natural range <>) of std_logic_vector(7 downto 0);

    -- Valid UDP frame (46 bytes total):
    --   dst_mac  = AA:BB:CC:DD:EE:FF
    --   src_mac  = 11:22:33:44:55:66
    --   src_ip   = 192.168.1.10
    --   dst_ip   = 192.168.1.20
    --   src_port = 1234  dst_port = 5678
    --   UDP len  = 12 (8 hdr + 4 payload)
    constant VALID_UDP : byte_array_t(0 to 45) := (
        -- Ethernet header (14 bytes)
        x"AA", x"BB", x"CC", x"DD", x"EE", x"FF",  -- dst mac
        x"11", x"22", x"33", x"44", x"55", x"66",  -- src mac
        x"08", x"00",                                -- EtherType = IPv4
        -- IPv4 header (20 bytes)
        x"45", x"00",                                -- version/IHL, DSCP
        x"00", x"1C",                                -- total length = 28
        x"00", x"01",                                -- identification
        x"00", x"00",                                -- flags / fragment offset
        x"40", x"11",                                -- TTL=64, protocol=0x11 (UDP)
        x"00", x"00",                                -- header checksum
        x"C0", x"A8", x"01", x"0A",                 -- src IP 192.168.1.10
        x"C0", x"A8", x"01", x"14",                 -- dst IP 192.168.1.20
        -- UDP header (8 bytes)
        x"04", x"D2",                                -- src port = 1234
        x"16", x"2E",                                -- dst port = 5678
        x"00", x"0C",                                -- UDP length = 12
        x"00", x"00",                                -- checksum (not checked)
        -- payload (4 bytes)
        x"DE", x"AD", x"BE", x"EF"
    );

    -- TCP frame: protocol = 0x06 instead of 0x11 -> frame_ok drops, parsing_done never fires
    constant TCP_PKT : byte_array_t(0 to 45) := (
        x"AA", x"BB", x"CC", x"DD", x"EE", x"FF",
        x"11", x"22", x"33", x"44", x"55", x"66",
        x"08", x"00",
        x"45", x"00",
        x"00", x"1C",
        x"00", x"02",
        x"00", x"00",
        x"40", x"06",                                -- protocol = TCP -> drop
        x"00", x"00",
        x"C0", x"A8", x"01", x"0A",
        x"C0", x"A8", x"01", x"14",
        x"04", x"D2",
        x"16", x"2E",
        x"00", x"0C",
        x"00", x"00",
        x"DE", x"AD", x"BE", x"EF"
    );

    -- ARP frame: EtherType = 0x0806 -> frame_ok drops at byte 13, parsing_done never fires
    constant ARP_PKT : byte_array_t(0 to 45) := (
        x"AA", x"BB", x"CC", x"DD", x"EE", x"FF",
        x"11", x"22", x"33", x"44", x"55", x"66",
        x"08", x"06",                                -- EtherType = ARP -> drop
        x"45", x"00",
        x"00", x"1C",
        x"00", x"03",
        x"00", x"00",
        x"40", x"11",
        x"00", x"00",
        x"C0", x"A8", x"01", x"0A",
        x"C0", x"A8", x"01", x"14",
        x"04", x"D2",
        x"16", x"2E",
        x"00", x"0C",
        x"00", x"00",
        x"DE", x"AD", x"BE", x"EF"
    );

    -- Drive one byte per clock; assert tlast on the final byte
    procedure send_packet (
        constant pkt       : in  byte_array_t;
        signal   tdata     : out std_logic_vector(7 downto 0);
        signal   tvalid    : out std_logic;
        signal   tlast     : out std_logic;
        signal   clk_sig   : in  std_logic
    ) is
    begin
        for i in pkt'range loop
            tdata  <= pkt(i);
            tvalid <= '1';
            if i = pkt'high then
                tlast <= '1';
            else
                tlast <= '0';
            end if;
            wait until rising_edge(clk_sig);
        end loop;
        tvalid <= '0';
        tlast  <= '0';
        tdata  <= (others => '0');
    end procedure;

begin

    DUT : entity work.udp_parser
        port map (
            clk            => clk,
            reset          => reset,
            s_axis_tdata   => s_axis_tdata,
            s_axis_tvalid  => s_axis_tvalid,
            s_axis_tlast   => s_axis_tlast,
            s_axis_tready  => s_axis_tready,
            dst_mac        => dst_mac,
            src_mac        => src_mac,
            dst_ip         => dst_ip,
            src_ip         => src_ip,
            dst_port       => dst_port,
            src_port       => src_port,
            payload_length => payload_length,
            parsing_done   => parsing_done
        );

    clk <= not clk after CLK_PERIOD / 2;

    stim : process
    begin
        -- Hold reset for 3 cycles then release
        reset <= '1';
        wait for 3 * CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;

        -- Packet 1: valid UDP
        -- Expected: parsing_done pulses high after byte 42 and holds until tlast
        send_packet(VALID_UDP, s_axis_tdata, s_axis_tvalid, s_axis_tlast, clk);
        wait for 5 * CLK_PERIOD;

        -- Packet 2: TCP (protocol mismatch)
        -- Expected: frame_ok goes low at byte 23, parsing_done never asserts
        send_packet(TCP_PKT, s_axis_tdata, s_axis_tvalid, s_axis_tlast, clk);
        wait for 5 * CLK_PERIOD;

        -- Packet 3: ARP (EtherType mismatch)
        -- Expected: frame_ok goes low at byte 13, parsing_done never asserts
        send_packet(ARP_PKT, s_axis_tdata, s_axis_tvalid, s_axis_tlast, clk);
        wait for 5 * CLK_PERIOD;

        -- Packet 4: valid UDP again to confirm the parser recovered cleanly
        -- Expected: parsing_done pulses high after byte 42 as with packet 1
        send_packet(VALID_UDP, s_axis_tdata, s_axis_tvalid, s_axis_tlast, clk);
        wait for 10 * CLK_PERIOD;

        wait;
    end process;

end sim;