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


endmodule