module output_buffer #(
    parameter DATA_WIDTH  = 8,
    parameter PRICE_WIDTH = 32,
    parameter QTY_WIDTH   = 32,
    parameter DEPTH       = 16
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [7:0]             in_msg_type,
    input  wire [15:0]            in_seq_num,
    input  wire [PRICE_WIDTH-1:0] in_price,
    input  wire [QTY_WIDTH-1:0]   in_quantity,
    input  wire                   in_valid,
    output wire                   in_ready,
    output reg  [7:0]             out_msg_type,
    output reg  [15:0]            out_seq_num,
    output reg  [PRICE_WIDTH-1:0] out_price,
    output reg  [QTY_WIDTH-1:0]   out_quantity,
    output reg                    out_valid,
    input  wire                   out_ready
);

    localparam ENTRY_WIDTH = 8 + 16 + PRICE_WIDTH + QTY_WIDTH;
    localparam ADDR_W      = $clog2(DEPTH);

    reg [ENTRY_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_W:0]        wr_ptr;
    reg [ADDR_W:0]        rd_ptr;

    wire full  = (wr_ptr[ADDR_W] != rd_ptr[ADDR_W]) &&
                 (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]);
    wire empty = (wr_ptr == rd_ptr);

    assign in_ready = !full;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {(ADDR_W+1){1'b0}};
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= {ENTRY_WIDTH{1'b0}};
        end else if (in_valid && !full) begin
            mem[wr_ptr[ADDR_W-1:0]] <= {in_msg_type, in_seq_num, in_price, in_quantity};
            wr_ptr                  <= wr_ptr + 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr      <= {(ADDR_W+1){1'b0}};
            out_valid   <= 1'b0;
            out_msg_type <= 8'd0;
            out_seq_num  <= 16'd0;
            out_price    <= {PRICE_WIDTH{1'b0}};
            out_quantity <= {QTY_WIDTH{1'b0}};
        end else begin
            if (!empty && (!out_valid || out_ready)) begin
                {out_msg_type, out_seq_num, out_price, out_quantity} <= mem[rd_ptr[ADDR_W-1:0]];
                out_valid <= 1'b1;
                rd_ptr    <= rd_ptr + 1;
            end else if (out_valid && out_ready) begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule
