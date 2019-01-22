`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/30 19:22:23
// Design Name: 
// Module Name: clockDiv
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module clockDiv(input clk,
                input [31:0]div,
                output reg out);
    reg [31:0] count;
    reg inc;
    reg max;
    // All Always blocks run in parallel don't get confused
    always begin // This block will execute continuously and will update 'inc'
        max = div >> 1;
        inc = (count > max);
    end
    always@(posedge clk) begin
        case(inc)
            1:begin
                count = 0;
                out = ~out;
            end
            0:begin
                count = count + 1;
            end
        endcase
    end
endmodule