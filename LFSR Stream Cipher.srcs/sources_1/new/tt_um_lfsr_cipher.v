/*
 * LFSR Stream Cipher — TinyTapeout Submission
 * IEEE CEDA SSCS Chapter, KIIT University
 *
 * ui_in  [7:0] : 8-bit key input (loaded on rst)
 * uo_out [7:0] : 8-bit keystream output (raw LFSR output)
 * uio    [7:0] : bidirectional — input plaintext, output ciphertext
 * uio_oe [7:0] : set to 0xFF (all outputs) during cipher mode
 *
 * How it works:
 *   1. On reset, LFSR is seeded with {ui_in, 8'hA5} (key + fixed salt)
 *   2. Every clock cycle, LFSR shifts and generates 1 new keystream byte
 *   3. uo_out shows raw keystream
 *   4. uio_out = uio_in XOR keystream (encrypt/decrypt)
 */

module tt_um_lfsr_cipher (
    input  wire [7:0] ui_in,    // 8-bit key
    output wire [7:0] uo_out,   // keystream output
    input  wire [7:0] uio_in,   // plaintext input
    output wire [7:0] uio_out,  // ciphertext output
    output wire [7:0] uio_oe,   // bidirectional direction (1=output)
    input  wire       ena,       // always 1
    input  wire       clk,       // clock
    input  wire       rst_n      // active-low reset
);

    // 16-bit Galois LFSR
    // Taps at positions 16,15,13,4 ? polynomial x^16+x^15+x^13+x^4+1
    // This gives maximum-length sequence of 65535 cycles before repeating
    reg [15:0] lfsr;

    wire feedback = lfsr[0]; // LSB feedback

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Seed LFSR with key + salt (never seed with 0)
            lfsr <= {ui_in, 8'hA5};
        end else begin
            // Galois LFSR shift with taps
            lfsr <= {1'b0, lfsr[15:1]}          // shift right
                  ^ (feedback ? 16'hB400 : 16'h0); // XOR taps if feedback=1
            // 0xB400 = taps at bits 15,13,12,10 for maximal length
        end
    end

    // Keystream = upper 8 bits of LFSR state
    wire [7:0] keystream = lfsr[15:8];

    // Encrypt: XOR plaintext with keystream
    assign uo_out  = keystream;           // raw keystream visible on output
    assign uio_out = uio_in ^ keystream; // ciphertext = plaintext XOR keystream
    assign uio_oe  = 8'hFF;              // all bidir pins are outputs

endmodule