module mkt_data_parser #(
    parameter DATA_WIDTH  = 8,
    parameter PRICE_WIDTH = 32,
    parameter QTY_WIDTH   = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  in_data,
    input  wire                   in_valid,
    input  wire                   in_last,
    output reg  [7:0]             msg_type,
    output reg  [15:0]            seq_num,
    output reg  [PRICE_WIDTH-1:0] price,
    output reg  [QTY_WIDTH-1:0]   quantity,
    output reg                    msg_valid
);

    localparam IDLE      = 3'd0;
    localparam MSG_TYPE  = 3'd1;
    localparam SEQ_NUM   = 3'd2;
    localparam PRICE_S   = 3'd3;
    localparam QTY_S     = 3'd4;
    localparam DONE      = 3'd5;

    reg [2:0]           state;
    reg [2:0]           byte_cnt;
    reg [7:0]           msg_type_r;
    reg [15:0]          seq_num_r;
    reg [PRICE_WIDTH-1:0] price_r;
    reg [QTY_WIDTH-1:0]   qty_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            byte_cnt   <= 3'd0;
            msg_type_r <= 8'd0;
            seq_num_r  <= 16'd0;
            price_r    <= {PRICE_WIDTH{1'b0}};
            qty_r      <= {QTY_WIDTH{1'b0}};
            msg_type   <= 8'd0;
            seq_num    <= 16'd0;
            price      <= {PRICE_WIDTH{1'b0}};
            quantity   <= {QTY_WIDTH{1'b0}};
            msg_valid  <= 1'b0;
        end else begin
            msg_valid <= 1'b0;

            case (state)
                IDLE: begin
                    byte_cnt <= 3'd0;
                    price_r  <= {PRICE_WIDTH{1'b0}};
                    qty_r    <= {QTY_WIDTH{1'b0}};
                    if (in_valid)
                        state <= MSG_TYPE;
                end

                MSG_TYPE: begin
                    if (in_valid) begin
                        msg_type_r <= in_data;
                        state      <= SEQ_NUM;
                        byte_cnt   <= 3'd0;
                    end
                end

                SEQ_NUM: begin
                    if (in_valid) begin
                        seq_num_r <= {seq_num_r[7:0], in_data};
                        byte_cnt  <= byte_cnt + 1;
                        if (byte_cnt == 3'd1) begin
                            byte_cnt <= 3'd0;
                            state    <= PRICE_S;
                        end
                    end
                end

                PRICE_S: begin
                    if (in_valid) begin
                        price_r  <= {price_r[PRICE_WIDTH-9:0], in_data};
                        byte_cnt <= byte_cnt + 1;
                        if (byte_cnt == 3'd3) begin
                            byte_cnt <= 3'd0;
                            state    <= QTY_S;
                        end
                    end
                end

                QTY_S: begin
                    if (in_valid) begin
                        qty_r    <= {qty_r[QTY_WIDTH-9:0], in_data};
                        byte_cnt <= byte_cnt + 1;
                        if (byte_cnt == 3'd3) begin
                            byte_cnt <= 3'd0;
                            state    <= DONE;
                        end
                    end
                end

                DONE: begin
                    msg_type  <= msg_type_r;
                    seq_num   <= seq_num_r;
                    price     <= price_r;
                    quantity  <= qty_r;
                    msg_valid <= 1'b1;
                    state     <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
