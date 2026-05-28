`timescale 1ns/1ps

module tb_feed_handler_top;

    parameter DATA_WIDTH  = 8;
    parameter PRICE_WIDTH = 32;
    parameter QTY_WIDTH   = 32;

    reg                   clk;
    reg                   rst_n;
    reg  [DATA_WIDTH-1:0] rx_data;
    reg                   rx_valid;
    reg                   rx_last;
    wire [7:0]             out_msg_type;
    wire [15:0]            out_seq_num;
    wire [PRICE_WIDTH-1:0] out_price;
    wire [QTY_WIDTH-1:0]   out_quantity;
    wire                   out_valid;
    reg                    out_ready;

    feed_handler_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .PRICE_WIDTH(PRICE_WIDTH),
        .QTY_WIDTH  (QTY_WIDTH),
        .BUF_DEPTH  (16)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .rx_last     (rx_last),
        .out_msg_type(out_msg_type),
        .out_seq_num (out_seq_num),
        .out_price   (out_price),
        .out_quantity(out_quantity),
        .out_valid   (out_valid),
        .out_ready   (out_ready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg [7:0] packet [0:35];
    integer i;

    task send_byte;
        input [7:0] d;
        input       last;
        begin
            rx_data  = d;
            rx_valid = 1;
            rx_last  = last;
            @(posedge clk); #1;
        end
    endtask

    initial begin
        $dumpfile("tb_feed_handler_top.vcd");
        $dumpvars(0, tb_feed_handler_top);

        rst_n     = 0;
        rx_data   = 0;
        rx_valid  = 0;
        rx_last   = 0;
        out_ready = 1;

        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;

        packet[0]  = 8'hFF; packet[1]  = 8'hFF; packet[2]  = 8'hFF;
        packet[3]  = 8'hFF; packet[4]  = 8'hFF; packet[5]  = 8'hFF;
        packet[6]  = 8'hAA; packet[7]  = 8'hBB; packet[8]  = 8'hCC;
        packet[9]  = 8'hDD; packet[10] = 8'hEE; packet[11] = 8'hFF;
        packet[12] = 8'h08; packet[13] = 8'h00;
        packet[14] = 8'h13; packet[15] = 8'h88;
        packet[16] = 8'h27; packet[17] = 8'h10;
        packet[18] = 8'h00; packet[19] = 8'h16;
        packet[20] = 8'h00; packet[21] = 8'h00;
        packet[22] = 8'h41;
        packet[23] = 8'h00; packet[24] = 8'h01;
        packet[25] = 8'h00; packet[26] = 8'h00; packet[27] = 8'h27; packet[28] = 8'h10;
        packet[29] = 8'h00; packet[30] = 8'h00; packet[31] = 8'h03; packet[32] = 8'hE8;

        for (i = 0; i < 33; i = i + 1)
            send_byte(packet[i], (i == 32) ? 1 : 0);

        rx_valid = 0;
        rx_last  = 0;

        repeat(20) @(posedge clk);

        if (out_valid) begin
            $display("msg_type = %h  (expected 41)", out_msg_type);
            $display("seq_num  = %0d (expected 1)",  out_seq_num);
            $display("price    = %0d (expected 10000)", out_price);
            $display("quantity = %0d (expected 1000)",  out_quantity);
        end else begin
            $display("No output received");
        end

        $finish;
    end

endmodule
