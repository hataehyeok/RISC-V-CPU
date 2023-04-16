`include "opcodes.v"

module ImmediateGenerator(input [31:0] part_of_inst,
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