module CompleteControllerUpdate (
 input clk ,
 input Find_Setting ,
 input rst_n ,
 input [7:0] ADC,
 output reg [6:0] DC_Comp,
 output reg LED_IR , LED_RED  ,
 output reg [3:0] PGA_Gain) ;
 reg [1:0] stateForRunningLeds;
 reg [2:0] stateForFindingValues;
 reg [6:0] DC_RED, DC_IR, LastDCUp, LastDCDown;
 reg [3:0] PGA_RED ,PGA_IR, LastPGAUp,LastPGADown;
 // boardup and boarddown are the max voltage and the min voltage the wave can reach
 reg [7:0] maxForCurrentPeriod  ,minForCurrentPeriod, boardUp , boardDown, middleForCurrentPeriod; 
 reg [9:0] counterForFindingValues ;// count 1000 for a period
 reg [7:0] counterForRunningLeds ;// count for switching the LED
 reg [6:0] DC_Half;
 reg [3:0] PGA_Half;
 reg setting ;
// nihal made change
 reg CLK_Filter;
 reg [7:0] IR_ADC_Value;
 reg [7:0] RED_ADC_Value; 

 localparam [1:0] // state define
 Find_DC_RED= 2'b00,
 Find_Gain_RED= 2'b01,
 Find_DC_IR=2'b10 ,
 Find_Gain_IR =2'b11;
 localparam 
 RED_On=1'b0,
 IR_On=1'b1;
 always@(posedge clk or negedge rst_n) begin
 if (!rst_n) begin
     LastDCUp <= 126;
     LastDCDown <= 30;
     DC_Half <= 10;
     LastPGADown <= 1;
     LastPGAUp <= 13;
     PGA_Half <= 10;
     stateForFindingValues <= Find_DC_RED;
     DC_Comp <= 100;
     DC_RED <= 0;
     DC_IR <= 0;
     PGA_Gain <= 0 ;
     PGA_RED <= 0 ;
     PGA_IR <= 0;
     maxForCurrentPeriod <= 0;
     minForCurrentPeriod <= 8'b11111111 ;
     boardUp <=  240;
     boardDown <= 20;
     LED_RED <= 1;
     LED_IR <= 0;
     counterForFindingValues <= 0;
     counterForRunningLeds <= 0;
     CLK_Filter <= 1'b0 ;
     stateForRunningLeds <= RED_On;
     setting <= Find_Setting ; 
 end
 else begin CLK_Filter <= ! CLK_Filter ;
        if(setting == 1) begin
            case ( counterForFindingValues )
                default: begin 
                           maxForCurrentPeriod <= (maxForCurrentPeriod > ADC) ? maxForCurrentPeriod : ADC;
                           minForCurrentPeriod <= (minForCurrentPeriod < ADC) ? minForCurrentPeriod : ADC;
                           counterForFindingValues <= counterForFindingValues + 1;
                         end
                1000:    begin 
                           middleForCurrentPeriod <= (maxForCurrentPeriod + minForCurrentPeriod) /2;
			   counterForFindingValues <= counterForFindingValues + 1;
                         end        
                1001:    begin 
                          counterForFindingValues <= 0; 
                          maxForCurrentPeriod <= 8'b00000000;
                          minForCurrentPeriod <= 8'b11111111;                        
                          case(stateForFindingValues) 
                              Find_DC_RED : begin
					    stateForFindingValues <= (DC_Half == 2) ? Find_Gain_RED :Find_DC_RED;
                                            if(DC_Half == 2) begin
					       DC_Comp <=(middleForCurrentPeriod > 8'b01111111) ? (DC_Comp + 1):(DC_Comp - 1) ;
                                               DC_RED <= (middleForCurrentPeriod > 8'b01111111) ? (DC_Comp + 1):(DC_Comp - 1);
				   	       PGA_Gain <= 5;
					       PGA_Half <= 10;
                                            end
  					    else begin if (middleForCurrentPeriod == 8'b01111111) begin
							  DC_Comp <= 62;
                                                 	  DC_RED <= DC_Comp;
				   	       		  PGA_Gain <= 5;
						          stateForFindingValues <= Find_Gain_RED;
						        end					     	 
					    	       else begin if(middleForCurrentPeriod > 8'b01111111) begin 
						                     DC_Comp <= DC_Comp + (LastDCUp - DC_Comp) / 2;
                                                                     DC_RED <= DC_Comp + (LastDCUp - DC_Comp) / 2;
			 			                     DC_Half <= (LastDCUp - DC_Comp) / 2;
							             LastDCDown <= DC_Comp;
								  end
								     else begin 
                                                                     LastDCUp <= DC_Comp;                                                         
              					           	     DC_Comp <= DC_Comp - (DC_Comp - LastDCDown) / 2;
                                                           	     DC_RED <= DC_Comp - (DC_Comp - LastDCDown) / 2;                                                          
						                     DC_Half <= (DC_Comp - LastDCDown) / 2;							   			
                                            			     end
					    		end
					    end
					    end
                              Find_Gain_RED : begin
   					      stateForFindingValues <= (PGA_Half == 1) ? Find_DC_IR :Find_Gain_RED;
					      if(PGA_Half == 1) begin
					        PGA_RED <= ((maxForCurrentPeriod >= boardUp) || (minForCurrentPeriod <= boardDown)) ? (PGA_Gain - 1):PGA_Gain;
					        PGA_Gain <= 0;
						DC_Comp <= 62;				     
 			                        DC_Half <= 10;
					        LastDCUp <= 126;
					        LastDCDown <= 30;
					        LastPGAUp <= 13;
					        LastPGADown <= 1;
					        LED_RED <= 0;
                                                LED_IR <= 1;
         				      end
				              else begin if((maxForCurrentPeriod >= boardUp) || (minForCurrentPeriod <= boardDown)) begin
 						           PGA_Gain <= PGA_Gain - (PGA_Gain - LastPGADown) / 2;
						           PGA_RED <= PGA_Gain - (PGA_Gain - LastPGADown) / 2;
					                   LastPGAUp <= PGA_Gain;
						           PGA_Half <= (PGA_Gain - LastPGADown) / 2;
					                  end
					                  else begin 
						          PGA_Gain <= PGA_Gain + (LastPGAUp - PGA_Gain) / 2;
						          PGA_RED <= PGA_Gain + (LastPGAUp - PGA_Gain) / 2;
					                  LastPGAUp <= PGA_Gain;
						          PGA_Half <= (LastPGAUp - PGA_Gain) / 2; 
						          end
                                              end
					      end                                     
                                 Find_DC_IR:  begin
					    stateForFindingValues <= (DC_Half == 2) ? Find_Gain_IR :Find_DC_IR;
                                            if(DC_Half == 2) begin
					       DC_Comp <=(middleForCurrentPeriod > 8'b10000000) ? (DC_Comp + 1) : (DC_Comp -1);
                                               DC_IR <= (middleForCurrentPeriod > 8'b10000000) ? (DC_Comp + 1) : (DC_Comp -1);
				   	       PGA_Gain <= 5;
					       PGA_Half <= 10;
                                            end
  					    else begin if (middleForCurrentPeriod == 8'b01111111) begin
							  DC_Comp <= DC_Comp;
                                                 	  DC_IR <= DC_Comp;
				   	       		  PGA_Gain <= 8;
							  stateForFindingValues <= Find_Gain_IR; 
						          PGA_Half <= 10;
							  end					     	 
					    	       else begin if(middleForCurrentPeriod > 8'b01111111) begin 
						                     DC_Comp <= DC_Comp + (LastDCUp - DC_Comp) / 2;
                                                                     DC_IR <= DC_Comp + (LastDCUp - DC_Comp) / 2;
			 			                     DC_Half <= (LastDCUp - DC_Comp) / 2;
							             LastDCDown <= DC_Comp;
								     end
								     else begin 
                                                                     LastDCUp <= DC_Comp;                                                         
              					           	     DC_Comp <= DC_Comp - (DC_Comp - LastDCDown) / 2;
                                                           	     DC_IR <= DC_Comp - (DC_Comp - LastDCDown) / 2;                                                          
						                     DC_Half <= (DC_Comp - LastDCDown) / 2;	
                                            			     end
					    		end
					    end
					  end
                                Find_Gain_IR :  begin
						if(PGA_Half == 1) begin
					        setting <= 0;
					        //PGA_Gain <= PGA_Gain;
					        PGA_IR <= ((maxForCurrentPeriod >= boardUp )||( minForCurrentPeriod <= boardDown ))? (PGA_Gain-1) :PGA_Gain;
						LED_RED <= 1;	
						LED_IR <= 0; 
						DC_Comp <= DC_RED;
		  				PGA_Gain <= PGA_RED;
                  				end
				                else begin  stateForFindingValues <= Find_Gain_IR;
                                                           if((maxForCurrentPeriod >= boardUp) || (minForCurrentPeriod <= boardDown)) begin
 						             PGA_Gain <= PGA_Gain - (PGA_Gain - LastPGADown) / 2;
						             PGA_IR <= PGA_Gain - (PGA_Gain - LastPGADown) / 2;
					                     LastPGAUp <= PGA_Gain;
						             PGA_Half <= (PGA_Gain - LastPGADown) / 2;
					                    end
					                    else begin 
						            PGA_Gain <= PGA_Gain + (LastPGAUp - PGA_Gain) / 2;
						            PGA_IR <= PGA_Gain + (LastPGAUp - PGA_Gain) / 2;
					                    LastPGADown <= PGA_Gain;
						            PGA_Half <= (LastPGAUp - PGA_Gain) / 2; 
						            end
                                               end
					       end  
                          endcase
                end
            endcase
        end
     else begin 
          case(stateForRunningLeds) 
	  RED_On: begin	
	          if(counterForRunningLeds <=9) begin
		  counterForRunningLeds <= counterForRunningLeds + 1;
		  stateForRunningLeds <= RED_On;
		  RED_ADC_Value <= ADC; 
		  IR_ADC_Value <= 0;	 
		  end
		  else begin 
	          counterForRunningLeds <= 0;
		  stateForRunningLeds <= IR_On;	
	          LED_RED <= 0;	
		  LED_IR <= 1;
		  DC_Comp <= DC_IR;
		  PGA_Gain <= PGA_IR;	  
		  end
    		  end		  
           IR_On: begin
	          if(counterForRunningLeds <=9) begin
		  counterForRunningLeds <= counterForRunningLeds + 1;
		  stateForRunningLeds <= IR_On;
		  IR_ADC_Value <= ADC;
		  RED_ADC_Value <= 0;  
		  end
		  else begin 
		   counterForRunningLeds <= 0;
		  stateForRunningLeds <= RED_On;	
	          LED_RED <= 1;	
		  LED_IR <= 0;
		  DC_Comp <= DC_RED;
		  PGA_Gain <= PGA_RED; 			
                  end
	          end	         
          endcase
end
end
end
endmodule
