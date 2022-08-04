module Controller(
input[7:0] ADC,
input clk,
input rst_n,
input Find_Setting,
output reg[6:0] DC_Comp,
output reg[3:0] PGA_Gain,
output reg LED_IR,
output reg LED_RED,
output reg[7:0] RED_ADC_Value,
output reg[7:0]	IR_ADC_Value);

reg measureOrControl,clipLastTime, lastChange, thisChange,DCoptimal;
reg[1:0] final,flag;
reg[2:0] state;
reg[3:0] RED_PGA;
reg[3:0] IR_PGA;
reg[6:0] RED_DC, lowDcComp, higherDcComp,oldDC;
reg[6:0] IR_DC;
reg[7:0] errorDc, lowestErrorDc;
reg [9:0] counterForFindingValues ;
reg[7:0] maxForCurrentPeriod,middleForCurrentPeriod, minForCurrentPeriod, middleValUpperLimit, middleValLowerLimit, maxboard, minboard,diff,diffOld;
reg[3:0] ctr;
always@(posedge clk)
begin
//$monitor("Find_Setting = %d, state = %d, DC_Comp = %d ,RED_PGA = %d ,IR_PGA = %d ,RED_DC = %d,IR_DC = %d, counterForFindingValues = %d,final = %d,clipLastTime = %d",Find_Setting, state,DC_Comp,RED_PGA,IR_PGA,RED_DC,IR_DC, counterForFindingValues,final,clipLastTime);
if(!rst_n)
begin
	DC_Comp <=64;
	lowDcComp <= 0;
        higherDcComp <= 127;
	state <=0;
	PGA_Gain<=0;
	measureOrControl<=0;
	counterForFindingValues <=0;
	maxForCurrentPeriod <= 0;
        minForCurrentPeriod <= 8'b11111111 ;
	middleForCurrentPeriod <= 0;
	middleValUpperLimit <= 'h90;
	middleValLowerLimit <= 'h60;
	maxboard <= 240;
	minboard <= 15;
	final<=0;
	clipLastTime <=0;
	LED_IR<=0;
	LED_RED<=1;
	flag<= 2;
	DCoptimal<= 0 ;
	lastChange<= 0;
	thisChange<= 0;
	ctr<=0;
	RED_ADC_Value<=0;
	IR_ADC_Value<=0;

end
else
begin

	case(state)
		0:
		begin
			if(Find_Setting)
			begin
			state<= 1;
			end
			DC_Comp <=64;
			lowDcComp <= 0;
       			 higherDcComp <= 127;
			RED_ADC_Value<=0;
			IR_ADC_Value<=0;
			PGA_Gain<=0;
			measureOrControl<=0;
			counterForFindingValues <=0;
			maxForCurrentPeriod <= 0;
       		 	minForCurrentPeriod <= 8'b11111111 ;
			middleForCurrentPeriod <= 0;
			middleValUpperLimit <= 'h90;
			middleValLowerLimit <= 'h60;
			maxboard <= 240;
			minboard <= 15;
			final<=0;
			clipLastTime <=0;
			LED_IR<=0;
			LED_RED<=1;
			flag<= 2;
			DCoptimal<= 0 ;
			lastChange<= 0;
			thisChange<= 0;
		end
		1: //fast DC RED
		if(measureOrControl)
		begin	//measure
			if(ADC>middleValLowerLimit && ADC<middleValUpperLimit) // adjust to get better value
			begin
				state <= 2;
				PGA_Gain <= 7;
							
			end
						
			
			measureOrControl <= !measureOrControl;

		end
		else
		begin
			if(ADC > 8'b01111111)
			
			begin
                		DC_Comp <= DC_Comp + ((higherDcComp - DC_Comp)>>1);
                		lowDcComp <= DC_Comp;
				
			end
			else
			begin				
                		DC_Comp <= DC_Comp - ((DC_Comp-lowDcComp)>>1);
                		higherDcComp <= DC_Comp;
			end		
			measureOrControl <= !measureOrControl;
		end
		2 : // pga + dc_comp optimition
			begin
		if(final==3)begin
		state<=3;/// state change
		RED_PGA<=PGA_Gain;
		RED_DC<=DC_Comp;
		DC_Comp <=64;
	 	lowDcComp <= 0;
         	higherDcComp <= 127;
		PGA_Gain<=0;
		measureOrControl<=0;
		counterForFindingValues <=0;
		maxForCurrentPeriod <= 0;
        	minForCurrentPeriod <= 8'b11111111 ;
		middleForCurrentPeriod <= 0;
		middleValUpperLimit <= 'h90;
		middleValLowerLimit <= 'h27;
		final<=0;
		clipLastTime <=0;
		LED_IR<=1;
		LED_RED<=0;
		flag<= 2;
		DCoptimal<= 0 ;
		lastChange<= 0;
		thisChange<= 0;
				
		end
		else
		begin
		case ( counterForFindingValues )
                default: begin
			   if(ADC > maxboard || ADC < minboard)
			   begin
				counterForFindingValues <=0;
				maxForCurrentPeriod <= 0;
                		minForCurrentPeriod <= 8'b11111111;	
				PGA_Gain<= PGA_Gain - 1;
				clipLastTime <= 1;
				final[0]<=0;			
			   end
			   else
			   begin
				 maxForCurrentPeriod <= (maxForCurrentPeriod > ADC) ? maxForCurrentPeriod : ADC;
                           	minForCurrentPeriod <= (minForCurrentPeriod < ADC) ? minForCurrentPeriod : ADC;
                           	counterForFindingValues <= counterForFindingValues + 1;
				
			   end
                         end
                1000:    begin 
                           middleForCurrentPeriod <= (maxForCurrentPeriod>>1) + (minForCurrentPeriod>>1);
			   counterForFindingValues <= counterForFindingValues + 1;
		
                         end  
		1001: 
			begin
				counterForFindingValues <=0;
				maxForCurrentPeriod <= 0;
                		minForCurrentPeriod <= 8'b11111111;
			//exit if optimal solution
			//old error
			if(lastChange^thisChange && flag == 0)
			begin
				if(diffOld<diff)
					begin
				//	DC_Comp<=oldDC;
					end
				else
				begin
					DC_Comp<=oldDC;
				end
				DCoptimal<=1;
				final[1]<=1;
			end
				
			if(!DCoptimal)
			begin
				if(middleForCurrentPeriod  > middleValUpperLimit  )  
				begin
					DC_Comp <= DC_Comp + 1;
					final[1]<=0;
					lastChange<=thisChange;
					thisChange<=1;
					diff<=middleForCurrentPeriod-'h7f;
					diffOld<=diff;
					oldDC<=DC_Comp;
					if(flag>0)
					flag<=flag-1;
				end
				else if(middleForCurrentPeriod < middleValLowerLimit)
				begin
					DC_Comp <= DC_Comp - 1;
					final[1]<=0;
					lastChange<=thisChange;
					thisChange<=0;
					diff<='h7f-middleForCurrentPeriod;
					diffOld<=diff;
					oldDC<=DC_Comp;
					if(flag>0)
					flag<=flag-1;
				end
				else
					final[1]<=1;
			end
				if(maxForCurrentPeriod > maxboard || minForCurrentPeriod < minboard)
				begin
					PGA_Gain<= PGA_Gain - 1;
					clipLastTime <= 1;
					final[0]<=0;
				end
				else
				begin
					if(clipLastTime)
						//leave
						final[0]<=1;
												
					else
					begin
					PGA_Gain<= PGA_Gain + 1;
					clipLastTime<=0;
					final[0]<=0;
					end
				end

			end 
		endcase
		end//else condition - not final
		end//ending of state 1
		3 :// fast IR DC
		begin
		if(measureOrControl)
		begin	//measure
			if(ADC>8'h7d && ADC<8'h83) // adjust to get better value
			begin
				state <= 4;
				PGA_Gain <= 7;
							
			end
						
			
			measureOrControl <= !measureOrControl;

		end
		else
		begin
			if(ADC > 8'b01111111)
			begin
                		DC_Comp <= DC_Comp + ((higherDcComp - DC_Comp)>>1);
                		lowDcComp <= DC_Comp;
				
			end
			else
			begin				
                		DC_Comp <= DC_Comp - ((DC_Comp-lowDcComp)>>1);
                		higherDcComp <= DC_Comp;
			end		
			measureOrControl <= !measureOrControl;
		end
					
		end // ending of case 2
	    4 : 
		
			begin
		if(final==3)begin
		state<=5;/// state change
		IR_PGA <=PGA_Gain;
		IR_DC <= DC_Comp;	 
		LED_IR<=0;
		LED_RED<=0;
				
		end
		else
		begin
		case ( counterForFindingValues )
                default: begin
			   if(ADC > maxboard || ADC < minboard)
			   begin
				counterForFindingValues <=0;
				maxForCurrentPeriod <= 0;
                		minForCurrentPeriod <= 8'b11111111;	
				PGA_Gain<= PGA_Gain - 1;
				clipLastTime <= 1;
				final[0]<=0;			
			   end
			   else
			   begin
				 maxForCurrentPeriod <= (maxForCurrentPeriod > ADC) ? maxForCurrentPeriod : ADC;
                           	minForCurrentPeriod <= (minForCurrentPeriod < ADC) ? minForCurrentPeriod : ADC;
                           	counterForFindingValues <= counterForFindingValues + 1;
				
			   end
                         end
                1000:    begin 
                           middleForCurrentPeriod <= (maxForCurrentPeriod>>1) + (minForCurrentPeriod>>1);
			   counterForFindingValues <= counterForFindingValues + 1;
		
                         end  
		1001: 
			begin
				counterForFindingValues <=0;
				maxForCurrentPeriod <= 0;
                          	minForCurrentPeriod <= 8'b11111111;
		if(lastChange^thisChange && flag == 0)
			begin
				if(diffOld<diff)
					begin
				//	DC_Comp<=oldDC;
					end
				else
				begin
					DC_Comp<=oldDC;
				end
				DCoptimal<=1;
				final[1]<=1;
			end
				
			if(!DCoptimal)
			begin
				if(middleForCurrentPeriod  > middleValUpperLimit  )  
				begin
					DC_Comp <= DC_Comp + 1;
					final[1]<=0;
					lastChange<=thisChange;
					thisChange<=1;
					diff<=middleForCurrentPeriod-'h7f;
					diffOld<=diff;
					oldDC<=DC_Comp;
					if(flag>0)
					flag<=flag-1;
				end
				else if(middleForCurrentPeriod < middleValLowerLimit)
				begin
					DC_Comp <= DC_Comp - 1;
					final[1]<=0;
					lastChange<=thisChange;
					thisChange<=0;
					diff<='h7f-middleForCurrentPeriod;
					diffOld<=diff;
					oldDC<=DC_Comp;
					if(flag>0)
					flag<=flag-1;
				end
				else
					final[1]<=1;
			end
				if(maxForCurrentPeriod > maxboard || minForCurrentPeriod < minboard)
				begin
					PGA_Gain<= PGA_Gain - 1;
					clipLastTime <= 1;
					final[0]<=0;
				end
				else
				begin
					if(clipLastTime)
						//leave
						final[0]<=1;
												
					else
					begin
					PGA_Gain<= PGA_Gain + 1;
					clipLastTime<=0;
					final[0]<=0;
					end
				end

			end 
		endcase
		end//else condition - not final	
		end // ending of case 3
		5 : //RED is ON
		begin
			if(Find_Setting)
			begin
			state<=1;
				DC_Comp <=64;
			lowDcComp <= 0;
       		 higherDcComp <= 127;
			state <=0;
			PGA_Gain<=0;
			measureOrControl<=0;
			counterForFindingValues <=0;
			maxForCurrentPeriod <= 0;
       		 minForCurrentPeriod <= 8'b11111111 ;
			middleForCurrentPeriod <= 0;
			middleValUpperLimit <= 'h90;
			middleValLowerLimit <= 'h60;
			maxboard <= 240;
			minboard <= 15;
			final<=0;
			clipLastTime <=0;
			LED_IR<=0;
			LED_RED<=1;
			flag<= 2;
			DCoptimal<= 0 ;
			lastChange<= 0;
			thisChange<= 0;
			end
			else
			begin
			LED_RED<=1;
			LED_IR<=0;
			DC_Comp<=RED_DC;
			PGA_Gain<=RED_PGA;
			RED_ADC_Value<=ADC;
			IR_ADC_Value<=0;
		
			if(ctr==9)
			begin
			state<=6;
			ctr<=0;
			end
			else
				ctr<=ctr+1;
		end
		end
		6 : //RED is ON
		begin
			if(Find_Setting)
			begin
			state<=1;
				DC_Comp <=64;
			lowDcComp <= 0;
       		 higherDcComp <= 127;
			state <=0;
			PGA_Gain<=0;
			measureOrControl<=0;
			counterForFindingValues <=0;
			maxForCurrentPeriod <= 0;
       		 minForCurrentPeriod <= 8'b11111111 ;
			middleForCurrentPeriod <= 0;
			middleValUpperLimit <= 'h90;
			middleValLowerLimit <= 'h60;
			maxboard <= 240;
			minboard <= 15;
			final<=0;
			clipLastTime <=0;
			LED_IR<=0;
			LED_RED<=1;
			flag<= 2;
			DCoptimal<= 0 ;
			lastChange<= 0;
			thisChange<= 0;
			end
			else
			begin
			LED_RED<=0;
			LED_IR<=1;
			DC_Comp<=IR_DC;
			PGA_Gain<=IR_PGA;
			RED_ADC_Value<=0;
			IR_ADC_Value<=ADC;
			if(ctr==9)
			begin
			state<=5;
			ctr<=0;
			end
			else
			ctr<=ctr+1;
		end
		end
	default:
	begin
		DC_Comp <=64;
			lowDcComp <= 0;
       		 higherDcComp <= 127;
			state <=0;
			PGA_Gain<=0;
			measureOrControl<=0;
			counterForFindingValues <=0;
			maxForCurrentPeriod <= 0;
       		 minForCurrentPeriod <= 8'b11111111 ;
			middleForCurrentPeriod <= 0;
			middleValUpperLimit <= 'h90;
			middleValLowerLimit <= 'h60;
			maxboard <= 240;
			minboard <= 15;
			final<=0;
			clipLastTime <=0;
			LED_IR<=0;
			LED_RED<=1;
			flag<= 2;
			DCoptimal<= 0 ;
			lastChange<= 0;
			thisChange<= 0;
	state<=0;
	end
	endcase
end
end
endmodule
