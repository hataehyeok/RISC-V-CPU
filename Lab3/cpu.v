// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/

  // ---------- Wire of PC ----------
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire pc_control;  
  // ---------- Wire of Registers ----------
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [31:0] rd_din;
  wire write_enable;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  //---------- Wire of ControlUnit ----------
  
  wire inst_or_data;
  wire mem_read;
  wire mem_write;
  wire ALUSrcA;
  wire ALUSrcB;
  wire pcWrite;
  wire pcWire_cond;
  wire [1:0] ALUOp;
  wire PCSource;
  wire mem_to_reg;
  wire is_ecall;

  //---------- Wire of ImmediateGenerator ----------
  wire [31:0] imm_gen_out;
  //---------- Wire of ALUControlUnit ----------
  wire [2:0] alu_op;
  //---------- Wire of ALU ----------
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [2:0] funct3;
  wire [31:0] alu_result;
  wire alu_bcond;
  //---------- Wire of Memory ----------
  wire [31:0] mem_addr
  wire [31:0] dout

  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.

  assign rs1 = is_ecall ? 17 : IR[19:15]; //검토 필요 => is_halted 판별하려고 is ecall 조건 추가
  assign rs2 = instr[24:20];
  assign rd = instr[11:7];
  assign rd_din = mem_to_reg ? MDR : ALUOut;

  assign funct3 = IR[14:12];
  assign pc_control = (pcWrite|(pcWire_cond & !alu_bcond));
  assign next_pc = PCSource ? ALUOut : alu_result;
  assign mem_addr = inst_or_data ? ALUOut : current_pc;
  assign alu_in_1 = ALUSrcA ? A : current_pc;
  assign alu_in_2 = (ALUSrcB == 0) ? B : ((ALUSrcB == 1) ? 4 : imm_gen_out);

  always @(posedge clk) begin
    if(reset) begin
      IR <= 0;
      MDR <= 0;
      A <= 0;
      B <= 0;
      ALUOut <= 0;
    end
    else begin
      if(ir_write && (IR!=dout)) begin
        IF <= dout;
      end
      if(MDR!=dout) begin
        MDR <= dout;
      end
      if(A!=rs1_dout) begin
        A<=rs1_dout;
      end
      if(B!=rs2_dout) begin
        B<=rs2_dout;
      end
      if(ALUOut!=alu_result) begin
        ALUOut <= alu_result;
      end
    end
  end

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .pc_control(pc_control),
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(rs1),          // input
    .rs2(rs2),          // input
    .rd(rd),           // input
    .rd_din(rd_din),       // input
    .write_enable(write_enable),    // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout)      // output
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(mem_addr),         // input
    .din(B),          // input
    .mem_read(mem_read),     // input
    .mem_write(mem_write),    // input
    .dout(dout)          // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .part_of_inst(),  // input
    .is_jal(),        // output
    .is_jalr(),       // output
    .branch(),        // output
    .mem_read(),      // output
    .mem_to_reg(),    // output
    .mem_write(),     // output
    .alu_src(),       // output
    .write_enable(),     // output
    .pc_to_reg(),     // output
    .is_ecall()       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IR),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst(IR),  // input
    .ALUOp(ALUOp),
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .funct3(funct3),
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

endmodule
