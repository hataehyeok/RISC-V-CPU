`include "opcodes.v"

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

    reg [5:0] cur_state=0;
    wire [5:0] next_state;

    
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
            0: begin
                mem_read=1;
                i_or_d=0;
                ir_write=1;

                // alu_src_A=0;
                // alu_src_B =2'b01;
                // ALUOp =2'b00;
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
            cur_state<=0;
        end
        else begin
            cur_state<=next_state;
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
                        input [5:0] cur_state,
                        output reg [5:0] next_state);
    always @(*) begin
        case(cur_state)
            0: begin
                next_state=1;
            end
            1: begin
                case(part_of_inst)
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
                case(part_of_inst)
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




