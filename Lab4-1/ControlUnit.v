`include "opcodes.v"
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
// module ControlUnit (
//     part_of_inst, mem_read,
//     mem_to_reg, mem_write, alu_src, write_enable, pc_to_reg, alu_op, is_ecall);

//     input wire[6:0] part_of_inst;

//     output reg mem_read;
//     output reg mem_to_reg;
//     output reg mem_write;
//     output reg alu_src;
//     output reg write_enable;
//     output reg pc_to_reg;
//     output reg [6:0] alu_op;
//     output reg is_ecall;

//     always @(*) begin
//         alu_op <= part_of_inst;

//         if (part_of_inst==`LOAD) begin  //MemRead
//             mem_read<=1;
//             mem_to_reg<=1;
//             mem_write<=0;
//             alu_src<=1;
//             write_enable<=1;
//             pc_to_reg<=0;
//             is_ecall<=0;     
//             //$display("LOAD used\n");
//         end

//         else if (part_of_inst==`STORE) begin  //MemWrite
//             mem_read<=0;
//             mem_to_reg<=0;
//             mem_write<=1;
//             alu_src<=1;
//             write_enable<=0;
//             pc_to_reg<=0;
//             is_ecall<=0;               
//             //$display("STORE used\n");
//         end

//         else if (part_of_inst==`ARITHMETIC) begin
//             mem_read<=0;
//             mem_to_reg<=0;
//             mem_write<=0;
//             alu_src<=0;
//             write_enable<=1;
//             pc_to_reg<=0;
//             is_ecall<=0;               
//             //$display("ARITHMETIC used\n");
//         end

//         else if (part_of_inst==`ARITHMETIC_IMM) begin
//             mem_read<=0;
//             mem_to_reg<=0;
//             mem_write<=0;
//             alu_src<=1;
//             write_enable<=1;
//             pc_to_reg<=0;
//             is_ecall<=0;               
//             //$display("ARITHMETIC_IMM used\n");
//         end

// 	    else if (part_of_inst==`ECALL) begin
//             mem_read<=0;
//             mem_to_reg<=0;
//             mem_write<=0;
//             alu_src<=0;
//             write_enable<=0;
//             pc_to_reg<=0;
//             is_ecall<=1;   
//             //$display("ECALL used\n");
//         end
//     end
// endmodule