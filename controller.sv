// this module takes the inputs of the microwave controller
// power = 0 for HALF and 1 for FULL
// timer is the heat time
// door_status = 0 for OPEN and 1 for closed
// start_button = 0 initially and 1 when pressed
// cancel_button = 0 initially and 1 when pressed
module controller (input clk,
  input power,
  input [6:0] timer,
  input door_status,
  input start_button,
  input cancel_button,
  output reg [6:0] state_display1,
  output reg [6:0] state_display2,
  output reg [6:0] state_display3,
  output reg [6:0] state_display4,
  output reg [6:0] time_display);
  // fill out code
  // TODO :
  // 1. Implement a countdown counter for the timer
  // 2. Monitor door_status and cancel_button (analogous to reset in Lab4)
  // 3. Monitor start_button (analogous to enable in Lab4)
  // 4. state_display consists of 4-alphabets based on the state of the controller. Use 7-segment display representation to display the state.
 
  
  integer state = 0;
  reg power_level;
  reg[1:0] interrupts = 0;
  comb display(
    .state(state),
    .state_display({state_display1, state_display2, state_display3, state_display4})
  );
  
  // the instructions are so unbelievably unclear that i'm just
  // implementing the "allow timer to be set while in PrOC after
  // the door is closed but before the start button is pressed"
  // behavior this way in case it has to be taken out later
  reg door_is_closed_but_still_waiting_for_start_to_be_pressed = 0;
  
  // we only need to asynchronously handle opening the door when the food is done.
  // in any other situation, opening the door has no discernable behavior that can't
  // be handled synchronously
  always @(negedge door_status) begin
      if (state == 2) begin
        /* dOnE state: change display to IdLE */
        state = 0;
      end
  end
  
  // basic 1-level-deep interrupt queue in case these buttons are pressed & released
  // quicker than the clk period 
  always @(posedge cancel_button, posedge start_button) begin
    interrupts[1] |= cancel_button;
    interrupts[0] |= start_button;
  end

  always @(posedge clk) begin
    if (interrupts[1]) begin // cancel button
      interrupts[1] = 0;
      state <= 0;
      time_display = 0;
    end else begin
      if (!state) begin // IdLE
        // check to see if power & timer have been properly set
        // if not, set to default values
        if (power !== 1) begin
          power_level = 0;
        end else begin
          power_level = power;
        end
        if ((timer^timer) !== 7'b0 || timer > 120) begin
          time_display = 60;
        end else begin
          time_display = timer;
        end
        if (interrupts == 2'b01 && door_status) begin // start button
          interrupts[0] = 0;
          state <= 1;
        end
      end else if (state == 1) begin // PrOC
        // time's up!
        // since the timer will take an extra clk cycle for the display change
        // to occur, we want to "stop" it at 1 rather than 0. Then we can just
        // set it to zero at the same time 
        if (time_display == 1) begin
          time_display = 0;
          state <= 2;
        end else begin
          if (!door_status) begin
            wait(door_status);
            door_is_closed_but_still_waiting_for_start_to_be_pressed = 1;
            @(posedge start_button);
            door_is_closed_but_still_waiting_for_start_to_be_pressed = 0;
            interrupts[0] = 0;
          end
          time_display = time_display - 1;
        end
      end
    end
  end
  
  // allow changing the timer while the door is open
  // (no need to set a default value -- if the user enters gibberish
  // just resume where we left off)
  always @(timer) begin
    if (!door_status || door_is_closed_but_still_waiting_for_start_to_be_pressed) begin
      if ((timer^timer) === 7'b0 && timer <= 120) begin
        time_display = timer;
      end
    end
  end
endmodule

module comb(input[31:0] state, output reg[3:0][6:0] state_display);
  // state_display: disp1, disp2, disp3, disp4
  // display format is abcdefg

  // we need to initialize the display right away, and then update
  // whenever a state change occurs
  always_comb begin
    case (state)
      0:  /* IdLE -- BC, BCDEG, DEF, ADEFG */
          state_display = {7'b0110000, 7'b0111101, 7'b0001110, 7'b1001111};
      1:  /* PrOC -- ABEFG, AEF, ABCDEF, ADEF */
          state_display = {7'b1100111, 7'b1000110, 7'b1111110, 7'b1001110};
      2:  /* dOnE -- BCDEG, ABCDEF, CEG, ADEFG */
          state_display = {7'b0111101, 7'b1111110, 7'b0010101, 7'b1001111};
    endcase
  end
endmodule