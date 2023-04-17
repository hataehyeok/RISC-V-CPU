`include "opcodes.v"

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
      2'b00: alu_op = `FUNCT_ADD;
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
          `ARITHMETIC_IMM : begin
            alu_op = funct3;
          end
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
    case(alu_op)
      `FUNCT3_ADD: begin
        result = alu_in_1 + alu_in_2;
      end
      `FUNCT_SUB: begin
        result = alu_in_1-alu_in_2;
        case(funct3)
          `FUNCT3_BEQ: begin
            bcond = (result == 32'b0);
          end
          `FUNCT3_BNE: begin
            bcond = (result != 32'b0);
          end
          `FUNCT3_BLT: begin
            bcond = (result[31] == 1'b1);
          end
          `FUNCT3_BGE: begin
            bcond = (result[31] != 1'b1);
          end
          default:
            bcond = 1'b0;
        endcase
      end
      `FUNCT3_SLL: begin
        result = alu_in_1 << alu_in_2;
      end
      `FUNCT3_XOR: begin
        result = alu_in_1 ^ alu_in_2;
      end
      `FUNCT3_OR: begin
        result = alu_in_1 | alu_in_2;
      end
      `FUNCT3_AND: begin
        result = alu_in_1 & alu_in_2;
      end
      `FUNCT3_SRL: begin
        result = alu_in_1 >> alu_in_2;
      end
      default: begin
        result = 0;
      end
    endcase

    if(alu_op!=`FUNCT_SUB) begin
      bcond = 1'b0;
    end

  end

endmodule