`include "opcodes.v"

module ControlUnit(
    input [6:0] part_of_inst,
    input clk,
    input reset,
    input alu_bcond,
    output pc_write_cond,
    output pc_write,
    output i_or_d,
    output mem_read,
    output mem_write,
    output mem_to_reg,
    output ir_write,
    output pc_source,
    output [1:0] ALUOp,
    output [1:0] alu_src_B,
    output alu_src_A,
    output reg_write,
    output is_ecall);

    reg [3:0] current_state;
    reg [3:0] next_state;
 
    assign pc_write_cond = (current_state == `EX2) && (part_of_inst == `BRANCH);
    assign pc_write = current_state == `WB || (current_state == `MEM4 && part_of_inst == `STORE);
    assign i_or_d = ((current_state == `MEM1)) && (((part_of_inst == `LOAD) || (part_of_inst == `STORE)));
    assign mem_read = (`IF1 <= current_state && current_state <= `IF4) || (( `MEM1 <= current_state && current_state <= `MEM4) && (part_of_inst == `LOAD));
    assign mem_write = (current_state == `MEM1) && (part_of_inst == `STORE); 
    assign mem_to_reg = (current_state == `WB) && ((part_of_inst == `LOAD) || (part_of_inst == `JAL) || (part_of_inst == `JALR));
    assign ir_write = (current_state == `IF4);
    assign pc_source = !((((part_of_inst == `BRANCH) && bcond) || (part_of_inst == `JAL) || (part_of_inst == `JALR)));
    assign ALUOp = (current_state ==`EX2) && ((part_of_inst == `ARITHMETIC) || (part_of_inst == `ARITHMETIC_IMM));
    assign alu_src_B[0] = (current_state == `EX1); 
    assign alu_src_B[1] = (current_state == `EX2 && part_of_inst != `ARITHMETIC);
    assign alu_src_A = ((current_state == `EX2) && (part_of_inst != `JAL) && (part_of_inst != `BRANCH)); 
    assign reg_write = (current_state == `WB) && ((part_of_inst != `STORE) && (part_of_inst != `BRANCH));
    assign is_ecall = (part_of_inst == `ECALL);

    always @(posedge clk) begin
        case(current_state)
            `IF1: begin
                next_state = `IF2;
            end
            `IF2: begin
                next_state = `IF3;
            end
            `IF3: begin
                next_state = `IF4;
            end
            `IF4: begin
                if (part_of_inst == `JAL) begin
                    next_state = `EX1;
                end
                else begin
                    next_state = `ID;
                end
            end
            `ID: begin
                next_state = `EX1;
            end
            `EX1: begin
                next_state = `EX2;
            end
            `EX2: begin
                if (part_of_inst == `BRANCH) begin
                    next_state = `IF1;
                end
                else if (part_of_inst == `ARITHMETIC || part_of_inst == `ARITHMETIC_IMM || part_of_inst == `JAL || part_of_inst == `JALR || part_of_inst == `ECALL) begin
                    next_state = `WB;
                end
                else begin
                    next_state = `MEM1;
                end
            end
            `MEM1: begin
                next_state = `MEM2;
            end
            `MEM2: begin
                next_state = `MEM3;
            end
            `MEM3: begin
                next_state = `MEM4;
            end
            `MEM4: begin
                if (part_of_inst == `LOAD) begin
                    next_state = `WB;
                end
                else if (part_of_inst == `STORE) begin
                    next_state = `IF1;
                end
            end
            `WB: begin
                next_state = `IF1;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            cur_state <= `IF1;
        end
        else begin
            cur_state <= next_state;
        end
    end

endmodule
