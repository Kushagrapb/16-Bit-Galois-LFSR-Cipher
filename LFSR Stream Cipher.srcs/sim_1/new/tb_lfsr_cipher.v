`timescale 1ns/1ps

module tb_lfsr_cipher;

    reg        clk, rst_n;
    reg  [7:0] ui_in;   // key
    reg  [7:0] uio_in;  // plaintext
    wire [7:0] uo_out;  // keystream
    wire [7:0] uio_out; // ciphertext
    wire [7:0] uio_oe;

    // Instantiate design
    tt_um_lfsr_cipher uut (
        .clk(clk), .rst_n(rst_n),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(1'b1)
    );

    // 10ns clock
    always #5 clk = ~clk;

    integer i;

    initial begin
        $dumpfile("cipher.vcd");
        $dumpvars(0, tb_lfsr_cipher);

        clk   = 0;
        rst_n = 0;
        ui_in = 8'hAB;   // secret key = 0xAB
        uio_in = 8'h48;  // plaintext  = 0x48 ('H')

        // Apply reset for 2 cycles
        #10 rst_n = 1;

        $display("Key = 0x%02X", ui_in);
        $display("Plaintext = 0x%02X ('%c')", uio_in, uio_in);
        $display("-----------------------------");
        $display("Cycle | Keystream | Ciphertext");

        // Run 10 cycles, observe keystream and ciphertext
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            #1; // small delay for output to settle
            $display("  %2d  |   0x%02X   |   0x%02X", i, uo_out, uio_out);
        end

        // Now try decryption:
        // Feed ciphertext back in - XOR with same keystream = original plaintext
        $display("\n-- Decryption Test --");
        rst_n = 0; #10 rst_n = 1; // reset to resync keystream

        @(posedge clk); #1;
        uio_in = uio_out; // feed ciphertext in
        @(posedge clk); #1;
        $display("Decrypted = 0x%02X ('%c')", uio_out, uio_out);

        #20 $finish;
    end

endmodule