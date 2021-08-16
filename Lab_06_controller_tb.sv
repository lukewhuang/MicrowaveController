module controller_tb();

	// declare variables
	parameter CLK = 10;
	reg clk = 0;
	reg power, door_status, start_button, cancel_button;
	reg [6:0] timer ;
	wire [6:0] state_display1; // I or P or d
	wire [6:0] state_display2; // d or r or O
	wire [6:0] state_display3; // L or O or n
	wire [6:0] state_display4; // E or C or E
	wire [6:0] time_display;
	
	initial begin
	forever begin
	clk <= ~clk;
	#5;
	end
	end
	
	controller ctl (. clk(clk),
	.power(power),
	.timer(timer),
	.door_status(door_status),
	.start_button(start_button),
	.cancel_button(cancel_button),
	.state_display1(state_display1),
	.state_display2(state_display2),
	.state_display3(state_display3),
	.state_display4(state_display4),
	.time_display(time_display)
	);
	
	initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, controller_tb);
	// Possible scenario 1
	// default settings
	power <= 0; // power is HALF
	timer <= 7'b111100 ; // timer is 60s
	door_status <= 0; // Door is open
	start_button <= 0; // start button not pressed
	cancel_button <= 0; // cancel button not pressed
	#CLK //1 clock cycle to place food
	door_status <=1; // Door is closed
	power <= 1; // Power is set to FULL
	timer <= 7'b1100100 ; // timer is set to 100s
	start_button <= 1; // start button pressed
	#5 start_button <= 0; // start button reset at negedge
	#(100*CLK +5) door_status <= 0; // Door opened after 101 s - 1s extra to display dOnE
	#CLK timer <= 7'b111100 ; // timer is reset to 60s
	door_status = 1; // 1 clock cycle to remove food and door is closed
	// write test bench for possible scenarios 2, 3 and 4
	#20

	//SCENARIO TWO
	// default 
	power <= 0; // power is HALF
	timer <= 7'b111100 ; // timer is 60s
	door_status <= 0; // Door is open
	start_button <= 0; // start button not pressed
	cancel_button <= 0; // cancel button not pressed
	// put food in
	#CLK
	door_status <= 1; // door closed
	power <= 0;  // power half
	timer <= 7'b1100100; //set timer to 100 sec
	#CLK
	start_button <= 1; // start
	#5 start_button <= 0; // start button reset at negedge
	#(40*CLK + 5) door_status <= 0; // door opened afer 40 sec? 
	#CLK // remove food
	#CLK // put food back
	door_status = 1; //door closed again
	#CLK
	start_button <= 1; // start
	#5 start_button <= 0; // start button reset at negedge
	#(60*CLK + 5) door_status = 0; // door opened once done
	door_status = 1;
	#20

	//SCENARIO THREE
	// default 
	power <= 0; // power is HALF
	timer <= 7'b0111100 ; // timer is 60s
	door_status <= 0; // Door is open
	start_button <= 0; // start button not pressed
	cancel_button <= 0; // cancel button not pressed
	// put food in
	#CLK
	door_status <= 1; // close door
	power <= 1; //power FULL
	timer <= 7'b1100100; // timer 100 seconds set
	#CLK
	start_button <= 1; // press start button
	#5 start_button <= 0; // start button reset at negedge
	#(30*CLK + 5) door_status <= 0; // wait 30 second and open door
	#CLK // remove food, put it back
	door_status <= 1; // close door again
	#CLK
	//cancel_button <= 1;
	//#5 cancel_button <= 0;
	//#CLK
	timer <= 7'b0110010; // set to 50 seconds 
	#CLK
	start_button <= 1; // press start button
	#5 start_button <= 0; // start button reset at negedge
	#(50*CLK + 5) door_status <= 0; // open door once done
	#CLK // remove food
	door_status <= 1; //close door
	#20

	//SCENARIO FOUR
	// default 
	power <= 0; // power is HALF
	timer <= 7'b0111100 ; // timer is 60s
	door_status <= 0; // Door is open
	start_button <= 0; // start button not pressed
	#5 start_button <= 0; // start button reset at negedge
	cancel_button <= 0; // cancel button not pressed
	// put food in
	#CLK
	door_status <= 1; // door closed
	power <= 1; // power FULL
	timer <= 7'b1100100; // set timer to 100 sec
	#CLK
	start_button <= 1; //press start
	#5 start_button <= 0; // start button reset at negedge
	#(30*CLK + 5) cancel_button <= 1; // press cancel after 30 sec
	#5 cancel_button <= 0; // cancel button reset at negedge
	door_status <= 0; // open door

	$finish;
	end
endmodule