module ForwardingUnit (input [4:0] id_ex_rs1,
                        input [4:0] id_ex_rs2,
                        input [4:0] ex_mem_rd,
                        input ex_mem_reg_write,
                        input [4:0] mem_wb_rd,
                        input mem_wb_reg_write,
                        output reg [1:0] forward_A,
                        output reg [1:0] forward_B);
    always @(*) begin
        // rs1 forwarding 필요한지 확인
        if(ex_mem_reg_write&(id_ex_rs1==ex_mem_rd)&(ex_mem_rd!=0)) begin
            forward_A=2'b01;
        end
        else if(mem_wb_reg_write&(id_ex_rs1==mem_wb_rd)&(mem_wb_rd!=0)) begin
            forward_A=2'b10;
        end
        else begin
            forward_A=2'b00;
        end

        // rs2 forwarding 필요한지 확인
        if(ex_mem_reg_write&(id_ex_rs2==ex_mem_rd)&(ex_mem_rd!=0)) begin
            forward_B=2'b01;
        end
        else if(mem_wb_reg_write&(id_ex_rs2==mem_wb_rd)&(mem_wb_rd!=0)) begin
            forward_B=2'b10;
        end
        else begin
            forward_B=2'b00;
        end
    end

endmodule

// for forwarding data from MEM/WB to ID stage
module ForwardingMuxControlUnit(input [4:0] rs1,
                                input [4:0] rs2,
                                input [4:0] rd, // From WB stage
                                input [4:0]ex_mem_rd,
                                input is_ecall,
                                output reg [1:0] mux_rs1_dout,
                                output reg mux_rs2_dout);
    always @(*) begin
        if(rs1==rd&(rd!=0)) begin
            mux_rs1_dout=2'b00;
        end
        else if((ex_mem_rd==17)&is_ecall) begin // ecall instruction 바로 앞에서 x17의 값을 write 해준 경우 forwarding
            mux_rs1_dout=2'b10;
        end
        else begin
            mux_rs1_dout=2'b01;
        end

        if(rs2==rd&(rd!=0)) begin
            mux_rs2_dout=0;
        end
        else begin
            mux_rs2_dout=1;
        end

        

    end
endmodule


// Forwarding 시 register 번호가 0인 경우까지 Forwarding 하게 되면
// stall 상황에서 rd가 0일 때 forwarding을 시도하면서 이상한 값이 forwarding 됨;;