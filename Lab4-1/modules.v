
//Program Counter Module
// module PC (input reset,
//            input clk,
//            input pc_control,
//            input [31:0] next_pc,
//            output reg [31:0] current_pc);

//   always @(posedge clk) begin
//     if(reset) begin
//       current_pc <= 0;
//     end
//     else begin
//         if(pc_control) begin
//             current_pc <= next_pc;
//         end
//     end
//   end
// endmodule

module PC (input reset,
            input clk,
            input [31:0] next_pc,
            input pc_write,
            output [31:0] current_pc);
  
  reg [31:0] pc;

  assign current_pc = pc;
  


  always @(posedge clk) begin
    if(reset) begin
      pc <= 32'b0;
    end
    else if(pc_write) begin
      pc <= next_pc;
    end
    else begin
      // pc <= pc;
    end
  end
endmodule

module Adder (input [31:0] input1, input [31:0] input2, output [31:0] output_adder);
    assign output_adder=input1+input2;
endmodule


//Immediate Generator Module
module ImmediateGenerator (input [31:0] part_of_inst,
                           output reg [31:0] imm_gen_out);
  always @(*) begin
    case (part_of_inst[6:0])
      `ARITHMETIC_IMM, `LOAD, `JALR: begin // I-type
        imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:20]};
      end
      `STORE: begin // S-type
        imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:25], part_of_inst[11:7]};
      end
      `BRANCH: begin // B-type
        imm_gen_out = {{20{part_of_inst[31]}}, part_of_inst[7], part_of_inst[30:25], part_of_inst[11:8], 1'b0};
      end
      `JAL: begin // J-type
        imm_gen_out = {{12{part_of_inst[31]}}, part_of_inst[19:12], part_of_inst[20], part_of_inst[30:25], part_of_inst[24:21], 1'b0};
      end
      default: begin
        imm_gen_out = 32'b0;
      end
    endcase
  end
endmodule

//ALU Control Module
// module ALUControlUnit (input [31:0] part_of_inst,
//                        input [1:0] ALUOp,
//                        output reg [2:0] alu_op);
//   wire [6:0] opcode;
//   wire [2:0] funct3;
//   wire [6:0] funct7;

//   assign opcode = part_of_inst[6:0];
//   assign funct3 = part_of_inst[14:12];
//   assign funct7 = part_of_inst[31:25];

//   always @(*) begin
//     case(ALUOp)
//       2'b00: alu_op = `FUNCT3_ADD;
//       2'b01: alu_op = `FUNCT_SUB;
//       2'b10: begin
//         case(opcode)
//           `ARITHMETIC : begin
//             case(funct7)
//               `FUNCT7_SUB : begin
//                 alu_op = `FUNCT_SUB;
//               end
//               default : begin
//                 alu_op = funct3;
//               end
//             endcase
//           end
//           `ARITHMETIC_IMM : alu_op = funct3;
//           `LOAD : alu_op = `FUNCT3_ADD;
//           `STORE : alu_op = `FUNCT3_ADD;
//           `JALR : alu_op = `FUNCT3_ADD;
//           `BRANCH : alu_op = `FUNCT_SUB;
//           default : alu_op = 3'b000;
//         endcase
//       end
//       default: alu_op = 3'b000;
//     endcase
//   end
// endmodule

// //ALU Module
// module ALU (input [2:0] alu_op,
//             input [31:0] alu_in_1,
//             input [31:0] alu_in_2,
//             input [2:0] funct3,
//             output reg [31:0] alu_result,
//             output reg alu_bcond);

//   always @(*) begin
//     case(alu_op)
//       `FUNCT3_ADD: begin
//         alu_result = alu_in_1 + alu_in_2;
//       end
//       `FUNCT_SUB: begin
//         alu_result = alu_in_1 - alu_in_2;
//         case(funct3)
//           `FUNCT3_BEQ: begin
//             alu_bcond = (alu_result == 32'b0);
//           end
//           `FUNCT3_BNE: begin
//             alu_bcond = (alu_result != 32'b0);
//           end
//           `FUNCT3_BLT: begin
//             alu_bcond = (alu_result[31] == 1'b1);
//           end
//           `FUNCT3_BGE: begin
//             alu_bcond = (alu_result[31] != 1'b1);
//           end
//           default:
//             alu_bcond = 1'b0;
//         endcase
//       end
//       `FUNCT3_SLL: begin
//         alu_result = alu_in_1 << alu_in_2;
//       end
//       `FUNCT3_XOR: begin
//         alu_result = alu_in_1 ^ alu_in_2;
//       end
//       `FUNCT3_OR: begin
//         alu_result = alu_in_1 | alu_in_2;
//       end
//       `FUNCT3_AND: begin
//         alu_result = alu_in_1 & alu_in_2;
//       end
//       `FUNCT3_SRL: begin
//         alu_result = alu_in_1 >> alu_in_2;
//       end
//       default: begin
//         alu_result = 0;
//       end
//     endcase

//     if(alu_op != `FUNCT_SUB) begin
//       alu_bcond = 1'b0;
//     end
//   end
// endmodule
module ALUControlUnit (input [31:0] part_of_inst, input[1:0] ALUOp, output [2:0] alu_op);
  wire [6:0] opcode;
  wire [2:0] func3;
  wire [6:0] func7;

  reg [2:0] op;

  assign alu_op = op;

  assign opcode = part_of_inst[6:0];
  assign func3 = part_of_inst[14:12];
  assign func7 = part_of_inst[31:25];

  always @(*) begin
    if(ALUOp==2'b00) begin // add
        op=`FUNCT_ADD;
    end
    else if(ALUOp==2'b01) begin // sub <- branch 일 때 커버
        op=`FUNCT_SUB;
    end
    else begin // ALUOp==2'b10 일 때를 모두 커버
        if (opcode==`ARITHMETIC) begin
            if (func7==`FUNCT7_SUB) begin // R-type
                op = `FUNCT_SUB;
            end
            else begin
                op = func3; 
            end
        end
        else if (opcode==`ARITHMETIC_IMM) begin // I-type 중 imm
            op = func3;
        end
        // else if (opcode==`LOAD || opcode==`STORE || opcode==`JALR) begin
        // op = `FUNCT_ADD;
        // end
        // else if (opcode==`BRANCH) begin
        // op = `FUNCT_SUB;
        // end
        else begin
            op = 3'b000; //
        end
    end
    
  end


endmodule

module ALU (input [2:0] alu_op,
            input [31:0] alu_in_1,
            input [31:0] alu_in_2,
            // input [2:0] funct3,
            output [31:0] alu_result
            // output alu_bcond
            );

  reg [31:0] result;
//   reg bcond;

  assign alu_result = result;
//   assign alu_bcond = bcond;

  always @(*) begin
    case(alu_op)
      `FUNCT_ADD: begin
        result = alu_in_1 + alu_in_2;
        // bcond = 1'b0;
      end
      `FUNCT_SUB: begin
        result = alu_in_1 - alu_in_2;
        // case(funct3)
        //   `FUNCT3_BEQ: begin
        //     bcond = (result == 32'b0);
        //   end
        //   `FUNCT3_BNE: begin
        //     bcond = (result != 32'b0);
        //   end
        //   `FUNCT3_BLT: begin
        //     bcond = (result[31] == 1'b1);
        //   end
        //   `FUNCT3_BGE: begin
        //     bcond = (result[31] != 1'b1);
        //   end
        //   default: bcond = 1'b0;
        // endcase
      end
      `FUNCT_SLL: begin
        result = alu_in_1 << alu_in_2;
        // bcond = 1'b0;
      end
      `FUNCT_XOR: begin
        result = alu_in_1 ^ alu_in_2;
        // bcond = 1'b0;
      end
      `FUNCT_OR: begin
        result = alu_in_1 | alu_in_2;
        // bcond = 1'b0;
      end
      `FUNCT_AND: begin
        result = alu_in_1 & alu_in_2;
        // bcond = 1'b0;
      end
      `FUNCT_SRL: begin
        result = alu_in_1 >> alu_in_2;
        // bcond = 1'b0;
      end

      default: begin
        result = 0;
        // bcond = 1'b0;
      end

    endcase
      
  end
endmodule