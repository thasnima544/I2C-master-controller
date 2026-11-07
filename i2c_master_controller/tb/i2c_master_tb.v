
`timescale 1ns/1ps

module i2c_master_tb;

    reg clk;
    reg rst;
    reg start;
    reg [6:0] slave_addr;
    reg [7:0] data_in;

    wire scl;
    wire busy;
    wire done;
    wire ack_error;

    tri1 sda;

    // Simulated slave ACK driver
    reg slave_ack_low;
    assign sda = slave_ack_low ? 1'b0 : 1'bz;

    // DUT
    i2c_master #(
        .CLK_DIV(4)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .slave_addr(slave_addr),
        .data_in(data_in),
        .scl(scl),
        .sda(sda),
        .busy(busy),
        .done(done),
        .ack_error(ack_error)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    reg [7:0] rx_shift;
    reg [7:0] received_address;
    reg [7:0] received_data;

    integer bit_count;
    integer byte_count;

    // Capture incoming serial data on SCL rising edge
    always @(posedge scl) begin
        if (!rst) begin
            #1;

            if (bit_count < 8) begin

                rx_shift = {rx_shift[6:0], sda};

                if (bit_count == 7) begin

                    if (byte_count == 0) begin
                        received_address = rx_shift;

                        $display(
                            "SLAVE RECEIVED ADDRESS: %h",
                            rx_shift
                        );
                    end
                    else if (byte_count == 1) begin
                        received_data = rx_shift;

                        $display(
                            "SLAVE RECEIVED DATA: %h",
                            rx_shift
                        );
                    end

                end

                bit_count = bit_count + 1;

            end
            else begin

                // ACK clock
                bit_count = 0;
                byte_count = byte_count + 1;

                $display("SLAVE ACK DETECTED");

            end
        end
    end

    // Slave ACK control
    always @(negedge scl) begin
        if (!rst) begin

            if (bit_count == 8)
                slave_ack_low = 1'b1;

            else if (bit_count == 0 && byte_count > 0)
                slave_ack_low = 1'b0;

        end
    end

    // Main test sequence
    initial begin

        clk = 0;
        rst = 1;
        start = 0;

        slave_addr = 7'h50;
        data_in = 8'h3C;

        slave_ack_low = 0;

        rx_shift = 0;
        received_address = 0;
        received_data = 0;

        bit_count = 0;
        byte_count = 0;

        // Waveform dump
        $dumpfile("sim/i2c_waveform.vcd");
        $dumpvars(0, i2c_master_tb);

        // Reset
        #20;
        rst = 0;

        $display("RESET TEST PASSED");

        // Start transaction
        #20;
        start = 1;

        #10;
        start = 0;

        $display("I2C TRANSACTION STARTED");

        // Wait for completion
        wait(done == 1'b1);

        #10;

        // Address verification
        if (received_address == 8'hA0)
            $display("ADDRESS TEST PASSED");
        else
            $display(
                "ADDRESS TEST FAILED: %h",
                received_address
            );

        // Data verification
        if (received_data == 8'h3C)
            $display("DATA TEST PASSED");
        else
            $display(
                "DATA TEST FAILED: %h",
                received_data
            );

        // ACK verification
        if (ack_error == 0)
            $display("ACK TEST PASSED");
        else
            $display("ACK TEST FAILED");

        // Busy verification
        if (busy == 0)
            $display("BUSY TEST PASSED");
        else
            $display("BUSY TEST FAILED");

        $display("I2C TESTBENCH COMPLETED");

        #50;
        $finish;

    end

    // Timeout protection
    initial begin
        #200000;

        $display("ERROR: TESTBENCH TIMEOUT");

        $finish;
    end

endmodule
