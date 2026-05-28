`timescale 1ns/1ps

module tb_eth_rx_parser;

    parameter DATA_WIDTH = 8;

    reg                  clk;
    reg                  rst_n;
    reg  [DATA_WIDTH-1:0] rx_data;
    reg                  rx_valid;
    reg                  rx_last;
    wire [DATA_WIDTH-1:0] payload_data;
    wire                  payload_valid;
    wire                  payload_last;
    wire [47:0]           dst_mac;
    wire [47:0]           src_mac;
    wire [15:0]           eth_type;
    wire                  frame_valid;

    eth_rx_parser #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .rx_data      (rx_data),
        .rx_valid     (rx_valid),
        .rx_last      (rx_last),
        .payload_data (payload_data),
        .payload_valid(payload_valid),
        .payload_last (payload_last),
        .dst_mac      (dst_mac),
        .src_mac      (src_mac),
        .eth_type     (eth_type),
        .frame_valid  (frame_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg [7:0] frame [0:17];
    integer i;

    initial begin
        $dumpfile("tb_eth_rx_parser.vcd");
        $dumpvars(0, tb_eth_rx_parser);

        rst_n    = 0;
        rx_data  = 0;
        rx_valid = 0;
        rx_last  = 0;

        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;

        frame[0]  = 8'hFF;
        frame[1]  = 8'hFF;
        frame[2]  = 8'hFF;
        frame[3]  = 8'hFF;
        frame[4]  = 8'hFF;
        frame[5]  = 8'hFF;
        frame[6]  = 8'hAA;
        frame[7]  = 8'hBB;
        frame[8]  = 8'hCC;
        frame[9]  = 8'hDD;
        frame[10] = 8'hEE;
        frame[11] = 8'hFF;
        frame[12] = 8'h08;
        frame[13] = 8'h00;
        frame[14] = 8'hDE;
        frame[15] = 8'hAD;
        frame[16] = 8'hBE;
        frame[17] = 8'hEF;

        for (i = 0; i < 18; i = i + 1) begin
            rx_data  = frame[i];
            rx_valid = 1;
            rx_last  = (i == 17) ? 1 : 0;
            @(posedge clk); #1;
        end
        rx_valid = 0;
        rx_last  = 0;

        repeat(4) @(posedge clk);

        $display("dst_mac  = %h (expected ffffffffffff)", dst_mac);
        $display("src_mac  = %h (expected aabbccddeeff)", src_mac);
        $display("eth_type = %h (expected 0800)", eth_type);

        $finish;
    end

endmodule
