module udp_parser #(
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  in_data,
    input  wire                   in_valid,
    input  wire                   in_last,
    output reg  [DATA_WIDTH-1:0]  payload_data,
    output reg                    payload_valid,
    output reg                    payload_last,
    output reg  [15:0]            src_port,
    output reg  [15:0]            dst_port,
    output reg  [15:0]            udp_length,
    output reg                    hdr_valid
);

    localparam IDLE       = 3'd0;
    localparam SRC_PORT   = 3'd1;
    localparam DST_PORT   = 3'd2;
    localparam LENGTH     = 3'd3;
    localparam CHECKSUM   = 3'd4;
    localparam PAYLOAD    = 3'd5;

    reg [2:0]  state;
    reg [1:0]  byte_cnt;
    reg [15:0] src_port_r;
    reg [15:0] dst_port_r;
    reg [15:0] length_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            byte_cnt      <= 2'd0;
            src_port_r    <= 16'd0;
            dst_port_r    <= 16'd0;
            length_r      <= 16'd0;
            src_port      <= 16'd0;
            dst_port      <= 16'd0;
            udp_length    <= 16'd0;
            payload_data  <= {DATA_WIDTH{1'b0}};
            payload_valid <= 1'b0;
            payload_last  <= 1'b0;
            hdr_valid     <= 1'b0;
        end else begin
            payload_valid <= 1'b0;
            payload_last  <= 1'b0;
            hdr_valid     <= 1'b0;

            case (state)
                IDLE: begin
                    byte_cnt <= 2'd0;
                    if (in_valid)
                        state <= SRC_PORT;
                end

                SRC_PORT: begin
                    if (in_valid) begin
                        src_port_r <= {src_port_r[7:0], in_data};
                        byte_cnt   <= byte_cnt + 1;
                        if (byte_cnt == 2'd1) begin
                            byte_cnt <= 2'd0;
                            state    <= DST_PORT;
                        end
                    end
                end

                DST_PORT: begin
                    if (in_valid) begin
                        dst_port_r <= {dst_port_r[7:0], in_data};
                        byte_cnt   <= byte_cnt + 1;
                        if (byte_cnt == 2'd1) begin
                            byte_cnt <= 2'd0;
                            state    <= LENGTH;
                        end
                    end
                end

                LENGTH: begin
                    if (in_valid) begin
                        length_r <= {length_r[7:0], in_data};
                        byte_cnt <= byte_cnt + 1;
                        if (byte_cnt == 2'd1) begin
                            byte_cnt <= 2'd0;
                            state    <= CHECKSUM;
                        end
                    end
                end

                CHECKSUM: begin
                    if (in_valid) begin
                        byte_cnt <= byte_cnt + 1;
                        if (byte_cnt == 2'd1) begin
                            byte_cnt   <= 2'd0;
                            src_port   <= src_port_r;
                            dst_port   <= dst_port_r;
                            udp_length <= length_r;
                            hdr_valid  <= 1'b1;
                            state      <= PAYLOAD;
                        end
                    end
                end

                PAYLOAD: begin
                    if (in_valid) begin
                        payload_data  <= in_data;
                        payload_valid <= 1'b1;
                        payload_last  <= in_last;
                        if (in_last)
                            state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
