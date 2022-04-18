// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required
`include "Alu.v"
`include "AluControlUnit.v"
`include "ImmediateGenerator.v"
`include "Memory.v"
`include "Mux.v"
`include "opcodes.v"
`include "Pc.v"
`include "RegisterFile.v"


module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  //PC
  wire [31:0] next_pc;

  //InstMemory
  wire [31:0] instruction;

  //control unit
  wire is_jal;
  wire is_jalr;
  wire branch;
  wire mem_read;
  wire mem_to_reg;
  wire mem_write;
  wire alu_src;
  wire write_enable;
  wire pc_to_reg;
  wire halt1;
  //registerFile
  wire [31:0] rs1_dout,rs2_dout,rd_din;
   
  //immgen
  wire[31:0] imm_gen_out;

  //alu_control
  wire [10:0] alu_part_of_inst;
  wire [3:0] alu_op;

  //alu
  wire [31:0] alu_in_1,alu_in_2,alu_result;
  wire bcond;

  //datamemory
  wire [31:0] dout;
  wire [31:0] pcnext;
  wire [31:0] current_pc;
  /***** Register declarations *****/
  //PC
  /*
  always @(posedge clk) begin
    $display("rs1: %h",instruction[19:15]);
    $display("rs2: %h",instruction[24:20]);
    $display("rd: %h",instruction[11:7]);
    $display("rs1out: %h",rs1_dout);
    $display("rs2out: %h",rs2_dout);
  end
  always @(posedge clk) begin
    $display("next_pc: %h",next_pc);
    $display("current_pc: %h",current_pc);
  end
  always @(posedge clk) begin
    $display("instruction: %h",instruction);
  end
  always @(posedge clk) begin
    $display("aluin1: %h",alu_in_1);
    $display("aluin2: %h",alu_in_2);
    $display("aluresult: %h",alu_result);
  end
  always @(posedge clk) begin
    $display("immediate: %h",imm_gen_out);
    $display("Regwrite: %h",write_enable);
  end
  */
  
  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  //add after pc
  assign pcnext = current_pc + 32'd4;//32bit add

  reg is_call;
  always @ (posedge clk) begin
    if(reset) begin
      is_call <=0;
    end
    if(instruction[6:0]==`ECALL)begin
      is_call <=1;
    end
    else begin
      is_call <= 0;
    end
  end
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(instruction)     // output
  );
  
  wire [31:0] datamemtoreg;
  //mux 
  Mux32 register_write_data(
    .signal(pc_to_reg),
    .sig1(pcnext),
    .sig0(datamemtoreg),
    .out(rd_din)
  );
  Mux32 ALU_in(
    .signal(alu_src),
    .sig1(imm_gen_out),
    .sig0(rs2_dout),
    .out(alu_in_2)
  );
  Mux32 datamem(
    .signal(mem_to_reg),
    .sig1(dout),
    .sig0(alu_result),
    .out(datamemtoreg)
  );
  wire branch_and_bcond;
  assign branch_and_bcond = branch & bcond;
  wire pcsrc1;
  assign pcsrc1 = is_jal | branch_and_bcond;
  wire [31:0] add_currentpc_and_immgenout;
  assign add_currentpc_and_immgenout = imm_gen_out + current_pc;
  wire [31:0] afteradd1_result;
  Mux32 afteradd1(
    .signal(pcsrc1),
    .sig1(add_currentpc_and_immgenout),
    .sig0(pcnext),
    .out(afteradd1_result)
  );
  Mux32 afteradd2(
    .signal(is_jalr),
    .sig1(alu_result),
    .sig0(afteradd1_result),
    .out(next_pc)
  );
  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (instruction[19:15]),          // input
    .rs2 (instruction[24:20]),          // input
    .rd (instruction[11:7]),           // input write_register
    .rd_din (rd_din),       // input write_data
    .write_enable (write_enable),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout),
    .is_halted(halt1)      // output
  );
  

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(instruction[6:0]),  // input
    .is_jal(is_jal),        // output
    .is_jalr(is_jalr),       // output
    .branch(branch),        // output
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),     // output
    .pc_to_reg(pc_to_reg)   // output       // output (ecall inst)
  );
  assign is_halted = halt1&is_call;
  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(instruction),  // input
    .imm_gen_out(imm_gen_out)    // output
  );
  
  // ---------- ALU Control Unit ----------
  assign alu_part_of_inst = {instruction[30],instruction[14:12], instruction[6:0]};
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(alu_part_of_inst),  // input
    .alu_op(alu_op)         // output
  );
  assign alu_in_1 = rs1_dout;
  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(bcond)     // output
  );
  
  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (alu_result),       // input
    .din (rs2_dout),        // input
    .mem_read (mem_read),   // input
    .mem_write (mem_write),  // input
    .dout (dout)        // output
  );
endmodule
