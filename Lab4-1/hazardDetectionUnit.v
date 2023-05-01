`include "opcodes.v"

module HazardDetectionUnit (input [4:0] rs1,
                            input [4:0] rs2,
                            input [4:0] id_ex_rd,
                            input id_ex_mem_read,
                            input [6:0] id_ex_opcode,
                            input ex_mem_mem_read,
                            input [4:0]ex_mem_rd,
                            input is_ecall,
                            output reg is_hazard);
    
    always @(*) begin
        //rs1과 rd가 같거나 rs2와 rd가 같은 경우 & mem_read가 1 (바로 이전 instruction이 load instruction)
        if(( (rs1 == id_ex_rd) | (rs2 == id_ex_rd) ) & id_ex_mem_read)
            is_hazard=1;
        // is_ecall 이고 바로 이전 instruction의 rd가 x17인 경우 hazard 해야함
        else if(is_ecall & (id_ex_rd==17)&(id_ex_opcode==`ARITHMETIC|id_ex_opcode==`ARITHMETIC_IMM|id_ex_opcode==`LOAD|id_ex_opcode==`JAL|id_ex_opcode==`JALR)) begin
            is_hazard=1;
        end
        // is_ecall 이고 이전의 이전 instruction이 load instruction이고 rd가 x17인 경우 hazard 해야함
        else if(is_ecall & (ex_mem_mem_read) & (ex_mem_rd==17)) begin
            is_hazard=1;
        end
        else begin
            is_hazard=0;
        end
    end


endmodule