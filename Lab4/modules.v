`include "opcodes.v"

//Mux Module(1 bit)
// module onebitMUX(input [31:0] inA,
//                  input [31:0] inB,
//                  input select,
//                  output [31:0] out);
//   assign out = select ? inA : inB;
// endmodule
module Mux(input [31:0] input0,
            input [31:0] input1,
            input signal,
            output reg [31:0] output_mux);
    always @(*) begin
        if(signal) begin
            output_mux=input1;
        end
        else begin
            output_mux=input0;
        end
    end
endmodule

//Mux Module(2 bit)
module twobitMUX(input [31:0] inA,
                 input [31:0] inB,
                 input [31:0] inC,
                 input [31:0] inD,
                 input [1:0] select,
                 output reg [31:0] out);
  always @(*) begin
    case(select)
      2'b00: begin
        out = inA;
      end
      2'b01: begin
        out = inB;
      end
      2'b10: begin
        out = inC;
      end
      default begin
        out = inD;
      end
    endcase
  end
endmodule

module MuxForIsEcall(input [4:0] input0,
                    input [4:0] input1,
                    input signal,
                    output reg [4:0] output_mux);
    always @(*) begin
        if(signal) begin
            output_mux=input1;
        end
        else begin
            output_mux=input0;
        end
    end
endmodule

module MuxForForward(input [31:0] input00,
                    input [31:0] input01,
                    input [31:0] input10,
                    input [1:0] signal,
                    output reg [31:0] output_mux);
    always @(*) begin
        if(signal==2'b00) begin
            output_mux=input00;
        end
        else if(signal==2'b01) begin
            output_mux=input01;
        end
        else if(signal==2'b10) begin
            output_mux=input10;
        end
    end
endmodule

//Program Counter Module
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
module ImmediateGenerator(input [31:0] part_of_inst,
                          output [31:0] imm_gen_out);

  wire [6:0] opcode = part_of_inst[6:0];
  reg [31:0] imm_gen;

  assign imm_gen_out = imm_gen;

  always @(*) begin
    if(opcode==`ARITHMETIC_IMM || opcode==`LOAD || opcode==`JALR) begin // I-type
      imm_gen = {{21{part_of_inst[31]}}, part_of_inst[30:20]};
    end

    else if(opcode==`STORE) begin // S-type
      imm_gen = {{21{part_of_inst[31]}}, part_of_inst[30:25], part_of_inst[11:7]};
    end

    else if(opcode==`BRANCH) begin // B-type
      imm_gen = {{20{part_of_inst[31]}}, part_of_inst[7], part_of_inst[30:25], part_of_inst[11:8], 1'b0};
    end

    else if(opcode==`JAL) begin // J-type
      imm_gen = {{12{part_of_inst[31]}}, part_of_inst[19:12], part_of_inst[20], part_of_inst[30:25], part_of_inst[24:21], 1'b0};
    end
    else begin
      imm_gen = 32'b0;
    end

  end


endmodule

//ALU Control Module
module ALUControlUnit (input [31:0] part_of_inst,
                       input [1:0] ALUOp,
                       output reg [2:0] alu_op);
  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;

  assign opcode = part_of_inst[6:0];
  assign funct3 = part_of_inst[14:12];
  assign funct7 = part_of_inst[31:25];

  always @(*) begin
    case(ALUOp)
      2'b00: alu_op = `FUNCT3_ADD;
      2'b01: alu_op = `FUNCT_SUB;
      2'b10: begin
        case(opcode)
          `ARITHMETIC : begin
            case(funct7)
              `FUNCT7_SUB : begin
                alu_op = `FUNCT_SUB;
              end
              default : begin
                alu_op = funct3;
              end
            endcase
          end
          `ARITHMETIC_IMM : alu_op = funct3;
          `LOAD : alu_op = `FUNCT3_ADD;
          `STORE : alu_op = `FUNCT3_ADD;
          `JALR : alu_op = `FUNCT3_ADD;
          `BRANCH : alu_op = `FUNCT_SUB;
          default : alu_op = 3'b000;
        endcase
      end
      default: alu_op = 3'b000;
    endcase
  end
endmodule

//ALU Module
module ALU (input [2:0] alu_op,
            input [31:0] alu_in_1,
            input [31:0] alu_in_2,
            input [2:0] funct3,
            output reg [31:0] alu_result,
            output reg alu_bcond);

  always @(*) begin
    case(alu_op)
      `FUNCT3_ADD: begin
        alu_result = alu_in_1 + alu_in_2;
      end
      `FUNCT_SUB: begin
        alu_result = alu_in_1 - alu_in_2;
        case(funct3)
          `FUNCT3_BEQ: begin
            alu_bcond = (alu_result == 32'b0);
          end
          `FUNCT3_BNE: begin
            alu_bcond = (alu_result != 32'b0);
          end
          `FUNCT3_BLT: begin
            alu_bcond = (alu_result[31] == 1'b1);
          end
          `FUNCT3_BGE: begin
            alu_bcond = (alu_result[31] != 1'b1);
          end
          default:
            alu_bcond = 1'b0;
        endcase
      end
      `FUNCT3_SLL: begin
        alu_result = alu_in_1 << alu_in_2;
      end
      `FUNCT3_XOR: begin
        alu_result = alu_in_1 ^ alu_in_2;
      end
      `FUNCT3_OR: begin
        alu_result = alu_in_1 | alu_in_2;
      end
      `FUNCT3_AND: begin
        alu_result = alu_in_1 & alu_in_2;
      end
      `FUNCT3_SRL: begin
        alu_result = alu_in_1 >> alu_in_2;
      end
      default: begin
        alu_result = 0;
      end
    endcase

    if(alu_op != `FUNCT_SUB) begin
      alu_bcond = 1'b0;
    end
  end
endmodule