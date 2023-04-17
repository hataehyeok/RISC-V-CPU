`include "opcodes.v"
`include "FiniteState.v"

module ControlUnit(
    input [6:0] part_of_inst,
    input clk,
    input reset,
    input alu_bcond,
    output reg pcWrite_cond,
    output reg pcWrite,
    output reg IorD,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg IRWrite,
    output reg PCSource,
    output reg [1:0] ALUOp,
    output reg [1:0] ALUSrcB,
    output reg ALUSrcA,
    output reg reg_write,
    output is_ecall);

    reg [3:0] current_state = `IF;
    wire [3:0] next_state;

    assign is_ecall = (part_of_inst == `ECALL);

    always @(*) begin
        pcWrite_cond = 0;
        pcWrite = 0;
        IorD = 0;
        mem_write = 0;
        mem_read = 0;
        mem_to_reg = 0;
        IRWrite = 0;
        PCSource = 0;
        ALUOp = 0;
        ALUSrcB = 0;
        ALUSrcA = 0;
        reg_write = 0;

        case (current_state)
            `IF: begin
                mem_read = 1;
                IorD = 0;
                IRWrite = 1;
            end
            `ID: begin
                ALUSrcA = 0;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
            end
            `EX_R: begin
                ALUSrcA = 1;
                ALUSrcB = 2'b00;
                ALUOp = 2'b10;
            end
            `EX_LDSD: begin
                ALUSrcA = 1;
                ALUSrcB = 2'b10;
                ALUOp = 2'b00;
            end
            `EX_B: begin
                ALUSrcA = 1;
                ALUSrcB = 2'b00;
                ALUOp = 2'b01;
                PCSource = 1;
                pcWrite = !alu_bcond;
            end
            `EX_JAL: begin
                mem_to_reg = 0;
                reg_write = 1;
                ALUSrcA = 0;
                ALUSrcB = 2'b10;
                ALUOp = 2'b00;
                pcWrite = 1;
                PCSource = 0;
            end
            `EX_JALR: begin
                mem_to_reg = 0;
                reg_write = 1;
                ALUSrcA = 1;
                ALUSrcB = 2'b10;
                ALUOp = 2'b00;
                pcWrite = 1;
                PCSource = 0;                
            end
            `MEM_R: begin
                reg_write = 1;
                mem_to_reg = 0;
                ALUSrcA = 0;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
                pcWrite = 1;
                PCSource = 0;   
            end
            `MEM_LD: begin
                mem_read = 1;
                IorD = 1;
            end
            `MEM_SD: begin
                mem_write = 1;
                IorD = 1;
                ALUSrcA = 0;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
                pcWrite = 1;
                PCSource = 0;   
            end
            `MEM_B: begin
                ALUSrcA = 0;
                ALUSrcB = 2'b10;
                ALUOp = 2'b00;
                pcWrite = 1;
                PCSource = 0;
            end
            `WB_LD: begin
                reg_write = 1;
                mem_to_reg = 1;
                ALUSrcA = 0;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
                pcWrite = 1;
                PCSource = 0;                
            end
            `AM: begin
                ALUSrcA = 1;
                ALUSrcB = 2'b10;
                ALUOp = 2'b10;
            end
            `EC: begin
                ALUSrcA = 0;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
                pcWrite = 1;
                PCSource = 0;
            end
        endcase
    end

    MicrocodeController MC(
        .part_of_inst(part_of_inst),
        .alu_bcond(alu_bcond),
        .current_state(current_state),
        .next_state(next_state));

    always @(posedge clk) begin
        if (reset) begin
            current_state <= `IF;
        end
        else begin
            current_state <= next_state;
        end
    end

endmodule

module MicrocodeController (
    input [6:0] part_of_inst,
    input alu_bcond,
    input [3:0] current_state,
    output reg [3:0] next_state);

    always @(*) begin
        case(current_state)
            `IF: begin
                next_state = `ID;
            end
            `ID: begin
                case(part_of_inst)
                    `ARITHMETIC: next_state = `EX_R;
                    `ARITHMETIC_IMM: next_state = `AM;
                    `LOAD: next_state = `EX_LDSD;
                    `STORE: next_state = `EX_LDSD;
                    `BRANCH: next_state = `EX_B;
                    `JAL: next_state = `EX_JAL;
                    `JALR: next_state = `EX_JALR;
                    `ECALL: next_state = `EC;
                endcase
            end
            `EX_LDSD: begin
                case(part_of_inst)
                    `LOAD: next_state = `MEM_LD;
                    `STORE: next_state = `MEM_SD;
                endcase
            end
            `MEM_LD: begin
                next_state = `WB_LD;
            end
            `WB_LD: begin
                next_state = `IF;
            end
            `MEM_SD: begin
                next_state = `IF;
            end
            `EX_R: begin
                next_state = `MEM_R;
            end
            `MEM_R: begin
                next_state = `IF;
            end
            `EX_B: begin
                if(alu_bcond) begin
                    next_state = `MEM_B;
                end
                else begin
                    next_state = `IF;
                end
            end
            `MEM_B: begin
                next_state = `IF;
            end
            `EX_JAL: begin
                next_state = `IF;
            end
            `EX_JALR: begin
                next_state = `IF;
            end
            `AM: begin
                next_state = `MEM_R;
            end
            `EC: begin
                next_state = `IF;
            end
        endcase
    end

endmodule




