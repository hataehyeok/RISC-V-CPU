module ForwardingUnit (input [4:0] rs1,
                        input [4:0] rs2,
                        input [4:0] EX_MEM_rd,
                        input EX_MEM_reg_write,
                        input [4:0] MEM_WB_rd,
                        input MEM_WB_reg_write,
                        output reg [1:0] ForwardA,
                        output reg [1:0] ForwardB);

    always @(*) begin
        if((rs1 == EX_MEM_rd) && (rs1 != 0) && EX_MEM_reg_write) begin
            ForwardA = 2'b01;
        end
        else if((rs1 == MEM_WB_rd) && (rs1 != 0) && MEM_WB_reg_write) begin
            ForwardA = 2'b10;
        end
        else begin
            ForwardA = 2'd00;
        end

        if((rs2 == EX_MEM_rd) && (rs2 != 0) && EX_MEM_reg_write) begin
            ForwardB = 2'b01;
        end
        else if((rs2 == MEM_WB_rd) && (rs2 != 0) && MEM_WB_reg_write) begin
            ForwardB = 2'b10;
        end
        else begin
            ForwardB = 2'b00;
        end
    end

endmodule

// for forwarding data from MEM/WB to ID stage
module ForwardingEcall( input [4:0] rs1,
                        input [4:0] rs2,
                        input [4:0] rd,
                        input [4:0] EX_MEM_rd,
                        input is_ecall,
                        output reg [1:0] mux_rs1_dout,
                        output reg mux_rs2_dout);

    always @(*) begin
        if((rs1==rd) && (rd != 0)) begin
            mux_rs1_dout = 2'b00;
        end
        else if((EX_MEM_rd == 5'd17) && is_ecall) begin // ecall instruction 바로 앞에서 x17의 값을 write 해준 경우 forwarding
            mux_rs1_dout = 2'b10;
        end
        else begin
            mux_rs1_dout = 2'b01;
        end

        if((rs2 == rd) && (rd != 0)) begin
            mux_rs2_dout = 0;
        end
        else begin
            mux_rs2_dout = 1;
        end
    end
endmodule