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