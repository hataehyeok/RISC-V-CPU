`include "opcodes.v"

module PC (input reset, input clk, input [31:0] next_pc, output [31:0] current_pc);

  reg [31:0] pc;
  assgin current_pc = pc;

  always @(posedge clk) begin
    if(reset) begin
      pc <= 32'b0;
    end
    else begin
      pc <= next_pc;
    end
  end

endmodule

module ControlUnit (input [6:0] part_of_inst,
                    output is_jar,
                    output is_jalr,
                    output branch,
                    output mem_read,
                    output mem_to_reg,
                    output mem_write,
                    output alu_src,
                    output write_enable,
                    output pc_to_reg,
                    output is_ecall);
  
  // always@(*) begin
  //   is_jal = 0;
  //   is_jalr = 0;
  //   branch = 0;
  //   mem_read = 0;
  //   mem_to_reg = 0;
  //   mem_write = 0;
  //   alu_src = 0;
  //   reg_write = 0;
  //   pc_to_reg = 0;
  //   is_ecall = 0;

  //   case (part_of_inst)
  //     `ARITHMETIC : begin
  //       reg_write = 1;
  //     end
  //     `ARITHMETIC_IMM : begin
  //         reg_write = 1;
  //         alu_src = 1;
  //     end
  //     `LOAD: begin
  //       reg_write = 1;
  //       mem_read = 1;
  //       mem_to_reg = 1;
  //       alu_src = 1;
  //     end
  //     `JALR: begin
  //       reg_write = 1; 
  //       is_jalr = 1;
  //       alu_src = 1;
  //       pc_to_reg = 1;
  //     end
  //     `STORE: begin
  //       mem_write = 1;
  //       alu_src = 1;
  //     end
  //     `BRANCH: begin
  //       branch = 1;
  //     end
  //     `JAL: begin
  //       is_jal = 1;
  //       reg_write=1;
  //       pc_to_reg = 1;
  //     end
  //     `ECALL: begin 
  //       is_ecall = 1;
  //     end
  //     default:begin

  //     end
  //   endcase
  // end
  assign is_jalr = (part_of_inst == `JALR) ? 1 : 0;
  assign is_jal = (part_of_inst == `JAL) ? 1 : 0;
  assign branch = (part_of_inst == `BRANCH) ? 1 : 0;
  assign mem_read = (part_of_inst == `LOAD) ? 1 : 0;
  assign mem_to_reg = (part_of_inst == `LOAD) ? 1 : 0;
  assign mem_write = (part_of_inst == `STORE) ? 1 : 0;
  assign alu_src = (part_of_inst != `ARITHMETIC && part_of_inst != `BRANCH) ? 1 : 0;
  assign write_enable = ((part_of_inst != `STORE) && (part_of_inst != `BRANCH)) ? 1 : 0; 
  assign pc_to_reg = (part_of_inst == `JAL || part_of_inst == `JALR) ? 1: 0;
  assign is_ecall = (part_of_inst == `ECALL) ? 1 : 0;

endmodule


module ImmediateGenerator(input [31:0] part_of_inst,
                          output [31:0] imm_gen_out);


endmodule

module ALUControlUnit (input [31:0] part_of_inst, output [2:0] alu_op);
  
  wire [6:0] opcode;
  wire [2:0] func3;
  wire [6:0] func7;


endmodule

module ALU (input [2:0] alu_op,
            input [31:0] alu_in_1,
            input [31:0] alu_in_2,
            input [2:0] funct3,
            output [31:0] alu_result,
            output alu_bcond);

  reg [31:0] result;
  reg bcond;

  assign alu_result = result;
  assign alu_bcond = bcond;

  always @(*) begin
    
  end


endmodule