module Controller2 (
 input clk ,
 input Find_Setting ,
 input rst_n ,
 input [7:0] ADC,
 output reg [6:0] DC_Comp,
 output reg LED_IR , LED_RED,
 output reg [3:0] PGA_Gain) ;
 reg [6:0] DC_RED, DC_IR; 
 reg [3:0] PGA_RED ,PGA_IR;

//nihal code declaration begins 
reg [3:0] StateOfMachine;
reg [7:0] errorDc;

//Nihal local param
 localparam [2:0]
 find_DC_comp_IR = 3'b001,
 find_DC_comp_RED = 3'b010,
 find_PGA_comp_IR = 3'b011,
 find_PGA_comp_RED = 3'b100,
 multiplex_RED_and_IR = 3'b100;

always@( posedge clk or negedge rst_n ) begin

 if (!rst_n) 
 begin
	 // Nihal reset signals starts
	 StateOfMachine <= find_DC_comp_IR;
	 DC_Comp <= 64;
	 DC_IR <= 0;
	 errorDc <= 0;
     halfError <= 0;     
 end
 else 
 begin
	case(StateOfMachine)
	default : begin
		//restart from begning
		StateOfMachine <= find_DC_comp_IR;
		DC_Comp <= 64;
		DC_IR <= 0;
		errorDc <= 0;
        halfError <= 0;  	
	end
	find_DC_comp_IR : 
	begin
		if(ADC > 8'b01111111)
        begin
            errorDc <= ADC - 8'b01111111 ;
            halfError <= errorDc/2;
        end
        else
        begin
    	    errorDc <= 8'b01111111 - ADC;
            halfError <= errorDc/2;
        end
		if((ADC == 8'b01111111)||errorDc < 8'b00000010)
		begin
			StateOfMachine <= find_PGA_comp_IR;
			DC_IR <= DC_Comp;
			DC_Comp <= 64;
		end
		else
		begin
			DC_IR <= 0;
			StateOfMachine <= find_DC_comp_IR;
			if(ADC > 8'b01111111)
				DC_Comp <=  DC_Comp + halfError;
			else
                if(halfError > DC_Comp)
                	DC_Comp <=  halfError - DC_Comp;
                else
                    DC_Comp <=  DC_Comp - halfError;

		end
	end
	endcase
end
	
end
endmodule
