// //Adder module for PC+4
// module Adder(input [31:0] inA,
//              input [31:0] inB,
//              output[31:0] out);
//   assign out = inA + inB;
// endmodule

// //Mux Module(1 bit)
// module onebitMUX(input [31:0] inA,
//                  input [31:0] inB,
//                  input select,
//                  output [31:0] out);
//   assign out = select ? inA : inB;
// endmodule

// //Mux Module(2 bit)
// module twobitMUX(input [31:0] inA,
//                  input [31:0] inB,
//                  input [31:0] inC,
//                  input [31:0] inD,
//                  input [1:0] select,
//                  output reg [31:0] out);
//   always @(*) begin
//     case(select)
//       2'b00: begin
//         out = inA;
//       end
//       2'b01: begin
//         out = inB;
//       end
//       2'b10: begin
//         out = inC;
//       end
//       default begin
//         out = inD;
//       end
//     endcase
//   end
// endmodule

// //Mux Module(for ecall)
// module ecallMUX(input [4:0] inA,
//                 input [4:0] inB,
//                 input select,
//                 output reg out);
//   assign out = select ? inA : inB;
// endmodule

module Mux(input [31:0] input0,
            input [31:0] input1,
            input signal,
            output reg [31:0] output_mux);
    always @(*) begin
        if(signal) begin
            output_mux=input1;
        end
        else begin
            output_mux=input0;
        end
    end
endmodule

module MuxForIsEcall(input [4:0] input0,
                    input [4:0] input1,
                    input signal,
                    output reg [4:0] output_mux);
    always @(*) begin
        if(signal) begin
            output_mux=input1;
        end
        else begin
            output_mux=input0;
        end
    end
endmodule

module MuxForForward(input [31:0] input00,
                    input [31:0] input01,
                    input [31:0] input10,
                    input [1:0] signal,
                    output reg [31:0] output_mux);
    always @(*) begin
        if(signal==2'b00) begin
            output_mux=input00;
        end
        else if(signal==2'b01) begin
            output_mux=input01;
        end
        else if(signal==2'b10) begin
            output_mux=input10;
        end
    end
endmodule