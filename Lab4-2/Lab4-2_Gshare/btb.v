module BTB(input [31:0] pc,
            input reset,
            input clk,
            input [31:0] IF_ID_pc,
            // input [1:0] write_pc_src,
            input is_jal, // ID_EX
            input is_jalr, // ID_EX
            input branch, // ID_EX
            input bcond,
            input [31:0] write_pc, // ID_EX
            input [31:0] pc_plus_imm,
            input [31:0] reg_plus_imm,
            input [4:0] write_bhsr,
            output reg [31:0] n_pc,
            // output reg miss_prediction
            output reg [4:0] bhsr
            );

    // wire declaration
    wire [31:0] tag;
    wire [4:0] index;

    wire [31:0] write_tag;
    wire [4:0] write_index;

    // 2-bit predictor
    wire is_taken;

    // reg declaration
    reg [5:0] i;
    reg [31:0] btb[0:31];
    reg [31:0] tag_table[0:31];

    // 2-bit predictor for Gshare : 32개의 entries
    reg [1:0] bht[0:31];

    // Gshare
    // reg [4:0] bhsr; => output reg로 바꿈

    // assignment
    assign tag=pc[31:0];
    assign index=pc[6:2]^bhsr;
    assign write_tag=write_pc[31:0];
    assign write_index=write_pc[6:2]^write_bhsr;
    assign is_taken = (branch&bcond)|is_jal|is_jalr;

    always @(*) begin
        if((tag_table[index]==tag)&(bht[index]>=2'b10)) begin
            n_pc = btb[index];
        end
        else begin
            n_pc = pc+4;
        end
    end

    always @(*) begin
        if(is_jal|branch) begin
            if((tag_table[write_index]!=write_tag)|(btb[write_index]!=pc_plus_imm)) begin
                tag_table[write_index]=write_tag;
                btb[write_index] = pc_plus_imm;
            end
        end
        else if(is_jalr) begin
            if((tag_table[write_index]!=write_tag)|(btb[write_index]!=reg_plus_imm)) begin
                tag_table[write_index]=write_tag;
                btb[write_index] = reg_plus_imm;
            end
        end
    end
   
    // 2-bit predictor
    always @(*) begin
        if (branch | is_jal | is_jalr) begin 
            if(is_taken) begin
                case(bht[write_index])
                    2'b00: begin
                        bht[write_index]=2'b01;
                    end
                    2'b01: begin
                        bht[write_index]=2'b10;
                    end
                    2'b10: begin
                        bht[write_index]=2'b11;
                    end
                    2'b11: begin
                        bht[write_index]=2'b11;
                    end
                endcase
                //Gshare
                bhsr = {bhsr[3:0], 1'b1};
            end
            else begin
                case(bht[write_index])
                    2'b00: begin
                        bht[write_index]=2'b00;
                    end
                    2'b01: begin
                        bht[write_index]=2'b00;
                    end
                    2'b10: begin
                        bht[write_index]=2'b01;
                    end
                    2'b11: begin
                        bht[write_index]=2'b10;
                    end
                endcase
                //Gshare
                bhsr = {bhsr[3:0], 1'b0};
            end
        end
    end


    always @(posedge clk) begin
        if (reset) begin
            for(i=0; i < 32;i=i+1) begin
                btb[i] = 0;
                tag_table[i] = -1; // tag를 0으로 하면 초반에 모든 pc가 전부 tag가 일치해서 n_pc를 0으로 넣어버림.
                // 2-bit predictor
                bht[i] = 2'b00;
            end
            // Gshare
            bhsr=5'b00000;
        end
    end

endmodule

//Predicting Misses
module MissPredDetector(
    input [31:0] IF_ID_pc,
    input ID_EX_is_jal,
    input ID_EX_is_jalr,
    input ID_EX_branch,
    input ID_EX_bcond,
    input [31:0] ID_EX_pc,
    input [31:0] pc_plus_imm,
    input [31:0] reg_plus_imm,
    output reg is_miss_pred);

    wire is_jal_or_taken = (ID_EX_is_jal|(ID_EX_branch&ID_EX_bcond))&(IF_ID_pc!=pc_plus_imm);
    wire is_jalr_or_taken  = (ID_EX_is_jalr)&(IF_ID_pc!=reg_plus_imm);
    wire is_branch  = (IF_ID_pc!=ID_EX_pc+4)&(ID_EX_branch&!ID_EX_bcond);

    always @(*) begin
        if(is_jal_or_taken | is_jalr_or_taken | is_branch) begin
            is_miss_pred=1;
        end
        else begin
            is_miss_pred=0;
        end 
    end
endmodule