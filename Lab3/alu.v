`include "opcodes.v"

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