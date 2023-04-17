`include "opcodes.v"
`include "FiniteState.v"

module ControlUnit(
    input [6:0] part_of_inst,
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

    reg [3:0] cur_state = `IF;
    wire [3:0] next_state;

    
    assign is_ecall=(part_of_inst==`ECALL);

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
            `IF: begin
                mem_read=1;
                i_or_d=0;
                ir_write=1;

            end
            `ID: begin
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp =2'b00;
            end
            `EX_LDSD: begin
                alu_src_A=1;
                alu_src_B=2'b10;
                ALUOp=2'b00;
            end
            `MEM_LD: begin
                mem_read=1;
                i_or_d=1;
            end
            `ID: begin
                reg_write=1;
                mem_to_reg=1;
                //
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;                
            end
            `EX1: begin
                mem_write=1;
                i_or_d=1;
                //
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;   
            end
            `EX2: begin
                alu_src_A=1;
                alu_src_B=2'b00;
                ALUOp=2'b10;
            end
            `MEM1: begin
                reg_write=1;
                mem_to_reg=0;
                //
                alu_src_A=0;
                alu_src_B=2'b01;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;   
            end
            `MEM2: begin
                alu_src_A=1;
                alu_src_B=2'b00;
                ALUOp=2'b01; // branch 일때 ALUOp 01
                // pc_write_cond=1; // branch 일때
                
                pc_source=1; //pc+4 가 ALUOut에 저장되어 있으므로
                pc_write=!alu_bcond;
            end
            `MEM3: begin
                alu_src_A=0;
                alu_src_B=2'b10;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;
            end
            `MEM4: begin
                mem_to_reg=0;
                reg_write=1;
                //
                alu_src_A=0;
                alu_src_B=2'b10;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;
            end
            `WB: begin
                mem_to_reg=0;
                reg_write=1;
                //
                alu_src_A=1;
                alu_src_B=2'b10;
                ALUOp=2'b00;
                pc_write=1;
                pc_source=0;                
            end
            `AM: begin
                alu_src_A=1;
                alu_src_B=2'b10;
                ALUOp=2'b10;
            end
            `EC: begin
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
            cur_state <= `IF;
        end
        else begin
            cur_state <= next_state;
        end
    end

    MicroStateMachine msm(
        .part_of_inst(part_of_inst),
        .clk(clk),
        .reset(reset),
        .alu_bcond(alu_bcond),
        .cur_state(cur_state),
        .next_state(next_state)
    );

endmodule

module MicroStateMachine (input [6:0] part_of_inst,
                        input clk,
                        input reset,
                        input alu_bcond,
                        input [3:0] cur_state,
                        output reg [3:0] next_state);
    always @(*) begin
        case(cur_state)
            `IF: begin
                next_state=`ID;
            end
            `ID: begin
                case(part_of_inst)
                    `ARITHMETIC: next_state=`EX2;
                    `ARITHMETIC_IMM: next_state=`AM;
                    `LOAD: next_state=`EX_LDSD;
                    `STORE: next_state=`EX_LDSD;
                    `BRANCH: next_state=`MEM2;
                    `JAL: next_state=`MEM4;
                    `JALR: next_state=`WB;
                    `ECALL: next_state=`EC;
                endcase
            end
            `EX_LDSD: begin
                case(part_of_inst)
                    `LOAD: next_state=`MEM_LD;
                    `STORE: next_state=`EX1;
                endcase
            end
            `MEM_LD: begin
                next_state=`ID;
            end
            `ID: begin
                next_state=`IF;
            end
            `EX1: begin
                next_state=`IF;
            end
            `EX2: begin
                next_state=`MEM1;
            end
            `MEM1: begin
                next_state=`IF;
            end
            `MEM2: begin
                if(alu_bcond) begin
                    next_state=`MEM3;
                end
                else begin
                    next_state=`IF;
                end
            end
            `MEM3: begin
                next_state=`IF;
            end
            `MEM4: begin
                next_state=`IF;
            end
            `WB: begin
                next_state=`IF;
            end
            `AM: begin
                next_state=`MEM1;
            end
            `EC: begin
                next_state=`IF;
            end
        endcase
    end

endmodule




