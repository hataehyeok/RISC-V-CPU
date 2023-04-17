`include "opcodes.v"

module PC (input reset,
            input clk,
            input pc_control,
            input [31:0] next_pc,
            output reg [31:0] current_pc);

  always @(posedge clk) begin
    if(reset) begin
      current_pc <= 32'b0;
    end
    else begin
        if(pc_control) begin
            current_pc <= next_pc;
        end
    end
  end
endmodule

module ControlUnit (input [6:0] part_of_inst,
                    input clk,
                    input reset,
                    input alu_bcond,
                    output reg pc_write_cond,
                    output reg pc_write,
                    output reg i_or_d,
                    output reg mem_read,
                    output reg mem_write,
                    output reg mem_to_reg,
                    output reg ir_write,
                    output reg pc_source,
                    output reg [1:0] ALUOp,
                    output reg [1:0] alu_src_B,
                    output reg alu_src_A,
                    output reg reg_write,
                    output is_ecall);
  
  assign is_ecall = (part_of_inst == `ECALL) ? 1 : 0;
  
  reg [5:0] current_state = 0;
  wire [5:0] next_state;    //Predict transfer state of MIPS

  always @(*) begin
        pc_write_cond=0;
        pc_write=0;
        i_or_d=0;
        mem_write=0;
        mem_read=0;
        mem_to_reg=0;
        ir_write=0;
        pc_source=0;
        ALUOp=0;
        alu_src_B=0;
        alu_src_A=0;
        reg_write=0;
        case(cur_state)
            0: begin
                mem_read=1;
                i_or_d=0;
                ir_write=1;
            end
            1: begin
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp =2'b00;
            end
            2: begin
                alu_src_A=1;
                alu_src_B=2'b10;
                ALUOp=2'b00;
            end
            3: begin
                mem_read=1;
                i_or_d=1;
            end
            4: begin
                reg_write=1;
                mem_to_reg=1;
                //
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;                
            end
            5: begin
                mem_write=1;
                i_or_d=1;
                //
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;   
            end
            6: begin
                alu_src_A=1;
                alu_src_B=2'b00;
                ALUOp=2'b10;
            end
            7: begin
                reg_write=1;
                mem_to_reg=0;
                //
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;   
            end
            8: begin
                alu_src_A=1;
                alu_src_B=2'b00;
                ALUOp=2'b01; // branch 일때 ALUOp 01
                // pc_write_cond=1; // branch 일때
                
                pc_source=1; //pc+4 가 ALUOut에 저장되어 있으므로
                pc_write=!alu_bcond;
            end
            9: begin
                alu_src_A=0;
                alu_src_B=2'b10;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;
            end
            10: begin
                mem_to_reg=0;
                reg_write=1;
                //
                alu_src_A=0;
                alu_src_B=2'b10;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;
            end
            11: begin
                mem_to_reg=0;
                reg_write=1;
                //
                alu_src_A=1;
                alu_src_B=2'b10;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;                
            end
            12: begin
                alu_src_A=1;
                alu_src_B=2'b10;
                ALUOp=2'b10;
            end
            13: begin
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;
            end
        endcase
  end

  always @(posedge clk) begin
        if (reset) begin
            cur_state <= 0;
        end
        else begin
            cur_state <= next_state;
        end
  end

  always @(*) begin
        case(cur_state)
            0: begin
                next_state=1;
            end
            1: begin
                case(opcode)
                    `ARITHMETIC: next_state=6;
                    `ARITHMETIC_IMM: next_state=12;
                    `LOAD: next_state=2;
                    `STORE: next_state=2;
                    `BRANCH: next_state=8;
                    `JAL: next_state=10;
                    `JALR: next_state=11;
                    `ECALL: next_state=13;
                endcase
            end
            2: begin
                case(opcode)
                    `LOAD: next_state=3;
                    `STORE: next_state=5;
                endcase
            end
            3: begin
                next_state=4;
            end
            4: begin
                next_state=0;
            end
            5: begin
                next_state=0;
            end
            6: begin
                next_state=7;
            end
            7: begin
                next_state=0;
            end
            8: begin
                if(alu_bcond) begin
                    next_state=9;
                end
                else begin
                    next_state=0;
                end
            end
            9: begin
                next_state=0;
            end
            10: begin
                next_state=0;
            end
            11: begin
                next_state=0;              
            end
            12: begin
                next_state=7;
            end
            13: begin
                next_state=0;
            end
        endcase
    end

endmodule

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
        result = alu_in_1 - alu_in_2;
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

    if(alu_op != `FUNCT_SUB) begin
      bcond = 1'b0;
    end
  end
endmodule