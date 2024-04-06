/////////////////////////////////////////////////////////////////////////////////////////
//
//   PROJECT DESCRIPTION:  A SPI master for a MCP3202 12-bit ADC. The sampling frequency
//                         is 50 KHz, making the Nyquist frequency 25 KHz. When the
//                         output 12-bit word is valid, the data valid flag goes high.
//                         The module can be configured to support single-ended and
//                         differential sampling modes, as well as specificy aquisition
//                         channel on the ADC (see pinout in datasheet for details).
//                         The ADC runs in MSB-first mode ONLY to maximize speed.
//
//              FILENAME:   SPI_MCP3202.v
//               VERSION:   2.0  9/17/2020
//                AUTHOR:   Dominic Meads
//
// Modified by Dean Netherton to work at 135Mhz. (April 2024)
//
/////////////////////////////////////////////////////////////////////////////////////////

module SPI_MCP3202_2 #(  // set up bits for MOSI (DIN on datasheet)
    parameter SGL = 1,  // sets ADC to single ended mode
    parameter ODD = 0   // sets sample input to channel 0
) (
    input         clk,        // 135 MHz, each clock cycle is ~7.4074074074074ns
    input         EN,         // Enable the SPI core (ACTIVE HIGH)
    input         MISO,       // data out of ADC (Dout pin)
    output        MOSI,       // Data into ADC (Din pin)
    output        SCK,        // SPI clock
    output [11:0] o_DATA,     // 12 bit word (for other modules)
    output        CS,         // Chip Select
    output        DATA_VALID  // is high when there is a full 12 bit word.
);

  // additional MOSI data
  localparam START = 1;  // start bit
  localparam MSBF = 1;  // sets ADC to transmit MSB first

  // states
  localparam DISABLE = 1;  // CS is high
  localparam TRANSMITTING = 2;  // set the sample channel, sampling mode, etc...
  localparam RECEIVING = 3;  // convert the bitstream into parellel word

  integer        i = 0;  // for the for loop in the TRANSMITTING state (used to condense code)

  reg     [ 7:0] SCK_counter = 0;  // for the output SPI clock
  reg            r_MOSI = 0;
  reg     [11:0] r_DATA;
  reg     [ 1:0] r_STATE = DISABLE;  // state machine (init to disable state)
  reg            r_CS = 1;  // disable CS to start
  reg            r_SCK_enable = 0;  // enable for SCK
  reg            r_DV = 0;  // DATA_VALID register
  reg     [11:0] sample_counter = 1;  // this counter flips over after one sample period
  // it starts at one so INITIALIZE waits one sampling period to begin DISABLE

  always @(posedge clk) begin
    if (EN) begin
      if (sample_counter <= 2698)  /* this number is the amount of system clock cycles to finish one sampling period:
                                      2700 counts (0-2699) @ 7.407...ns system clock period = 20us or 50 KHz */

        sample_counter <= 12'(sample_counter + 1);  // sample counter only counts if enable is high
      else sample_counter <= 0;
    end else begin
      sample_counter <= 0;
    end
  end

  // SPI_CLK
  always @(posedge clk) begin
    // looking for 900khz clock with is 1111.11...ns
    // 1111.11... / 7.407... is 150 cycles
    if (r_SCK_enable && SCK_counter <= 148)  /* 150 counts (0-149) @ 8ns system clock period
                                                is 900 KHz, < SCK max frequency of 0.9 MHz (datasheet) */

      SCK_counter <= 8'(SCK_counter + 1);
    else SCK_counter <= 0;
  end

  assign SCK = (SCK_counter <= ((150 / 2) - 1) && r_SCK_enable) ? 1 : 0;  // 50% duty cycle PWM/SPI clock

  // State machine
  always @(posedge clk) begin
    case (r_STATE)

      DISABLE: begin
        r_CS <= 1;
        r_SCK_enable <= 0;
        r_MOSI <= 0;
        r_DV <= 0;

        // ensures that DISABLE waits 68 counts or 512ns (tcsh must >= 500ns in datasheet)
        if (sample_counter == 68 && EN) begin
          r_STATE <= TRANSMITTING;
          r_CS    <= 0;  // CS pulled low, activates sampling
          r_MOSI  <= START;
        end else begin
          r_STATE <= DISABLE;
        end
      end

      TRANSMITTING: begin
        r_CS         <= 0;  // CS pulled low, activates sampling
        r_SCK_enable <= 0;
        r_MOSI       <= START;
        r_DV         <= 0;

        // pull SCK high after 452ns after DISABLE state (452ns, check tsucs in datasheet, tsucs >= 100ns)
        if (sample_counter >= 68 + 61 && EN) r_SCK_enable <= 1;

        // provides set up data to ADC depending on the timing
        // between 1520ns and 2640ns
        // 1520/7.407... = 205
        // 2640/7.407... = 356
        if (sample_counter >= 205 && sample_counter < 356 && EN) r_MOSI <= SGL;

        // between 2640ns and 3760ns
        // 2640/7.407... = 356
        // 3760/7.407... = 508
        else if (sample_counter >= 356 && sample_counter < 508 && EN) r_MOSI <= ODD;

        // between 3760ns and 4880ns
        // 3760/7.407... = 508
        // 4880/7.407... = 659
        else if (sample_counter >= 508 && sample_counter < 659 && EN) r_MOSI <= MSBF;

        // @ 4880ns, the ADC is ready to receiving data
        // 4880/7.407... = 659
        else if (sample_counter == 659 && r_MOSI == MSBF && EN) r_STATE <= RECEIVING;

        else if (!EN) r_STATE <= DISABLE;  // if enable goes low, go back to disabled state and reset count

        else r_STATE <= TRANSMITTING;
      end


      RECEIVING: begin
        r_CS         <= 0;
        r_SCK_enable <= 1;
        r_MOSI       <= 0;  // MOSI is "don't care" in this state

        for (i = 0; i < 12; i = i + 1) begin
          // 6280/7.407... = 848
          // 1120/7.407... = 151
          if (sample_counter == 848 + 151 * i && EN)  /* the 848  makes sure waits 1.5 SCK cycle after MSBF bit
                                                         because MISO transmits null bit (MUST SAMPLE AT MIDPOINT OF BIT) */
            r_DATA[11-i] <= MISO;
        end

        // Data is now valid
        // 18760/7.407... = 2533
        if (sample_counter == 2533 && EN) r_DV <= 1;

        // After counter flips over, the sample is over, and it is time for another one
        if (sample_counter == 0 && EN) r_STATE <= DISABLE;

        // if enable goes low, go back to disabled state and reset count
        else if (!EN) r_STATE <= DISABLE;

        else r_STATE <= RECEIVING;
      end

      default: begin
        r_STATE <= DISABLE;
      end

    endcase
  end

  assign CS         = r_CS;  // output signals (all low if enable is low)
  assign MOSI       = r_MOSI;
  assign o_DATA     = r_DATA;
  assign DATA_VALID = r_DV;

endmodule

