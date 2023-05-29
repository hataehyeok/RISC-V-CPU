`include "CLOG2.v"

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
    output [31:0] dout,
    output is_hit);
  // Wire declarations
  wire is_data_mem_ready;
  wire [3:0] index;
  wire [127:0] data_to_read;
  
  wire [23:0] tag_to_read;
  wire valid_read;
  wire dirty_read;

  wire [127:0] dmem_dout;
  wire dmem_output_valid;
  wire [31:0] clog2;

  // Reg declarations
  reg [1:0] cur_state;    //현재 state를 저장하기 위해 사용하는 register
  reg [1:0] next_state;   //다음 state를 저장하기 위해 사용하는 register

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

  // output에 연결할 reg들
  reg [31:0] _dout;

  // hit ratio check를 위한 reg
  reg [31:0] hit_counter;
  reg [31:0] miss_counter;


  // You might need registers to keep the status.

  assign is_ready = is_data_mem_ready;
  assign index = addr[7:4];

  // output에 연결할 reg들 assign
  assign is_output_valid = (next_state==2'b00);
  assign dout = _dout;
  assign is_hit = (addr[31:8] == tag_to_read)&valid_read;

  assign clog2 = `CLOG2(LINE_SIZE);

  always @(*) begin
    _dout=0;
    tag_to_write=0;
    valid_write=0;
    dirty_write=0;

    tag_we=0;
    data_we=0;

    // data_to_write 세팅
    data_to_write = data_to_read;

    case(addr[3:2]) // block offset 확인 (block offset은 2'b00이면 0~31, 2'b01이면 32~63, 2'b10이면 64~95, 2'b11이면 96~127)
      2'b00: data_to_write[31:0] = din;
      2'b01: data_to_write[63:32] = din;
      2'b10: data_to_write[95:64] = din;
      2'b11: data_to_write[127:96] = din;
    endcase

    // output으로 내보낼 data 결정
    case(addr[3:2]) // block offset 확인 (block offset은 2'b00이면 0~31, 2'b01이면 32~63, 2'b10이면 64~95, 2'b11이면 96~127)
      2'b00: _dout = data_to_read[31:0];
      2'b01: _dout = data_to_read[63:32];
      2'b10: _dout = data_to_read[95:64];
      2'b11: _dout = data_to_read[127:96];
    endcase

    // 본격적인 Cache FSM 시작
    // state transition logic 부분 (next_state 결정)
    case(cur_state)
      // idle state 2'b00
      2'b00: begin
        if(is_input_valid) begin
          next_state=2'b01;
        end
        else begin
          next_state=2'b00;
        end
        // else부분은 현상 유지니까 굳이 없어도 되지 않을까
      end
      // compare_tag state (if valid && hit, set valid, set tag / if write set dirty)
      2'b01: begin
        if(is_hit) begin
          // cache hit (tag 일치하고 valid==1)
          hit_counter = hit_counter + 1;
          // write hit (mem write일 때 cache hit인 경우)
          if(mem_write) begin
            // read and modify cache line
            data_we = 1; // data를 쓰기 위해
            tag_we = 1; // tag(tag, valid, dirty)를 쓰기 위해
            tag_to_write = tag_to_read; // tag는 그대로
            valid_write = 1;
            dirty_write = 1;
          end
          next_state=2'b00;   // 다시 idle state로
        end
        else begin
          // cache miss
          miss_counter = miss_counter+1;
          // tag 새로 입력
          tag_we=1;
          valid_write=1;
          tag_to_write=addr[31:8];
          dirty_write=mem_write; // write 인경우에만 dirty=1

          // cache miss 났으니까 dmem으로 고고
          // dmem으로 request
          dmem_input_valid=1; // data memory 의 request_arrived를 true로 만들기 위한 필수 조건
          // compusory miss or miss with clean(not dirty) block
          if((valid_read==0)|(dirty_read==0)) begin
            dmem_read=1;
            dmem_write=0;
            dmem_addr=addr;
            next_state=2'b10; // allocate state로
          end

          else begin // valid==1 and dirty==1
            // dirty line과 함께 miss 이므로 write back 해주고 난 다음 allocate state로 가야함
            dmem_addr={tag_to_read, addr[7:0]}; // write back하는 녀석의 tag는 현재 addr와 다른 tag임
            dmem_din=data_to_read;
            dmem_read=0;
            dmem_write=1;
            next_state=2'b11; // write back state로!
          end
        end
      end

      // allocate state (Read new block from Memory)
      2'b10: begin
        // dmem이 ready 될 때까지 기다리다가 ready 되면
        if(is_data_mem_ready) begin
          // compare tag state 로 돌아간다. dmem에서 받은 데이터 들고감
          next_state = 2'b01;
          data_to_write = dmem_dout;
          data_we = 1;
          
          dmem_input_valid = 0; // 이게 필요하지 않나???? 진짜 화난다 하ㅠㅠ
        end
        else begin
          next_state = 2'b10;
        end
        // 위의 else도 그냥 필요없지 않나 싶음
      end

      // write_back state (Write Old Block to Memory)
      2'b11: begin
        // write back 다 될 때까지 기다리다가 ready 되면
        if(is_data_mem_ready) begin
          // 새로운 memory request. write back 완료 됐으니까
          // 메모리에서 read 할 거 read 해올(Read new block from Memory) 차례
          dmem_input_valid=1;
          dmem_read=1;
          dmem_write=0;
          dmem_addr=addr;
          
          next_state=2'b10; // allocate state로 돌아간다.
        end
        else begin
          next_state=2'b11;
        end
      end
      
    endcase
  end

  always @(posedge clk) begin
    if(reset) begin
      cur_state <= 2'b00; // idle state;
      hit_counter <= 0;
      miss_counter <= 0;
    end
    else begin
      cur_state <= next_state;
      $monitor("hit = %d, miss = %d", hit_counter, miss_counter);
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

  // Cache DataBank and TagBank(tag, valid, dirty)
  CacheDataBank data_bank(
    .reset(reset),
    .clk(clk),
    .index(index),
    .write_enable(data_we),
    .data_to_write(data_to_write),
    .data_to_read(data_to_read)
  );
  CacheTagBank tag_bank(
    .reset(reset),
    .clk(clk),
    .index(index),
    .write_enable(tag_we),
    .tag_to_write(tag_to_write),
    .valid_write(valid_write),
    .dirty_write(dirty_write),
    .tag_to_read(tag_to_read),
    .valid_read(valid_read),
    .dirty_read(dirty_read)
  );
endmodule


module CacheDataBank(
  input reset,
  input clk,

  input [3:0] index,
  input write_enable,

  input [127:0] data_to_write,
  output [127:0] data_to_read);


  reg [127:0] data_bank [0:15];
  reg [9:0] i;

  assign data_to_read = data_bank[index];

  always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<16;i=i+1) begin
        data_bank[i]=0;
      end
    end
    else begin
      if(write_enable) begin
        data_bank[index] <= data_to_write;
      end
    end
  end

endmodule

module CacheTagBank(
  input reset,
  input clk,

  input [3:0] index,
  input write_enable,

  input [23:0] tag_to_write,
  input valid_write,
  input dirty_write,
  output [23:0] tag_to_read,
  output valid_read,
  output dirty_read);


  reg [23:0] tag_bank [0:15];
  reg valid_table [0:15];
  reg dirty_table [0:15];
  reg [9:0] i;

  assign tag_to_read = tag_bank[index];
  assign valid_read = valid_table[index];
  assign dirty_read = dirty_table[index];

  always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<16;i=i+1) begin
        tag_bank[i]=0;
        valid_table[i]=0;
        dirty_table[i]=0;
      end
    end
    else begin
      if(write_enable) begin
        tag_bank[index] <= tag_to_write;
        valid_table[index] <= valid_write;
        dirty_table[index] <= dirty_write;
      end
    end
  end

endmodule