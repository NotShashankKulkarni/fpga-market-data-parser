module feed_handler_top #(
    parameter DATA_WIDTH  = 8,
    parameter PRICE_WIDTH = 32,
    parameter QTY_WIDTH   = 32,
    parameter BUF_DEPTH   = 16
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  rx_data,
    input  wire                   rx_valid,
    input  wire                   rx_last,
    output wire [7:0]             out_msg_type,
    output wire [15:0]            out_seq_num,
    output wire [PRICE_WIDTH-1:0] out_price,
    output wire [QTY_WIDTH-1:0]   out_quantity,
    output wire                   out_valid,
    input  wire                   out_ready
);

    wire [DATA_WIDTH-1:0] eth_payload_data;
    wire                  eth_payload_valid;
    wire                  eth_payload_last;

    wire [DATA_WIDTH-1:0] udp_payload_data;
    wire                  udp_payload_valid;
    wire                  udp_payload_last;

    wire [7:0]             mkt_msg_type;
    wire [15:0]            mkt_seq_num;
    wire [PRICE_WIDTH-1:0] mkt_price;
    wire [QTY_WIDTH-1:0]   mkt_quantity;
    wire                   mkt_msg_valid;

    eth_rx_parser #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_eth (
        .clk          (clk),
        .rst_n        (rst_n),
        .rx_data      (rx_data),
        .rx_valid     (rx_valid),
        .rx_last      (rx_last),
        .payload_data (eth_payload_data),
        .payload_valid(eth_payload_valid),
        .payload_last (eth_payload_last),
        .dst_mac      (),
        .src_mac      (),
        .eth_type     (),
        .frame_valid  ()
    );

    udp_parser #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_udp (
        .clk          (clk),
        .rst_n        (rst_n),
        .in_data      (eth_payload_data),
        .in_valid     (eth_payload_valid),
        .in_last      (eth_payload_last),
        .payload_data (udp_payload_data),
        .payload_valid(udp_payload_valid),
        .payload_last (udp_payload_last),
        .src_port     (),
        .dst_port     (),
        .udp_length   (),
        .hdr_valid    ()
    );

    mkt_data_parser #(
        .DATA_WIDTH (DATA_WIDTH),
        .PRICE_WIDTH(PRICE_WIDTH),
        .QTY_WIDTH  (QTY_WIDTH)
    ) u_mkt (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_data  (udp_payload_data),
        .in_valid (udp_payload_valid),
        .in_last  (udp_payload_last),
        .msg_type (mkt_msg_type),
        .seq_num  (mkt_seq_num),
        .price    (mkt_price),
        .quantity (mkt_quantity),
        .msg_valid(mkt_msg_valid)
    );

    output_buffer #(
        .DATA_WIDTH (DATA_WIDTH),
        .PRICE_WIDTH(PRICE_WIDTH),
        .QTY_WIDTH  (QTY_WIDTH),
        .DEPTH      (BUF_DEPTH)
    ) u_buf (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_msg_type (mkt_msg_type),
        .in_seq_num  (mkt_seq_num),
        .in_price    (mkt_price),
        .in_quantity (mkt_quantity),
        .in_valid    (mkt_msg_valid),
        .in_ready    (),
        .out_msg_type(out_msg_type),
        .out_seq_num (out_seq_num),
        .out_price   (out_price),
        .out_quantity(out_quantity),
        .out_valid   (out_valid),
        .out_ready   (out_ready)
    );

endmodule
