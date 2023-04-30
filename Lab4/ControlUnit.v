`include "opcodes.v"

module ControlUnit(input [6:0] part_of_inst,  // input : opcode
                    // output is_jal,        // output 
                    // output is_jalr,       // output
                    // output branch,        // output
                    output mem_read,      // output
                    output mem_to_reg,    // output
                    output mem_write,     // output
                    output alu_src,       // output
                    output reg_write,     // output : RegWrite
                    // output pc_to_reg,     // output
                    output reg [1:0] alu_op,
                    output is_ecall);      // output (ecall inst)


//   assign is_jal=(part_of_inst==`JAL);
//   assign is_jalr=(part_of_inst==`JALR);
//   assign branch=(part_of_inst==`BRANCH);
  assign mem_read=(part_of_inst==`LOAD);
  assign mem_to_reg=(part_of_inst==`LOAD);
  assign mem_write=(part_of_inst==`STORE); 
  assign alu_src=(part_of_inst==`ARITHMETIC_IMM || part_of_inst==`LOAD || part_of_inst==`JALR || part_of_inst==`STORE);
  assign reg_write=(part_of_inst!=`STORE && part_of_inst!=`BRANCH);
//   assign pc_to_reg=(part_of_inst==`JAL || part_of_inst==`JALR);

  assign is_ecall=(part_of_inst==`ECALL);

  always @(*) begin
      if(part_of_inst==`LOAD||part_of_inst==`STORE||part_of_inst==`JAL||part_of_inst==`JALR) begin
          alu_op = 2'b00; // 무조건 add
      end
      else if(part_of_inst==`BRANCH) begin
          alu_op = 2'b01; // 무조건 sub
      end
      else if(part_of_inst==`ARITHMETIC||part_of_inst==`ARITHMETIC_IMM) begin
          alu_op = 2'b10; // func3와 func7 참조
      end
  end


endmodule