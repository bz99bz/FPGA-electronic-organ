`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/01/01 22:02:43
// Design Name: 
// Module Name: electronic organ
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


module electronic_organ(
 input                   I_clk   , // ϵͳ50MHzʱ��
   input                   I_rst_n , // ϵͳ��λ
   output  reg   [3:0]    O_red   , // VGA��ɫ����
   output   reg  [3:0]    O_green , // VGA��ɫ����
   output   reg  [3:0]    O_blue  , // VGA��ɫ����
   output                  O_hs    , // VGA��ͬ���ź�
   output                  O_vs ,    // VGA��ͬ���ź�
    input           [3:0]   row_data,
   output         key_flag,
    output   [3:0]   col_data,
    output                 BEEP                     //�������˿�
    );
  reg 	[ 7:0]	KEY;						//�����˿�
  wire [3:0] key_value;
  maxtrixKeyboard_drive uut(
  .clk( I_clk ),
  . rst_n( I_rst_n ),
  .row_data(row_data),
  .key_flag(key_flag),
  .key_value(key_value),
  .col_data(col_data)
  );  
    
    
    // �ֱ���Ϊ640*480ʱ��ʱ�������������
    parameter       C_H_SYNC_PULSE      =   96  , 
                     C_H_BACK_PORCH      =   48  ,
                     C_H_ACTIVE_TIME     =   640 ,
                     C_H_FRONT_PORCH     =   16  ,
                     C_H_LINE_PERIOD     =   800 ;
    // �ֱ���Ϊ640*480ʱ��ʱ�������������               
    parameter       C_V_SYNC_PULSE      =  2   , 
                     C_V_BACK_PORCH      =   33  ,
                     C_V_ACTIVE_TIME     =   480 ,
                     C_V_FRONT_PORCH     =   10  ,
                     C_V_FRAME_PERIOD    =   525 ;
    parameter       C_COLOR_BAR_WIDTH   =   C_H_ACTIVE_TIME / 12  ;  
    parameter       C_COLOR_BAR_LENGTH   =   C_V_ACTIVE_TIME / 2 ; 
    reg [11:0]      R_h_cnt         ; // ��ʱ�������
    reg [11:0]      R_v_cnt         ; // ��ʱ�������
    wire             R_clk_25M       ;
    wire            W_active_flag   ; // �����־��������ź�Ϊ1ʱRGB�����ݿ�����ʾ����Ļ��
    //////////////////////////////////////////////////////////////////
    //���ܣ� ����25MHz������ʱ��
    //////////////////////////////////////////////////////////////////
    
    clockDiv pixel(
    .clk(I_clk),
    .div(32'd4),
    .out(R_clk_25M)
    );
    
    //////////////////////////////////////////////////////////////////
    
    
    
    //////////////////////////////////////////////////////////////////
    
    // ���ܣ�������ʱ��
    
    //////////////////////////////////////////////////////////////////
    always @(posedge R_clk_25M or negedge I_rst_n)
    begin
        if(I_rst_n)
            R_h_cnt <=  12'd0   ;
        else if(R_h_cnt == C_H_LINE_PERIOD - 1'b1)
            R_h_cnt <=  12'd0   ;
        else
            R_h_cnt <=  R_h_cnt + 1'b1  ;                
    end                
    
    assign O_hs =   (R_h_cnt < C_H_SYNC_PULSE) ? 1'b0 : 1'b1    ; 
    //////////////////////////////////////////////////////////////////
    
    //////////////////////////////////////////////////////////////////
    // ���ܣ�������ʱ��
    //////////////////////////////////////////////////////////////////
    always @(posedge R_clk_25M or negedge I_rst_n)
    begin
        if(I_rst_n)
            R_v_cnt <=  12'd0   ;
        else if(R_v_cnt == C_V_FRAME_PERIOD - 1'b1)
            R_v_cnt <=  12'd0   ;
        else if(R_h_cnt == C_H_LINE_PERIOD - 1'b1)
            R_v_cnt <=  R_v_cnt + 1'b1  ;
        else
            R_v_cnt <=  R_v_cnt ;                        
    end                
    
    assign O_vs =   (R_v_cnt < C_V_SYNC_PULSE) ? 1'b0 : 1'b1    ; 
    //////////////////////////////////////////////////////////////////  
    assign W_active_flag =  (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH))  &&
                            (R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME))  && 
                            (R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH                  ))  &&
                            (R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME))  ;                     
    
    /*always @ (*)
    begin
    case(key_value)
    4'h0:KEY=8'b00000000;
    4'h1:KEY=8'b00000001;
    4'h2:KEY=8'b00000010;
    4'h3:KEY=8'b00000100;
    4'h4:KEY=8'b00001000;
    4'h5:KEY=8'b00010000;
    4'h6:KEY=8'b00100000;
    4'h7:KEY=8'b01000000;
    4'h8:KEY=8'b10000000;
    4'h9:KEY=8'b10000001;
    4'ha:KEY=8'b10000010;
    4'hb:KEY=8'b10000100;
    4'hc:KEY=8'b10001000;
    4'hd:KEY=8'b10010000;
    4'he:KEY=8'b10100000;
    4'hf:KEY=8'b11000000;
    endcase
    end*/
    
    //////////////////////////////////////////////////////////////////
    
    // ���ܣ�����ʾ����Ļ�ֳ�8�����У�ÿ�����еĿ����80
    
    //////////////////////////////////////////////////////////////////
    always @(posedge R_clk_25M or negedge I_rst_n)
    begin
        if(I_rst_n) 
            begin
                O_red   <=  4'b0000    ;
                O_green <=  4'b0000   ;
                O_blue  <=  4'b0000    ; 
            end
        else if(W_active_flag)     
            begin
               if((R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH/2))&&key_value==4'h1) 
                    begin
                        O_red   <=  4'b1111    ;
                        O_green <=  4'b0000   ;
                        O_blue  <=  4'b0000   ;
                    end
              else if((R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH/2))&&key_value!=4'h1) // ��ɫ����
                    begin
                        O_red   <=  4'b1111    ;
                        O_green <=  4'b1111   ;
                        O_blue  <=  4'b1111   ;
                    end
              else if(R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_LENGTH)&&R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH+10)) 
                                    begin
                                        O_red   <=  4'b0000 ;
                                        O_green <=  4'b0000;
                                        O_blue  <=  4'b0000;
                                    end
              else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH)&&key_value==4'h1) // ��ɫ����
                                       begin
                                             O_red   <=  4'b1111   ;
                                               O_green <=  4'b0000  ;
                                               O_blue  <=  4'b0000   ; 
                                          end                                     
                 else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH)&&key_value!=4'h1) // ��ɫ����
                                                                             begin
                                                                                   O_red   <=  4'b1111   ;
                                                                                     O_green <=  4'b1111  ;
                                                                                     O_blue  <=  4'b1111   ; 
                                                                                end          
               else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH+1)) // ��ɫ����
                                                                             begin
                                                                                  O_red   <=  4'b0000    ;
                                                                                  O_green <=  4'b0000   ; 
                                                                                  O_blue  <=  4'b0000    ;
                                                                             end
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*3/2+5)&&key_value==4'h2) 
                    begin
                        O_red   <=  4'b1100    ;
                        O_green <=  4'b1111   ; 
                        O_blue  <=  4'b0000   ;
                    end 
                    else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*3/2+5)&&key_value!=4'h2) 
                                    begin
                                        O_red   <=  4'b1111    ;
                                        O_green <=  4'b1111   ; 
                                        O_blue  <=  4'b1111    ;
                                    end 
                else if(R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_LENGTH)&&R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*2+15)) 
                                                   begin
                                                       O_red   <=  4'b0000 ;
                                                       O_green <=  4'b0000;
                                                       O_blue  <=  4'b0000;
                                                   end
                 else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*2)&&key_value==4'h2) 
                                                                  begin
                                                                      O_red   <=  4'b1100    ;
                                                                      O_green <=  4'b1111   ; 
                                                                      O_blue  <=  4'b0000    ;
                                                                  end 
                          else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*2)&&key_value!=4'h2) 
                                                                begin
                                                                     O_red   <=  4'b1111    ;
                                                                     O_green <=  4'b1111   ; 
                                                                     O_blue  <=  4'b1111    ;
                                                                end 
                     else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*2+1)) 
                                    begin
                                         O_red   <=  4'b0000    ;
                                         O_green <=  4'b0000   ; 
                                         O_blue  <=  4'b0000    ;
                                    end
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*3)&&key_value==4'h3) 
                    begin
                        O_red   <=  4'b1111    ;
                        O_green <=  4'b1111   ;
                        O_blue  <=  4'b0000  ;
                    end 
                    else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*3)&&key_value!=4'h3) 
                                   begin
                                       O_red   <=  4'b1111    ;
                                       O_green <=  4'b1111   ;
                                       O_blue  <=  4'b1111    ;
                                   end 
                   else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*3+1)) 
                         begin
                               O_red   <=  4'b0000    ;
                               O_green <=  4'b0000   ; 
                               O_blue  <=  4'b0000    ;
                         end
                 else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*7/2)&&key_value==4'h4)
                                         begin
                                             O_red   <=  4'b0000    ;
                                             O_green <=  4'b1111   ; 
                                             O_blue  <=  4'b0000    ;
                                         end 
                   else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*7/2)&&key_value!=4'h4)
                                                                            begin
                                                                                O_red   <=  4'b1111    ;
                                                                                O_green <=  4'b1111   ; 
                                                                                O_blue  <=  4'b1111    ;
                                                                            end                                  
                 else if(R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_LENGTH)&&R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*4+10)) 
                                          begin
                                                O_red   <=  4'b0000 ;
                                                O_green <=  4'b0000;
                                                O_blue  <=  4'b0000;
                                         end   
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*4)&&key_value==4'h4)
                    begin
                        O_red   <=  4'b0000    ;
                        O_green <=  4'b1111   ; 
                        O_blue  <=  4'b0000    ;
                    end 
                    else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*4)&&key_value!=4'h4)
                                 begin
                                     O_red   <=  4'b1111    ;
                                     O_green <=  4'b1111   ; 
                                     O_blue  <=  4'b1111    ;
                                 end 
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*4+1)) 
                       begin
                            O_red   <=  4'b0000    ;
                            O_green <=  4'b0000   ; 
                            O_blue  <=  4'b0000    ;
                      end
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*9/2+5)&&key_value==4'h5) 
                                      begin
                                          O_red   <=  4'b0000    ; 
                                          O_green <=  4'b1111   ;
                                          O_blue  <=  4'b1111    ;
                                      end
                  else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*9/2+5)&&key_value!=4'h5) 
                                                                       begin
                                                                           O_red   <=  4'b1111    ; 
                                                                           O_green <=  4'b1111   ;
                                                                           O_blue  <=  4'b1111    ;
                                                                       end    
                 else if(R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_LENGTH)&&R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*5+10)) 
                                 begin
                                     O_red   <=  4'b0000 ;
                                     O_green <=  4'b0000;
                                     O_blue  <=  4'b0000;
                                end   
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*5)&&key_value==4'h5) 
                    begin
                        O_red   <=  4'b0000    ; 
                        O_green <=  4'b1111   ;
                        O_blue  <=  4'b1111    ;
                    end
                 else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*5)&&key_value!=4'h5) 
                                   begin
                                       O_red   <=  4'b1111    ; 
                                       O_green <=  4'b1111   ;
                                       O_blue  <=  4'b1111    ;
                                   end 
               else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*5+1)) 
                                   begin
                                       O_red   <=  4'b0000    ; 
                                       O_green <=  4'b0000   ;
                                       O_blue  <=  4'b0000    ;
                                   end     
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*11/2+5)&&key_value==4'h6) 
                                                  begin
                                                      O_red   <=  4'b0000    ; 
                                                      O_green <=  4'b0000   ; 
                                                      O_blue  <=  4'b1111    ; 
                                                  end  
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*11/2+5)&&key_value!=4'h6) 
                                                 begin
                                                        O_red   <=  4'b1111    ; 
                                                        O_green <=  4'b1111   ; 
                                                        O_blue  <=  4'b1111    ; 
                                                 end 
              else if(R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_LENGTH)&&R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*6+15)) 
                                                 begin
                                                      O_red   <=  4'b0000 ;
                                                      O_green <=  4'b0000;
                                                      O_blue  <=  4'b0000;
                                                 end                     
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*6)&&key_value==4'h6) 
                    begin
                        O_red   <=  4'b0000    ; 
                        O_green <=  4'b0000   ; 
                        O_blue  <=  4'b1111    ; 
                    end
                 else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*6)&&key_value!=4'h6) 
                                    begin
                                        O_red   <=  4'b1111    ; 
                                        O_green <=  4'b1111   ; 
                                        O_blue  <=  4'b1111    ; 
                                    end
             else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*6+1)) 
                                  begin
                                      O_red   <=  4'b0000   ; 
                                      O_green <=  4'b0000   ; 
                                      O_blue  <=  4'b0000    ; 
                                  end
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*7)&&key_value==4'h7) 
                    begin
                        O_red   <=  4'b1111    ;
                        O_green <=  4'b0000  ; 
                        O_blue  <=  4'b1111    ;
                    end
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*7)&&key_value!=4'h7) 
                                   begin
                                       O_red   <=  4'b1111    ;
                                       O_green <=  4'b1111  ; 
                                       O_blue  <=  4'b1111    ;
                                   end       
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*7+1))                          
                    begin
                        O_red   <=  4'b0000    ; 
                        O_green <=  4'b0000   ; 
                        O_blue  <=  4'b0000    ; 
                    end 
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*15/2)&&key_value==4'h8)                          
                                                  begin
                                                      O_red   <=  4'b1111    ; 
                                                      O_green <=  4'b0000   ; 
                                                      O_blue  <=  4'b0000    ; 
                                                  end
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*15/2)&&key_value!=4'h8)                          
                                                  begin
                                                    O_red   <=  4'b1111    ; 
                                                    O_green <=  4'b1111   ; 
                                                    O_blue  <=  4'b1111    ; 
                                                  end  
               else if(R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_LENGTH)&&R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*8+10)) 
                                            begin
                                                  O_red   <=  4'b0000 ;
                                                  O_green <=  4'b0000;
                                                  O_blue  <=  4'b0000;
                                            end             
              else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*8)&&key_value==4'h8)                          
                                    begin
                                        O_red   <=  4'b1111    ; 
                                        O_green <=  4'b0000   ; 
                                        O_blue  <=  4'b0000    ; 
                                    end 
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*8)&&key_value!=4'h8)                          
                                                                 begin
                                                                     O_red   <=  4'b1111    ; 
                                                                     O_green <=  4'b1111   ; 
                                                                     O_blue  <=  4'b1111    ; 
                                                                 end   
             else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*8+1))                          
                     begin
                        O_red   <=  4'b0000    ; 
                        O_green <=  4'b0000   ; 
                        O_blue  <=  4'b0000    ; 
                     end   
                    else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*17/2+5)&&key_value==4'h9)                          
                                                               begin
                                                                   O_red   <=  4'b1100    ; 
                                                                   O_green <=  4'b1111   ; 
                                                                   O_blue  <=  4'b0000    ; 
                                                               end 
                      else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*17/2+5)&&key_value!=4'h9)                          
                                                             begin
                                                                  O_red   <=  4'b1111    ; 
                                                                  O_green <=  4'b1111   ; 
                                                                  O_blue  <=  4'b1111    ; 
                                                             end
                      else if(R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_LENGTH)&&R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*9+15)) 
                                                   begin
                                                         O_red   <=  4'b0000 ;
                                                         O_green <=  4'b0000;
                                                         O_blue  <=  4'b0000;
                                                   end    
               else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*9)&&key_value==4'h9)                          
                                                   begin
                                                       O_red   <=  4'b1100    ; 
                                                       O_green <=  4'b1111   ; 
                                                       O_blue  <=  4'b0000    ; 
                                                   end  
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*9)&&key_value!=4'h9)                          
                                                   begin
                                                       O_red   <=  4'b1111    ; 
                                                       O_green <=  4'b1111   ; 
                                                       O_blue  <=  4'b1111    ; 
                                                   end  
              else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*9+1))                          
                                                                   begin
                                                                      O_red   <=  4'b0000    ; 
                                                                      O_green <=  4'b0000   ; 
                                                                      O_blue  <=  4'b0000    ; 
                                                                   end    
              else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*10)&&key_value==4'ha)                          
                        begin
                               O_red   <=  4'b1111    ; 
                               O_green <=  4'b1111   ; 
                               O_blue  <=  4'b0000    ; 
                        end 
               else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*10)&&key_value!=4'ha)                          
                                          begin
                                                 O_red   <=  4'b1111    ; 
                                                 O_green <=  4'b1111   ; 
                                                 O_blue  <=  4'b1111    ; 
                                          end       
              else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*10+1))                          
                                begin
                                    O_red   <=  4'b0000    ; 
                                    O_green <=  4'b0000   ; 
                                    O_blue  <=  4'b0000    ; 
                                end  
                  else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*21/2)&&key_value==4'hb)                          
                                       begin
                                             O_red   <=  4'b0000    ; 
                                             O_green <=  4'b1111   ; 
                                             O_blue  <=  4'b0000    ; 
                                       end  
                   else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*21/2)&&key_value!=4'hb)                          
                                                                         begin
                                                                               O_red   <=  4'b1111    ; 
                                                                               O_green <=  4'b1111   ; 
                                                                               O_blue  <=  4'b1111    ; 
                                                                         end 
                  else if(R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_LENGTH)&&R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*11+10)) 
                                                                                      begin
                                                                                            O_red   <=  4'b0000 ;
                                                                                            O_green <=  4'b0000;
                                                                                            O_blue  <=  4'b0000;
                                                                                      end 
                else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*11)&&key_value==4'hb)                          
                                                  begin
                                                         O_red   <=  4'b0000    ; 
                                                         O_green <=  4'b1111   ; 
                                                         O_blue  <=  4'b0000    ; 
                                                  end  
                  else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*11)&&key_value!=4'hb)                          
                                                   begin
                                                        O_red   <=  4'b1111    ; 
                                                        O_green <=  4'b1111   ; 
                                                        O_blue  <=  4'b1111    ; 
                                                    end 
                  else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*11+1))                          
                        begin
                             O_red   <=  4'b0000    ; 
                             O_green <=  4'b0000   ; 
                             O_blue  <=  4'b0000    ; 
                        end 
                  else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*12)&&key_value==4'hc)                          
                            begin
                                O_red   <=  4'b0000    ; 
                                O_green <=  4'b1111   ; 
                                O_blue  <=  4'b1111    ; 
                            end 
                    else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*12)&&key_value!=4'hc)                          
                                                  begin
                                                      O_red   <=  4'b1111    ; 
                                                      O_green <=  4'b1111   ; 
                                                      O_blue  <=  4'b1111    ; 
                                                  end    
                  else if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*12+1))                          
                            begin
                               O_red   <=  4'b0000    ;                               
                               O_green <=  4'b0000   ; 
                               O_blue  <=  4'b0000    ; 
                            end           
            end
        else 
            begin
                O_red   <=  4'b0000    ;
                O_green <=  4'b0000   ;
                O_blue  <=  4'b0000    ; 
            end 
                  
    end          
    
//---------------------------------------------------------------------------
    //--    �ڲ��˿�����
    //---------------------------------------------------------------------------
    reg        [15:0]    time_cnt;                //�������Ʒ���������Ƶ�ʵĶ�ʱ������
    reg        [15:0]    time_cnt_n;                //time_cnt����һ��״̬
    reg        [15:0]    freq;                        //���������ķ�Ƶֵ
    reg                    beep_reg;                //�������Ʒ����������ļĴ���
    reg                    beep_reg_n;                //beep_reg����һ��״̬
    
    //---------------------------------------------------------------------------
    //--    �߼�����ʵ��    
    //---------------------------------------------------------------------------
    
    
    //ʱ���·,������time_cnt�Ĵ�����ֵ
    always @ (posedge I_clk or negedge I_rst_n)
    begin
        if(I_rst_n)                                    //�жϸ�λ
            time_cnt <= 16'b0;                        //��ʼ��time_cntֵ
        else
            time_cnt <= time_cnt_n;                //������time_cnt��ֵ
    end
    
    //��ϵ�·,�ж�Ƶ��,�ö�ʱ���ۼ� 
    always @ (*)
    begin
        if(time_cnt == freq)                        //�жϷ�Ƶֵ
            time_cnt_n = 16'b0;                    //��ʱ���������
        else
            time_cnt_n = time_cnt + 1'b1;        //��ʱ���ۼӲ���
    
    end
    
    //ʱ���·,������beep_reg�Ĵ�����ֵ
    always @ (posedge I_clk or negedge I_rst_n)
    begin
        if(I_rst_n)                                    //�жϸ�λ
            beep_reg <= 1'b0;                        //��ʼ��beep_regֵ
        else
            beep_reg <= beep_reg_n;        
    end        //������beep_reg��ֵ
    
    //��ϵ�·,�ж�Ƶ��,ʹ����������
    always @ (*)
    begin
        if(time_cnt == freq)                        //�жϷ�Ƶֵ
            beep_reg_n = ~beep_reg;                //�ı��������״̬
        else
            beep_reg_n = beep_reg;                //��������״̬���ֲ���
    end
    reg [23:0] counter_4Hz;
    reg [23:0] counter_6MHz;
    reg [13:0] count;
    reg [13:0] origin;
    reg audio_reg;
    reg clk_6MHz;
    reg clk_4Hz;
    reg [4:0] note;
    reg [7:0] len;
    
    
    //assign BEEP = RST_N ?  1'b1 : audio_reg;
    
    always @ (posedge I_clk) begin
        counter_6MHz <= counter_6MHz + 1'b1;
        if (counter_6MHz == 1) begin
            clk_6MHz = ~clk_6MHz;
            counter_6MHz <= 24'b0;
        end
    end
    
    always @ (posedge I_clk) begin
        counter_4Hz <= counter_4Hz + 1'b1;
        if (counter_4Hz == 2999999) begin    
            clk_4Hz = ~clk_4Hz;
            counter_4Hz <= 24'b0;
        end
    end
    
    always @ (posedge clk_6MHz) begin
        if(count == 16383) begin
            count = origin;
            audio_reg = ~audio_reg;
        end else
            count = count + 1;
    end
    
    
    always @ (posedge clk_4Hz) begin
        case (note)
            'd1: origin <= 'd4916;
            'd2: origin <= 'd6168;
            'd3: origin <= 'd7281;
            'd4: origin <= 'd7791;
            'd5: origin <= 'd8730;
            'd6: origin <= 'd9565;
            'd7: origin <= 'd10310;
            'd8: origin <= 'd010647;
            'd9: origin <= 'd011272;
            'd10: origin <= 'd011831;
            'd11: origin <= 'd012087;
            'd12: origin <= 'd012556;
            'd13: origin <= 'd012974;
            'd14: origin <= 'd013346;
            'd15: origin <= 'd13616;
            'd16: origin <= 'd13829;
            'd17: origin <= 'd14108;
            'd18: origin <= 'd11535;
            'd19: origin <= 'd14470;
            'd20: origin <= 'd14678;
            'd21: origin <= 'd14864;
            default: origin <= 'd011111;
        endcase             
    end
    
    always @ (*)
    begin
    case(key_value)
    4'h1:KEY=8'b00000001;
    4'h2:KEY=8'b00000010;
    4'h3:KEY=8'b00000100;
    4'h4:KEY=8'b00001000;
    4'h5:KEY=8'b00010000;
    4'h6:KEY=8'b00100000;
    4'h7:KEY=8'b01000000;
    4'h8:KEY=8'b10000000;
    4'h9:KEY=8'b10000001;
    4'ha:KEY=8'b10000010;
    4'hb:KEY=8'b10000100;
    4'hc:KEY=8'b10001000;
    4'hd:KEY=8'b10010000;
    4'he:KEY=8'b10100000;
    4'hf:KEY=8'b11000000;
    endcase
    end
    
    
    
    //��ϵ�·,����ѡ���Ƶֵ��ʵ�ַ�����������ͬ����
    //����do��Ƶ��Ϊ523.3hz��freq = 50 * 10^6 / (523 * 2) = 47774
    always @ (*)
    begin
        if(KEY!=8'b11000000)
        begin
        case(KEY)
            8'b00000001: freq = 16'd47774;     //����1��Ƶ��ֵ523.3Hz
            8'b00000010: freq = 16'd42568;     //����2��Ƶ��ֵ587.3Hz
            8'b00000100: freq = 16'd37919;     //����3��Ƶ��ֵ659.3Hz
            8'b00001000: freq = 16'd35791;     //����4��Ƶ��ֵ698.5Hz
            8'b00010000: freq = 16'd31888;     //����5��Ƶ��ֵ784Hz
            8'b00100000: freq = 16'd28409;     //����6��Ƶ��ֵ880Hz
            8'b01000000: freq = 16'd25309;     //����7��Ƶ��ֵ987.8Hz
            8'b10000000: freq = 16'd23889;     //����1��Ƶ��ֵ1046.5Hz
            8'b10000001: freq = 16'd21282;  //����2��Ƶ��ֵ1074.7Hz
            8'b10000010: freq = 16'd18961;  //����3��Ƶ��ֵ1318.5Hz
            8'b10000100: freq = 16'd17897;  //����4��Ƶ��ֵ1396.9Hz
            8'b10001000: freq = 16'd15944;  //����5��Ƶ��ֵ1568.0Hz
            8'b10010000: freq = 16'd14205;  //����6��Ƶ��ֵ1760.0Hz
            default      : freq = 16'd0;
        endcase
        end
    end
        always @ (posedge clk_4Hz)
         begin
             if(KEY==8'b11000000)
             begin
                len <= len + 1;
            case (len)
                0: note <= 3;
                4: note <= 3;
                8: note <= 3;
                12: note <= 3;
                16: note <= 5;
                20: note <= 5;
                24: note <= 5;
                28: note <= 6;
                32: note <= 8;
                36: note <= 8;
                40: note <= 8;
                44: note <= 9;
                48: note <= 6;
                52: note <= 8;
                56: note <= 5;
                60: note <= 5;
                64: note <= 12;
                68: note <= 12;
                72: note <= 12;
                76: note <= 15;
                80: note <= 13;
                84: note <= 12;
                88: note <= 10;
                92: note <= 12;
                96: note <= 9;
                100: note <= 9;
                104: note <= 9;
                108: note <= 9;
                112: note <= 9;
                116: note <= 9;
                120: note <= 9;
                124: note <= 9;
                128: note <= 9;
                132: note <= 9;
                136: note <= 9;
                140: note <= 10;
                144: note <= 7;
                148: note <= 7;
                152: note <= 6;
                156: note <= 6;
                160: note <= 5;
                164: note <= 5;
                168: note <= 5;
                172: note <= 6;
                176: note <= 8;
                180: note <= 8;
                184: note <= 9;
                188: note <= 9;
                192: note <= 3;
                196: note <= 3;
                200: note <= 8;
                204: note <= 8;
                208: note <= 6;
                212: note <= 5;
                216: note <= 6;
                220: note <= 8;
                224: note <= 5;
                228: note <= 5;
                232: note <= 5;
                236: note <= 5;
                240: note <= 5;
                244: note <= 5;
                248: note <= 5;
                252: note <= 5;
                256: note <= 10;
                260: note <= 10;
                264: note <= 10;
                268: note <= 12;
                272: note <= 7;
                276: note <= 7;
                280: note <= 9;
                284: note <= 9;
                288: note <= 6;
                292: note <= 8;
                296: note<=  5;
                300: note<=  5;
                304: note<=  5;
                308: note<=  5;
                312: note<=  5;
                316: note<=  5;
            endcase
            end         
      end
    
    assign BEEP =(KEY==18'b11000000)? audio_reg:beep_reg;        //���,���Ĵ�����ֵ��ֵ���˿�BEEP
    endmodule
