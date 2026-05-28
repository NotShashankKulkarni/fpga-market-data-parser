module eth_rx_parser #(
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  rx_data,
    input  wire                   rx_valid,
    input  wire                   rx_last,
    output reg  [DATA_WIDTH-1:0]  payload_data,
    output reg                    payload_valid,
    output reg                    payload_last,
    output reg  [47:0]            dst_mac,
    output reg  [47:0]            src_mac,
    output reg  [15:0]            eth_type,
    output reg                    frame_valid
);

    localparam IDLE      = 3'd0;
    localparam DST_MAC   = 3'd1;
    localparam SRC_MAC   = 3'd2;
    localparam ETH_TYPE  = 3'd3;
    localparam PAYLOAD   = 3'd4;

    reg [2:0]  state;
    reg [2:0]  byte_cnt;
    reg [47:0] dst_mac_r;
    reg [47:0] src_mac_r;
    reg [15:0] eth_type_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            byte_cnt      <= 3'd0;
            dst_mac_r     <= 48'd0;
            src_mac_r     <= 48'd0;
            eth_type_r    <= 16'd0;
            dst_mac       <= 48'd0;
            src_mac       <= 48'd0;
            eth_type      <= 16'd0;
            payload_data  <= {DATA_WIDTH{1'b0}};
            payload_valid <= 1'b0;
            payload_last  <= 1'b0;
            frame_valid   <= 1'b0;
        end else begin
            payload_valid <= 1'b0;
            payload_last  <= 1'b0;
            frame_valid   <= 1'b0;

            case (state)
                IDLE: begin
                    byte_cnt   <= 3'd0;
                    dst_mac_r  <= 48'd0;
                    if (rx_valid)
                        state <= DST_MAC;
                end

                DST_MAC: begin
                    if (rx_valid) begin
                        dst_mac_r <= {dst_mac_r[39:0], rx_data};
                        byte_cnt  <= byte_cnt + 1;
                        if (byte_cnt == 3'd5) begin
                            byte_cnt <= 3'd0;
                            state    <= SRC_MAC;
                        end
                    end
                end

                SRC_MAC: begin
                    if (rx_valid) begin
                        src_mac_r <= {src_mac_r[39:0], rx_data};
                        byte_cnt  <= byte_cnt + 1;
                        if (byte_cnt == 3'd5) begin
                            byte_cnt <= 3'd0;
                            state    <= ETH_TYPE;
                        end
                    end
                end

                ETH_TYPE: begin
                    if (rx_valid) begin
                        eth_type_r <= {eth_type_r[7:0], rx_data};
                        byte_cnt   <= byte_cnt + 1;
                        if (byte_cnt == 3'd1) begin
                            byte_cnt  <= 3'd0;
                            dst_mac   <= dst_mac_r;
                            src_mac   <= src_mac_r;
                            eth_type  <= {eth_type_r[7:0], rx_data};
                            state     <= PAYLOAD;
                        end
                    end
                end

                PAYLOAD: begin
                    if (rx_valid) begin
                        payload_data  <= rx_data;
                        payload_valid <= 1'b1;
                        payload_last  <= rx_last;
                        frame_valid   <= 1'b1;
                        if (rx_last)
                            state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
