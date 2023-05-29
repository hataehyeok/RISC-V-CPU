`include "CLOG2.v"

`define Idle            2'b00
`define CompareTag      2'b01
`define Allocate        2'b10
`define WriteBack       2'b11

//Cache module
module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 16,
               parameter NUM_WAYS = 1) (
    input reset,
    input clk,

    input is_input_valid,
    input [31:0] addr,
    input mem_read,
    input mem_write,
    input [31:0] din,

    output is_ready,
    output is_output_valid,
    output reg [31:0] dout,
    output is_hit);
  
  // Wire declarations
  wire is_data_mem_ready;
  reg [1:0] bo;
  reg [3:0] idx;
  reg [23:0] tag;
  wire [31:0] clog2;
  wire [127:0] dmem_dout;
  wire dmem_output_valid;
  

  // Reg declarations
  reg [1:0] cur_state;
  reg [1:0] next_state;

  reg [127:0] data_to_write;
  reg [23:0] tag_to_write;
  reg valid_write;
  reg dirty_write;

  reg data_we;
  reg tag_we;

  reg [31:0] dmem_addr;
  reg [127:0] dmem_din;
  reg dmem_input_valid;
  reg dmem_read;
  reg dmem_write;

  // Reg for Data Bank, Tag Bank
  reg [9:0] i;
  reg [127:0] data_bank [0:15];
  reg [23:0] tag_bank [0:15];
  reg valid_table [0:15];
  reg dirty_table [0:15];
  
  assign clog2 = `CLOG2(LINE_SIZE);   //Do not solve bug that why I have to assign this value
  // assign of output
  assign is_ready = is_data_mem_ready;
  assign is_output_valid = (next_state == `Idle);
  assign is_hit = (tag == tag_bank[idx]) & (valid_table[idx] == 1);


  always @(*) begin
    bo = addr[3:2];
    idx = addr[7:4];
    tag = addr[31:8];

    dout = 0;
    tag_to_write = 0;
    valid_write = 0;
    dirty_write = 0;

    tag_we = 0;
    data_we = 0;
    dmem_input_valid = 0;
    data_to_write = data_bank[idx];

    case (bo)    // block offset 확인 (block offset은 2'b00이면 0~31, 2'b01이면 32~63, 2'b10이면 64~95, 2'b11이면 96~127)
      `Idle: begin
        data_to_write[31:0] = din;
        dout = data_bank[idx][31:0];
      end
      `CompareTag: begin
        data_to_write[63:32] = din;
        dout = data_bank[idx][63:32];
      end
      `Allocate: begin
        data_to_write[95:64] = din;
        dout = data_bank[idx][95:64];
      end
      `WriteBack: begin
        data_to_write[127:96] = din;
        dout = data_bank[idx][127:96];
      end
    endcase

    // state transition logic 부분 (next_state 결정)
    case (cur_state)
      `Idle: begin
        if (is_input_valid) begin
          next_state = `CompareTag;
        end
        else begin
          next_state = `Idle;
        end
      end
      `CompareTag: begin
        if (is_hit) begin
          if (mem_write) begin
            data_we = 1;
            tag_we = 1;
            tag_to_write = tag_bank[idx];
            valid_write = 1;
            dirty_write = 1;
          end
          next_state = `Idle;
        end
        else begin
          tag_we = 1;
          valid_write = 1;
          tag_to_write = tag;
          dirty_write = mem_write;
          dmem_input_valid = 1;

          if ((valid_table[idx] == 0) | (dirty_table[idx] == 0)) begin
            dmem_read=1;
            dmem_write=0;
            dmem_addr=addr;
            next_state = `Allocate;
          end
          else begin
            dmem_addr = {tag_bank[idx], addr[7:0]};
            dmem_din = data_bank[idx];
            dmem_read = 0;
            dmem_write = 1;
            next_state = `WriteBack;
          end
        end
      end
      `Allocate: begin
        if (is_data_mem_ready) begin
          next_state = `CompareTag;
          data_to_write = dmem_dout;
          data_we = 1;
          dmem_input_valid = 0;
        end
      end
      `WriteBack: begin
        if (is_data_mem_ready) begin
          dmem_input_valid = 1;
          dmem_read = 1;
          dmem_write = 0;
          dmem_addr = addr;
          next_state = `Allocate;
        end
      end
      
    endcase
  end

  always @(posedge clk) begin
    if(reset) begin
      cur_state <= `Idle;
    end
    else begin
      cur_state <= next_state;
    end
  end

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),

    .is_input_valid(dmem_input_valid),
    .addr(dmem_addr >> clog2),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(dmem_read),
    .mem_write(dmem_write),
    .din(dmem_din),

    // is output from the data memory valid?
    .is_output_valid(dmem_output_valid),
    .dout(dmem_dout),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );

  always @(posedge clk) begin
    if(reset) begin
      for(i = 0; i < 16; i = i + 1) begin
        data_bank[i] = 0;
        tag_bank[i] = 0;
        valid_table[i] = 0;
        dirty_table[i] = 0;
      end
    end
    else begin
      if(data_we) begin
        data_bank[idx] <= data_to_write;
      end
      if(tag_we) begin
        tag_bank[idx] <= tag_to_write;
        valid_table[idx] <= valid_write;
        dirty_table[idx] <= dirty_write;
      end
    end
  end

endmodule

