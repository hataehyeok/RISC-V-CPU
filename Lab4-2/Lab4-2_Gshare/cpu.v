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


  // for Forwarding
  wire [1:0] forward_A;
  wire [1:0] forward_B;
  wire [31:0] forWard_B_out;

  wire [1:0]mux_rs1_dout;
  wire mux_rs2_dout;

  wire [31:0] f_rs1_dout;
  wire [31:0] f_rs2_dout;

  // with control flow instruction
  wire [31:0] pc_plus_4;
  wire [31:0] write_data; // 기존의 rd_din 대체. MEM_WB_pc_to_reg에 따라 rd_din 또는 MEM_WB_pc_plus_4
  wire is_jal;
  wire is_jalr;
  wire branch;
  wire pc_to_reg;
  wire [31:0] pc_plus_imm;
  wire bcond;

  wire is_flush;
  wire is_miss_pred; // jal, jalr, branch instruction이 EX 단계일 때, ID 단계의 pc가 잘못 예측된 것이 확인된 경우 1
  // wire miss_prediction; // always taken으로 예측한 pc 값이 taken 했을 때 진짜 pc 값이 아닌 경우
  wire [31:0] n_pc; // BTB에서 얻은 n_pc

  wire [4:0] bhsr;

  
  /***** Register declarations *****/
  reg [31:0] correct_pc; // miss_pred 시 정확한 pc 값


  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  
  // with control flow instruction
  reg [31:0] IF_ID_pc_plus_4;
  reg [31:0] IF_ID_pc;
  reg IF_ID_is_flush;

  reg [4:0]IF_ID_bhsr;

  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [1:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_pc_to_reg;      // in WB stage
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_inst;
  reg [4:0] ID_EX_rd;
  reg ID_EX_is_halted;

  // For Forwarding
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;

  // with control flow instruction
  reg [31:0] ID_EX_pc_plus_4;
  reg ID_EX_is_jal;
  reg ID_EX_is_jalr;
  reg ID_EX_branch;
  reg [31:0] ID_EX_pc;
  reg [1:0] pc_src;

  reg [4:0] ID_EX_bhsr;
  

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  // reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_pc_to_reg;      // in WB stage

  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;
  reg EX_MEM_is_halted;

  // with control flow instruction
  reg [31:0] EX_MEM_pc_plus_4;

  // for debugging
  reg [31:0] EX_MEM_inst;


  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_pc_to_reg;      // in WB stage
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;

  reg [4:0] MEM_WB_rd;
  reg MEM_WB_is_halted;

  // with control flow instruction
  reg [31:0] MEM_WB_pc_plus_4;
  

  // for debugging
  reg [31:0] MEM_WB_inst;
  reg test;



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

  // always taken으로 예측하므로 branch&!bcond 인경우(not taken)인 경우도 miss pred
  // assign is_miss_pred=miss_prediction|(ID_EX_branch&!bcond);
  assign is_flush=is_miss_pred;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .pc_write(pc_write),
    .current_pc(current_pc)   // output
  );

  Adder pc_adder(
      .input1(current_pc),
      .input2(4),
      .output_adder(pc_plus_4)
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
      // 초기?���? ?��?��?���??
      IF_ID_inst <=0;
      IF_ID_pc_plus_4<=0;
      IF_ID_pc<=0;
      IF_ID_is_flush<=0;

      IF_ID_bhsr<=0;
    end
    else if(if_id_write) begin
      IF_ID_inst<=instr;
      IF_ID_pc_plus_4<=pc_plus_4;
      IF_ID_pc<=current_pc;
      IF_ID_is_flush<=is_flush;

      IF_ID_bhsr<=bhsr;
    end
    else begin
      // IF_ID_inst<=IF_ID_inst;
    end
  end

  MuxForIsEcall mux_for_is_ecall(
    .input0(rs1_from_inst),
    .input1(5'd17),
    .signal(is_ecall),
    .output_mux(rs1)
  );

  Mux mux_for_write_data(
    .input0(rd_din),
    .input1(MEM_WB_pc_plus_4),
    .signal(MEM_WB_pc_to_reg),
    .output_mux(write_data)
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (rs2),          // input
    .rd (rd),           // input
    .rd_din (write_data),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),  // input
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .branch(branch),
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .reg_write(reg_write),     // output ?��?�� write_enable?��?��?��?�� ?���? 바꿈
    .pc_to_reg(pc_to_reg),
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
    if (reset|is_hazard|is_flush|IF_ID_is_flush) begin
      ID_EX_alu_op<=0;         // will be used in EX stage
      ID_EX_alu_src<=0;        // will be used in EX stage
      ID_EX_mem_write<=0;      // will be used in MEM stage
      ID_EX_mem_read<=0;       // will be used in MEM stage
      ID_EX_mem_to_reg<=0;     // will be used in WB stage
      ID_EX_reg_write<=0;      // will be used in WB stage
      // From others
      ID_EX_rs1_data<=0;
      ID_EX_rs2_data<=0;
      ID_EX_imm<=0;
      ID_EX_inst<=0;
      ID_EX_rd<=0;
      ID_EX_is_halted<=0;
      ID_EX_rs1<=0;
      ID_EX_rs2<=0;

      ID_EX_is_jal<=0;
      ID_EX_is_jalr<=0;
      ID_EX_branch<=0;
      ID_EX_pc_plus_4<=0;
      ID_EX_pc_to_reg<=0;
      ID_EX_pc<=0;

      ID_EX_bhsr<=0;
    end
    else begin
      // From the control unit
      ID_EX_alu_op<=ALUOp;         // will be used in EX stage
      ID_EX_alu_src<=alu_src;        // will be used in EX stage
      ID_EX_mem_write<=mem_write;      // will be used in MEM stage
      ID_EX_mem_read<=mem_read;       // will be used in MEM stage
      ID_EX_mem_to_reg<=mem_to_reg;     // will be used in WB stage
      ID_EX_reg_write<=reg_write;      // will be used in WB stage
      // From others
      ID_EX_rs1_data<=f_rs1_dout;
      ID_EX_rs2_data<=f_rs2_dout;
      ID_EX_imm<=imm_gen_out;
      ID_EX_inst<=IF_ID_inst;
      ID_EX_rd<=IF_ID_inst[11:7];
      ID_EX_is_halted<=_is_halted;
      ID_EX_rs1<=rs1;
      ID_EX_rs2<=rs2;

      ID_EX_is_jal<=is_jal;
      ID_EX_is_jalr<=is_jalr;
      ID_EX_branch<=branch;
      ID_EX_pc_plus_4<=IF_ID_pc_plus_4;
      ID_EX_pc_to_reg<=pc_to_reg;
      ID_EX_pc<=IF_ID_pc;

      ID_EX_bhsr<= IF_ID_bhsr;
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
    .funct3(ID_EX_inst[14:12]),
    .alu_result(alu_result),  // output
    .alu_bcond(bcond)
  );

  Mux mux_for_alu(
    .input0(forWard_B_out), //ForwardB?�� mux?�� output
    .input1(ID_EX_imm),
    .signal(ID_EX_alu_src),
    .output_mux(alu_in_2) //id_ex_alu_in_2�? ?��못했?��?��
  );

  Adder pc_imm_adder(
    .input1(ID_EX_pc),//////
    .input2(ID_EX_imm),
    .output_adder(pc_plus_imm)
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write<=0;
      EX_MEM_mem_read<=0;
      EX_MEM_mem_to_reg<=0;
      EX_MEM_reg_write<=0;

      EX_MEM_alu_out<=0;
      EX_MEM_dmem_data<=0;
      EX_MEM_rd<=0;
      EX_MEM_is_halted<=0;

      EX_MEM_pc_plus_4<=0;
      EX_MEM_pc_to_reg<=0;
    end
    else begin
      EX_MEM_mem_write<=ID_EX_mem_write;
      EX_MEM_mem_read<=ID_EX_mem_read;
      EX_MEM_mem_to_reg<=ID_EX_mem_to_reg;
      EX_MEM_reg_write<=ID_EX_reg_write;

      EX_MEM_alu_out<=alu_result;
      EX_MEM_dmem_data<=forWard_B_out;
      EX_MEM_rd<=ID_EX_rd;
      EX_MEM_is_halted<=ID_EX_is_halted;

      EX_MEM_pc_plus_4<=ID_EX_pc_plus_4;
      EX_MEM_pc_to_reg<=ID_EX_pc_to_reg;

      // for debugging
      EX_MEM_inst<=ID_EX_inst;
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
      MEM_WB_mem_to_reg<=0;
      MEM_WB_reg_write<=0;
      MEM_WB_mem_to_reg_src_1<=0;
      MEM_WB_mem_to_reg_src_2<=0;
      MEM_WB_is_halted<=0;
      MEM_WB_rd<=0;

      MEM_WB_pc_plus_4<=0;
      MEM_WB_pc_to_reg<=0;
    end
    else begin
      MEM_WB_mem_to_reg<=EX_MEM_mem_to_reg;
      MEM_WB_reg_write<=EX_MEM_reg_write;
      MEM_WB_mem_to_reg_src_1<=dmem_dout;
      MEM_WB_mem_to_reg_src_2<=EX_MEM_alu_out;
      MEM_WB_is_halted<=EX_MEM_is_halted;
      MEM_WB_rd<=EX_MEM_rd;

      MEM_WB_pc_plus_4<=EX_MEM_pc_plus_4;
      MEM_WB_pc_to_reg<=EX_MEM_pc_to_reg;

      // for debugging
      MEM_WB_inst<=EX_MEM_inst;
    end
  end

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

  Mux2bit muxForwardA(
    .input00(ID_EX_rs1_data),
    .input01(EX_MEM_pc_to_reg?EX_MEM_pc_plus_4:EX_MEM_alu_out),
    .input10(MEM_WB_pc_to_reg ? MEM_WB_pc_plus_4 : rd_din),
    .signal(forward_A),
    .output_mux(alu_in_1)
  );

  Mux2bit muxForwardB(
    .input00(ID_EX_rs2_data), // id_ex_alu_in_2�? ?��못했?��?��
    .input01(EX_MEM_pc_to_reg?EX_MEM_pc_plus_4:EX_MEM_alu_out),
    .input10(MEM_WB_pc_to_reg ? MEM_WB_pc_plus_4 : rd_din),
    .signal(forward_B),
    .output_mux(forWard_B_out) // alu_in_2�? ?��못했?��?��
  );

  ForwardingMuxControlUnit fmcu(
    .rs1(rs1), // is_ecall(rs1?�� x17) ?��?��?�� rs1
    .rs2(rs2),
    .rd(rd),
    .ex_mem_rd(EX_MEM_rd),
    .is_ecall(is_ecall),
    .mux_rs1_dout(mux_rs1_dout),
    .mux_rs2_dout(mux_rs2_dout)
  );

  Mux2bit mux_for_rs1_dout(
    .input00(MEM_WB_pc_to_reg ? MEM_WB_pc_plus_4 : rd_din),
    .input01(rs1_dout),
    .input10(EX_MEM_pc_to_reg?EX_MEM_pc_plus_4:EX_MEM_alu_out),
    .signal(mux_rs1_dout),
    .output_mux(f_rs1_dout)
  );
  Mux mux_for_rs2_dout(
    .input0(MEM_WB_pc_to_reg ? MEM_WB_pc_plus_4 : rd_din),
    .input1(rs2_dout),
    .signal(mux_rs2_dout),
    .output_mux(f_rs2_dout)
  );

  BTB btb(
    .pc(current_pc),
    .reset(reset),
    .clk(clk),
    .IF_ID_pc(IF_ID_pc),
    .is_jal(ID_EX_is_jal),
    .is_jalr(ID_EX_is_jalr),
    .branch(ID_EX_branch),
    .bcond(bcond),
    .write_pc(ID_EX_pc),
    .pc_plus_imm(pc_plus_imm),
    .reg_plus_imm(alu_result),
    .write_bhsr(ID_EX_bhsr),
    .n_pc(n_pc),
    // .miss_prediction(miss_prediction)
    .bhsr(bhsr)
  );

  MissPredictionDetector msd(
    .IF_ID_pc(IF_ID_pc),
    .ID_EX_is_jal(ID_EX_is_jal),
    .ID_EX_is_jalr(ID_EX_is_jalr),
    .ID_EX_branch(ID_EX_branch),
    .ID_EX_bcond(bcond),
    .ID_EX_pc(ID_EX_pc),
    .pc_plus_imm(pc_plus_imm),
    .reg_plus_imm(alu_result),
    .is_miss_pred(is_miss_pred)
  );

  assign next_pc=is_miss_pred?correct_pc:n_pc;

  // mux part for correct_pc
  always @(*) begin
    if(ID_EX_is_jalr) begin
      correct_pc=alu_result;
    end
    else if(ID_EX_is_jal) begin
      correct_pc=pc_plus_imm;
    end
    else if(ID_EX_branch&bcond) begin
      correct_pc=pc_plus_imm;
    end
    else begin
      correct_pc=ID_EX_pc+4;
    end
  end

  // Mux2bit mux_for_pc(
  //   .input00(pc_plus_4),
  //   .input01(pc_plus_imm),
  //   .input10(alu_result),
  //   .signal(pc_src),
  //   .output_mux(correct_pc)
  // );

  // for debugging
  always @(posedge clk) begin
    // if(ID_EX_inst==32'h0300006f) begin
    //     test<=1'b1;
    // end
    if(ID_EX_pc==32'h70) begin
      test<=1'b1;
    end
  end

  
endmodule