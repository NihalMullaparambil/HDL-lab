module Controller2 (
 input clk ,
 input Find_Setting ,
 input rst_n ,
 input [7:0] ADC,
 output reg [6:0] DC_Comp,
 output reg LED_IR , LED_RED ,
 output reg [3:0] PGA_Gain
//,output reg [3:0] LED_Drive
) ;

 reg [6:0] DC_RED, DC_IR; 
 reg [3:0] PGA_RED ,PGA_IR;

//nihal code declaration begins 
reg [3:0] StateOfMachine;
reg [3:0] past_PGA_Gain;
reg [7:0] errorDc, lowestErrorDc, minVal, maxVal, lowerLimitVal, upperLimitVal,midleVal;
reg [6:0] PastDC_Comp;
reg measureOrControl, repeatDclowest, optimisePGA, optimiseDC, Flag; // flag is not needed
reg [9:0] signalCounter;

//Nihal local param
 localparam [2:0]
 find_DC_comp_IR_fast = 3'b001,
 find_DC_comp_IR_slow = 3'b101,
 find_DC_comp_RED_fast = 3'b010,
 find_DC_comp_Red_slow = 3'b110,
 find_PGA_comp_IR = 3'b011,
 find_PGA_comp_RED = 3'b100,
 multiplex_RED_and_IR = 3'b100;
 

always@( posedge clk or negedge rst_n ) begin

 if (!rst_n) 
 begin
	 // Nihal reset signals starts
	 StateOfMachine <= find_DC_comp_IR_fast;
	 DC_Comp <= 64;
	 DC_IR <= 0;
	 errorDc <= 127;
	 measureOrControl = 0;
	 PGA_Gain <= 0;
	 LED_IR <= 1;
     LED_RED <= 0; 
	 lowestErrorDc <= 126;
	 repeatDclowest <= 0;
	 PastDC_Comp <= 56;
	 signalCounter <= 0;
	 minVal <= 250;
	 maxVal <= 5;
	 lowerLimitVal <= 0;
	 upperLimitVal <= 255;
	 optimisePGA <= 0;
	 midleVal <= 0;
	 optimiseDC <= 0;
	 Flag <=0;
     lowDcComp <= 0;
     higherDcComp <= 127;
 end
 else 
 begin
	case(StateOfMachine)
	default : begin
		//restart from begning:
		//StateOfMachine <= find_DC_comp_IR;
		DC_Comp <= DC_IR;
		errorDc <= 3;
		measureOrControl <= 0;
		PGA_Gain <= PGA_IR;
	 	LED_IR <= 1;
        LED_RED <= 0;
		PastDC_Comp <= 56;
		signalCounter <= 0;
		midleVal <= 0;
		
	end
	find_DC_comp_IR_fast: 
	begin
		if(measureOrControl)
		begin	//measure		
			if(errorDc < lowestErrorDc || errorDc == lowestErrorDc)
				if(repeatDclowest && errorDc == lowestErrorDc)
				begin
                    StateOfMachine <= find_PGA_comp_IR;
					DC_IR <= PastDC_Comp;
					DC_Comp <= PastDC_Comp;
					repeatDclowest <= 0;
					signalCounter <= 0;
					PGA_Gain <= 7;
					optimisePGA <= 1;
				end
				else
				begin
					lowestErrorDc <= errorDc;
					repeatDclowest <= 1;
				end
			if(ADC > 8'b01111111)
			begin
				errorDc <= ADC - 8'b01111111 ;
			end
			else
			begin
				errorDc <= 8'b01111111 - ADC;
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
			PastDC_Comp <= DC_Comp;			
			measureOrControl <= !measureOrControl;
		end
	end
    
	find_PGA_comp_IR: 	
	begin
		if(signalCounter != 1000 && optimisePGA )
		begin
		if(measureOrControl)
		begin
			if(minVal <= lowerLimitVal || maxVal >= upperLimitVal)
			begin
				PGA_Gain <= past_PGA_Gain - 1;
				PGA_IR <= past_PGA_Gain - 1;
				
				if(minVal <= lowerLimitVal)
					minVal <= minVal + 1;
				if(maxVal >= upperLimitVal)
					maxVal <= maxVal - 1;								
			end
			measureOrControl <= !measureOrControl;
			signalCounter <= signalCounter+1;					
		end
		else
		begin
			if(minVal > ADC)
				minVal <= ADC ;
			if(maxVal < ADC)
				maxVal <= ADC;
			
			//if((PGA_Gain != 7))
				 //PGA_Gain <= PGA_Gain + 1;
			past_PGA_Gain <= PGA_Gain;
			measureOrControl <= !measureOrControl;
		end
		end
		else
		begin
			
			optimisePGA <= 0;
			signalCounter <= 0;
			midleVal <= ((minVal+maxVal)>>1);
			if(optimiseDC != 1)
			begin
				optimiseDC <= 1;
				StateOfMachine <= find_DC_comp_IR_slow;
				measureOrControl <= 1;
				PGA_IR <= PGA_Gain;
			end
			else
			begin
				StateOfMachine <= find_DC_comp_RED_fast;
				measureOrControl <= 0;
				PGA_Gain <= 0;
				DC_Comp <= 50; // for model sim we are using 50
	 			errorDc <= 127;
	 			measureOrControl <= 0;
	 			LED_IR <= 0;
         			LED_RED <= 1; 
	 			repeatDclowest <= 0;
	 			PastDC_Comp <= 56;
	 			signalCounter <= 0;
	 			minVal <= 250;
	 			maxVal <= 5;
	 			optimisePGA <= 0;
	 			midleVal <= 0;
	 			optimiseDC <= 0;
				Flag = 1;
						
			end

		end
	endcase
end	
end
endmodule
