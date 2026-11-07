
`timescale 1ns/1ps

module i2c_master #(
    parameter CLK_DIV = 250
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [6:0] slave_addr,
    input wire [7:0] data_in,

    output reg scl,
    inout wire sda,

    output reg busy,
    output reg done,
    output reg ack_error
);

    // Open-drain SDA
    reg sda_drive_low;
    wire sda_in;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    assign sda_in = sda;

    // FSM states
    localparam IDLE       = 4'd0;
    localparam START      = 4'd1;
    localparam BIT_LOW    = 4'd2;
    localparam BIT_HIGH   = 4'd3;
    localparam ACK_LOW    = 4'd4;
    localparam ACK_HIGH   = 4'd5;
    localparam STOP_LOW   = 4'd6;
    localparam STOP_HIGH  = 4'd7;
    localparam STOP_END   = 4'd8;

    reg [3:0] state;
    reg [15:0] clk_count;

    reg [7:0] shift_reg;
    reg [7:0] data_reg;
    reg [2:0] bit_index;

    reg address_phase;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            clk_count      <= 0;
            shift_reg      <= 0;
            data_reg       <= 0;
            bit_index      <= 0;
            address_phase  <= 1'b0;

            scl            <= 1'b1;
            sda_drive_low  <= 1'b0;

            busy           <= 1'b0;
            done           <= 1'b0;
            ack_error      <= 1'b0;
        end
        else begin
            done <= 1'b0;

            case (state)

                IDLE: begin
                    scl           <= 1'b1;
                    sda_drive_low <= 1'b0;
                    busy          <= 1'b0;
                    clk_count     <= 0;

                    if (start) begin
                        shift_reg     <= {slave_addr, 1'b0};
                        data_reg      <= data_in;
                        bit_index     <= 3'd7;
                        address_phase <= 1'b1;

                        busy          <= 1'b1;
                        ack_error     <= 1'b0;
                        sda_drive_low <= 1'b1;

                        state <= START;
                    end
                end

                START: begin
                    scl           <= 1'b1;
                    sda_drive_low <= 1'b1;

                    if (clk_count == CLK_DIV-1) begin
                        clk_count <= 0;
                        scl       <= 1'b0;
                        state     <= BIT_LOW;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                BIT_LOW: begin
                    scl <= 1'b0;

                    if (address_phase)
                        sda_drive_low <= ~shift_reg[7];
                    else
                        sda_drive_low <= ~data_reg[7];

                    if (clk_count == CLK_DIV-1) begin
                        clk_count <= 0;
                        scl       <= 1'b1;
                        state     <= BIT_HIGH;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                BIT_HIGH: begin
                    scl <= 1'b1;

                    if (clk_count == CLK_DIV-1) begin
                        clk_count <= 0;
                        scl       <= 1'b0;

                        if (bit_index == 0) begin
                            sda_drive_low <= 1'b0;
                            state <= ACK_LOW;
                        end
                        else begin
                            bit_index <= bit_index - 1'b1;

                            if (address_phase)
                                shift_reg <= {shift_reg[6:0], 1'b0};
                            else
                                data_reg <= {data_reg[6:0], 1'b0};

                            state <= BIT_LOW;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ACK_LOW: begin
                    scl           <= 1'b0;
                    sda_drive_low <= 1'b0;

                    if (clk_count == CLK_DIV-1) begin
                        clk_count <= 0;
                        scl       <= 1'b1;
                        state     <= ACK_HIGH;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ACK_HIGH: begin
                    scl <= 1'b1;

                    if (clk_count == CLK_DIV-1) begin
                        clk_count <= 0;
                        scl       <= 1'b0;

                        if (sda_in == 1'b1) begin
                            ack_error <= 1'b1;
                            state <= STOP_LOW;
                        end
                        else if (address_phase) begin
                            address_phase <= 1'b0;
                            bit_index <= 3'd7;
                            state <= BIT_LOW;
                        end
                        else begin
                            state <= STOP_LOW;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP_LOW: begin
                    scl           <= 1'b0;
                    sda_drive_low <= 1'b1;

                    if (clk_count == CLK_DIV-1) begin
                        clk_count <= 0;
                        scl       <= 1'b1;
                        state     <= STOP_HIGH;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP_HIGH: begin
                    scl           <= 1'b1;
                    sda_drive_low <= 1'b1;

                    if (clk_count == CLK_DIV-1) begin
                        clk_count <= 0;
                        state     <= STOP_END;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP_END: begin
                    scl           <= 1'b1;
                    sda_drive_low <= 1'b0;

                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
