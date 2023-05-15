module BTB(input [31:0] pc,
            input reset,
            input clk,
            input [31:0] IF_ID_pc,
            input is_jal, // ID_EX
            input is_jalr, // ID_EX
            input branch, // ID_EX
            input bcond,
            input [31:0] write_pc, // ID_EX
            input [31:0] pc_plus_imm,
            input [31:0] reg_plus_imm,
            output reg [31:0] n_pc
            // output reg miss_prediction
            );

    // wire declaration
    wire [24:0] tag;
    wire [4:0] index;

    wire [24:0] write_tag;
    wire [4:0] write_index;

    // reg declaration
    reg [5:0] i;
    reg [31:0] btb[0:31];
    reg [24:0] tag_table[0:31];

    // assignment
    assign tag=pc[31:7];
    assign index=pc[6:2];
    
    assign write_tag=write_pc[31:7];
    assign write_index=write_pc[6:2];

    always @(*) begin
        if(tag_table[index]==tag) begin
            n_pc=btb[index];
        end
        else begin
            n_pc=pc+4;
        end
    end

    always @(*) begin
        if(is_jal|branch) begin
            if((tag_table[write_index]!=write_tag)|(btb[write_index]!=pc_plus_imm)) begin
                tag_table[write_index]=write_tag;
                btb[write_index]=pc_plus_imm;
            end
        end
        else if(is_jalr) begin
            if((tag_table[write_index]!=write_tag)|(btb[write_index]!=reg_plus_imm)) begin
                tag_table[write_index]=write_tag;
                btb[write_index]=reg_plus_imm;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for(i=0; i < 32;i=i+1) begin
                btb[i] = 0;
                tag_table[i] = -1; // tag를 0으로 하면 초반에 모든 pc가 전부 tag가 일치해서 n_pc를 0으로 넣어버림.
            end
        end
    end


endmodule

module MissPredictionDetector(
    input [31:0] IF_ID_pc,
    input ID_EX_is_jal, // ID_EX
    input ID_EX_is_jalr, // ID_EX
    input ID_EX_branch, // ID_EX
    input ID_EX_bcond,
    input [31:0] ID_EX_pc,
    input [31:0] pc_plus_imm,
    input [31:0] reg_plus_imm,
    output reg is_miss_pred);

    always @(*) begin
        if((ID_EX_is_jal|(ID_EX_branch&ID_EX_bcond))&(IF_ID_pc!=pc_plus_imm)) begin
            is_miss_pred=1;
        end
        else if((ID_EX_is_jalr)&(IF_ID_pc!=reg_plus_imm)) begin
            is_miss_pred=1;
        end
        else if(ID_EX_branch&(!ID_EX_bcond)&(IF_ID_pc!=ID_EX_pc+4)) begin
            is_miss_pred=1;
        end
        else begin
            is_miss_pred=0;
        end 
    end
endmodule