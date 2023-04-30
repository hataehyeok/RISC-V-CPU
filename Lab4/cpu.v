// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] next_pc;
  wire [31:0] current_pc;

  wire [31:0] instr;


  wire mem_read;
  wire mem_to_reg;
  wire mem_write;
  wire alu_src;
  wire reg_write;
  wire is_ecall;

  wire [31:0] imm_gen_out;


  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [4:0] rs1_from_inst;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [31:0] rd_din;

  wire [1:0] ALUOp;
  wire [2:0] alu_op;
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;

  wire [31:0] dmem_dout;

  wire _is_halted;
  wire is_x17_10;

  wire is_hazard;
  wire pc_write;
  wire if_id_write;
  /***** Data Forwarding *****/
  wire [1:0] forward_A;
  wire [1:0] forward_B;
  wire [31:0] forWard_B_out;

  wire [1:0]mux_rs1_dout;
  wire mux_rs2_dout;

  wire [31:0] f_rs1_dout;
  wire [31:0] f_rs2_dout;


  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [1:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_inst;
  reg [4:0] ID_EX_rd;
  reg ID_EX_is_halted;    //일단 추가적으로 선언하고 사용

  // For Forwarding
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  //reg EX_MEM_is_branch;     // will be used in MEM stage
  // 일단 이거 주석처리해 놓던데 왜인지는 모르겠음
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;
  reg EX_MEM_is_halted;   //얘도 추가적으로 선언하고 씀

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  // From others
  reg MEM_WB_mem_to_reg_src_1;
  reg MEM_WB_mem_to_reg_src_2;

  reg [4:0] MEM_WB_rd;
  reg MEM_WB_is_halted;


  // assign
  assign rs1_from_inst = IF_ID_inst[19:15];
  assign rs2 = IF_ID_inst[24:20];
  assign rd = MEM_WB_rd;
  
  // assign alu_in_1=ID_EX_rs1_data; => forwarding ?��면서 취소


  assign is_x17_10 = (f_rs1_dout==10)&(rs1==17);
  assign _is_halted = is_ecall & is_x17_10;
  assign is_halted = MEM_WB_is_halted;

  assign pc_write=!is_hazard;
  assign if_id_write=!is_hazard;



  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .pc_write(pc_write),
    .current_pc(current_pc)   // output
  );
  
  // ---------- Adder for program counter ----------
  // PC address must be updated to (previous address + 4)
  Adder pc_adder(
    .input1(current_pc),
    .input2(4),
    .output_adder(next_pc)
  );

  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(instr)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst <= 0;
    end
    else if (if_id_write) begin
      IF_ID_inst <= instr;
    end
    else begin
    end
    // 밑에 else부분은 지워도 되지 않을까 싶음
  end

  // ---------- MUX for calculate rs1 ----------
  // 
  MuxForIsEcall mux_for_is_ecall(
    .input0(rs1_from_inst),
    .input1(5'd17),
    .signal(is_ecall),
    .output_mux(rs1)
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (rs2),          // input
    .rd (rd),           // input
    .rd_din (rd_din),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),  // input
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    // .write_enable(),  // output
    // .pc_to_reg(),     // output
    .reg_write(reg_write),     // output
    .alu_op(ALUOp),        // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset | is_hazard) begin
      ID_EX_alu_op <= 0;         // will be used in EX stage
      ID_EX_alu_src <= 0;        // will be used in EX stage
      ID_EX_mem_write <= 0;      // will be used in MEM stage
      ID_EX_mem_read <= 0;       // will be used in MEM stage
      ID_EX_mem_to_reg <= 0;     // will be used in WB stage
      ID_EX_reg_write <= 0;      // will be used in WB stage
      // From others
      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;
      ID_EX_imm <= 0;
      ID_EX_inst <= 0;
      ID_EX_rd <= 0;
      ID_EX_is_halted <= 0;
      ID_EX_rs1 <= 0;
      ID_EX_rs2 <= 0;
    end
    else begin
      // From the control unit
      ID_EX_alu_op <= ALUOp;         // will be used in EX stage
      ID_EX_alu_src <= alu_src;        // will be used in EX stage
      ID_EX_mem_write <= mem_write;      // will be used in MEM stage
      ID_EX_mem_read <= mem_read;       // will be used in MEM stage
      ID_EX_mem_to_reg <= mem_to_reg;     // will be used in WB stage
      ID_EX_reg_write <= reg_write;      // will be used in WB stage
      // From others
      ID_EX_rs1_data <= f_rs1_dout;
      ID_EX_rs2_data <= f_rs2_dout;
      ID_EX_imm <= imm_gen_out;
      ID_EX_inst <= IF_ID_inst;
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_is_halted <= _is_halted;
      ID_EX_rs1 <= rs1;
      ID_EX_rs2 <= rs2;
    end
  end

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(ID_EX_inst),  // input
    .ALUOp(ID_EX_alu_op),
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result)  // output
    //.alu_zero()     // output
  );

  // ---------- MUX ----------
  Mux mux_for_alu(
    .input0(forWard_B_out), //ForwardB?�� mux?�� output
    .input1(ID_EX_imm),
    .signal(ID_EX_alu_src),
    .output_mux(alu_in_2) //id_ex_alu_in_2�? ?��못했?��?��
  );
  

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;
      EX_MEM_mem_read <= 0;
      EX_MEM_mem_to_reg <= 0;
      EX_MEM_reg_write <= 0;

      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
      EX_MEM_is_halted <= 0;
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;
      EX_MEM_mem_read <= ID_EX_mem_read;
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
      EX_MEM_reg_write <= ID_EX_reg_write;

      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= forWard_B_out;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_is_halted <= ID_EX_is_halted;

      // for debugging
      // EX_MEM_inst<=ID_EX_inst;
    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (dmem_dout)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_is_halted <= 0;
      MEM_WB_rd <= 0;
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
      MEM_WB_reg_write <= EX_MEM_reg_write;
      MEM_WB_mem_to_reg_src_1 <= dmem_dout;
      MEM_WB_mem_to_reg_src_2 <= EX_MEM_alu_out;
      MEM_WB_is_halted <= EX_MEM_is_halted;
      MEM_WB_rd <= EX_MEM_rd;

      // for debugging
      // MEM_WB_inst<=EX_MEM_inst;
    end
  end

  // 추가적으로 구현되어 있는 부분
  Mux mux_for_mem_to_reg(
    .input0(MEM_WB_mem_to_reg_src_2),
    .input1(MEM_WB_mem_to_reg_src_1),
    .signal(MEM_WB_mem_to_reg),
    .output_mux(rd_din)
  );

  //hazard part
  HazardDetectionUnit hdu(
    .rs1(rs1), // is_ecall(rs1?�� x17) ?��?��?�� rs1
    .rs2(rs2),
    .id_ex_rd(ID_EX_rd),
    .id_ex_mem_read(ID_EX_mem_read),
    .id_ex_opcode(ID_EX_inst[6:0]),
    .ex_mem_mem_read(EX_MEM_mem_read),
    .ex_mem_rd(EX_MEM_rd),
    .is_ecall(is_ecall),
    .is_hazard(is_hazard)
  );

  //Forwarding part
  ForwardingUnit fu(
    .id_ex_rs1(ID_EX_rs1),
    .id_ex_rs2(ID_EX_rs2),
    .ex_mem_rd(EX_MEM_rd),
    .ex_mem_reg_write(EX_MEM_reg_write),
    .mem_wb_rd(MEM_WB_rd),
    .mem_wb_reg_write(MEM_WB_reg_write),
    .forward_A(forward_A),
    .forward_B(forward_B)
  );

  MuxForForward muxForwardA(
    .input00(ID_EX_rs1_data),
    .input01(EX_MEM_alu_out),
    .input10(rd_din),
    .signal(forward_A),
    .output_mux(alu_in_1)
  );

  MuxForForward muxForwardB(
    .input00(ID_EX_rs2_data),
    .input01(EX_MEM_alu_out),
    .input10(rd_din),
    .signal(forward_B),
    .output_mux(forWard_B_out)
  );

  ForwardingMuxControlUnit fmcu(
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .ex_mem_rd(EX_MEM_rd),
    .is_ecall(is_ecall),
    .mux_rs1_dout(mux_rs1_dout),
    .mux_rs2_dout(mux_rs2_dout)
  );

  MuxForForward mux_for_rs1_dout(
    .input00(rd_din),
    .input01(rs1_dout),
    .input10(EX_MEM_alu_out),
    .signal(mux_rs1_dout),
    .output_mux(f_rs1_dout)
  );
  
  Mux mux_for_rs2_dout(
    .input0(rd_din),
    .input1(rs2_dout),
    .signal(mux_rs2_dout),
    .output_mux(f_rs2_dout)
  );

  
endmodule
