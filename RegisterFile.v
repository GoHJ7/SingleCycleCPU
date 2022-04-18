module RegisterFile(input	reset,
                    input clk,
                    input [4:0] rs1,          // source register 1
                    input [4:0] rs2,          // source register 2
                    input [4:0] rd,           // destination register
                    input [31:0] rd_din,      // input data for rd
                    input write_enable,          // RegWrite signal
                    output [31:0] rs1_dout,   // output of rs 1
                    output [31:0] rs2_dout,
                    output reg is_halted);  // output of rs 2
  integer i;
  integer count =0;
  // Register file
  reg [31:0] rf[0:31];
  // TODO
  // Asynchronously read register file
  assign rs1_dout = (rs1 == 5'b0) ? 32'b0 : rf[rs1];
  assign rs2_dout = (rs2 == 5'b0) ? 32'b0 : rf[rs2];
  // Synchronously write data to the register file
  always @(posedge clk) begin
    if(write_enable && (rd != 5'b0))
      rf[rd] <= rd_din;
      else begin
      end
      if(rf[17]==32'b1010)
        is_halted <= 1;
      else begin
      end

  end
  /*
  always @(posedge clk) begin
    $display("new cycle: %d",count);
    count = count + 1;
     for (i = 0; i < 32; i = i + 1)
        $display("rf[%d]: %h",i,rf[i]);
      
  end
  */
  // Initialize register file (do not touch)
  always @(posedge clk) begin
    // Reset register file
    if (reset) begin
      for (i = 0; i < 32; i = i + 1)
        rf[i] = 32'b0;
      rf[2] = 32'h2ffc; // stack pointer
      is_halted =0;
    end
  end
endmodule
