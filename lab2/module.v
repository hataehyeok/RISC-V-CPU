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
  
  reg opcode;
  reg [31:0] temp;
  assign imm_gen_out = temp;

  always @(*) begin
    opcode = part_of_inst[6:0];
    case (opcode)
      `ARITHMETIC_IMM, `LOAD, `JALR: begin // I-type
        temp = $signed(inst[31:20]);
      end
      `STORE: begin // S-type
        temp = $signed({inst[31:25], inst[11:7]});
      end
      `BRANCH: begin // B-type
        temp = $signed({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0});
      end
      `JAL: begin // J-type
        temp = $signed({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0});
      end
      default: begin
        temp = 32'b0;
      end
    endcase
  end
endmodule

module ALUControlUnit (input [31:0] part_of_inst, output [2:0] alu_op);
  
  wire [6:0] opcode = part_of_inst[6:0];
  wire [2:0] func3 = part_of_inst[14:12];
  wire [6:0] func7 = part_of_inst[31:25];
  wire isBranch = (opcode == `BRANCH) ? 1 : 0;

	always @(*) begin
		if(opcode == `ARITHMETIC) begin
			if(funct3 == `FUNCT3_ADD && funct7 == `FUNCT7_OTHERS) FuncCodeReg = `FUNC_ADD;
			else if(funct3 == `FUNCT3_ADD && funct7 == `FUNCT7_SUB) FuncCodeReg = `FUNC_SUB;
			else if(funct3 == `FUNCT3_SLL) FuncCodeReg = `FUNC_LLS;
			else if(funct3 == `FUNCT3_XOR) FuncCodeReg = `FUNC_XOR;
			else if(funct3 == `FUNCT3_OR) FuncCodeReg = `FUNC_OR;
			else if(funct3 == `FUNCT3_AND) FuncCodeReg = `FUNC_AND;
			else if(funct3 == `FUNCT3_SRL) FuncCodeReg = `FUNC_LRS;
		end
		else if(opcode == `ARITHMETIC_IMM) begin
			if(funct3 == `FUNCT3_ADD) FuncCodeReg = `FUNC_ADD;
			else if(funct3 == `FUNCT3_SLL) FuncCodeReg = `FUNC_LLS;
			else if(funct3 == `FUNCT3_XOR) FuncCodeReg = `FUNC_XOR;
			else if(funct3 == `FUNCT3_OR) FuncCodeReg = `FUNC_OR;
			else if(funct3 == `FUNCT3_AND) FuncCodeReg = `FUNC_AND;
			else if(funct3 == `FUNCT3_SRL) FuncCodeReg = `FUNC_LRS;
		end
		else if(opcode == `LOAD) FuncCodeReg = `FUNC_ADD;
		else if(opcode == `STORE) FuncCodeReg = `FUNC_ADD;
		else if(opcode == `BRANCH) begin
			if(funct3 == `FUNCT3_BEQ) FuncCodeReg = `FUNC_BEQ;
			else if (funct3 == `FUNCT3_BNE) FuncCodeReg = `FUNC_BNE;
			else if (funct3 == `FUNCT3_BLT) FuncCodeReg = `FUNC_BLT;
			else if (funct3 == `FUNCT3_BGE) FuncCodeReg = `FUNC_BGE;
		end
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
      'FUNCT3_ADD: begin
        result = alu_in_1 + alu_in_2;
        bcond = 1'b0;
      end
      3'b010: begin
        result = alu_in_1-alu_in_2;
        case(func3)
          'FUNCT3_BEQ: begin
            bcond = (result == 32'b0);
          end
          'FUNCT3_BNE: begin
            bcond = (result != 32'b0);
          end
          'FUNCT3_BLT: begin
            bcond = (result[31] == 1'b1);
          end
          'FUNCT3_BGE: begin
            bcond = (result[31] != 1'b0);
          end
          default:
            bcond = 1'b0;
        endcase
      end
      'FUNCT3_SLL: begin
        result = alu_in_1 << alu_in_2;
        bcond = 1'b0;
      end
      'FUNCT3_XOR: begin
        result = alu_in_1 ^ alu_in_2;
        bcond = 1'b0;
      end
      'FUNCT3_OR: begin
        result = alu_in_1 | alu_in_2;
        bcond = 1'b0;
      end
      'FUNCT3_AND: begin
        result = alu_in_1 & alu_in_2;
        bcond = 1'b0;
      end
      'FUNCT3_SRL: begin
        result = alu_in_1 >> alu_in_2;
        bcond = 1'b0;
      end
      default: begin
        result = 0;
        bcond = 1'b0;
      end
    endcase
  end

endmodule